{-# LANGUAGE TypeSynonymInstances, MultiParamTypeClasses, DeriveDataTypeable,
    NoMonomorphismRestriction, FlexibleContexts #-}

import XMonad hiding ( (|||) ) -- get III from X.L.LayoutCombinators
import XMonad.Actions.DynamicWorkspaces
import XMonad.Actions.Navigation2D
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Accordion
import XMonad.Layout.BinarySpacePartition
import XMonad.Layout.Gaps
import XMonad.Layout.Hidden
import XMonad.Layout.LayoutCombinators
import XMonad.Layout.MultiToggle
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.PerScreen
import XMonad.Layout.Reflect
import XMonad.Layout.Renamed
import XMonad.Layout.ResizableTile
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.WindowNavigation
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Util.Cursor
import XMonad.Util.EZConfig
import XMonad.Util.NamedActions
import XMonad.Util.NamedScratchpad
import XMonad.Util.NamedWindows
import XMonad.Util.Run
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce
import Graphics.X11.ExtraTypes.XF86

import Data.Char
import Data.Monoid
import Data.List
import GHC.IO.Handle
import System.Exit

import BarMonitor

import qualified DBus as D
import qualified DBus.Client as D
import qualified Codec.Binary.UTF8.String as UTF8
import qualified Data.Map        as M
import qualified XMonad.StackSet as W

splitString :: String -> [String]
splitString s = case dropWhile Data.Char.isSpace s of
    "" -> []
    s' -> w : splitString s''
        where (w, s'') = break Data.Char.isSpace s'

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth   = 1

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--

myModMask = mod4Mask

showKeybindings :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
showKeybindings x = addName "Show Keybindings" $ io $ do
    h <- spawnPipe "zenity --text-info"
    hPutStr h (unlines $ showKm x)
    hClose h
    return ()

wsKeys = map show $ [1..9] ++ [0]

screenKeys :: [String]
screenKeys = [ "w", "e", "r" ]

myKeys conf = let
    subKeys str ks = subtitle str : mkNamedKeymap conf ks
    zipM  m nm ks as f = zipWith (\k d -> (m ++ k, addName nm $ f d)) ks as
    in
    subKeys "System"
    [ ("M-q" , addName "Restart XMonad" $ spawn "pkill polybar; xmonad --restart")
    , ("M-S-q" , addName "Quit XMonad" $ io (exitWith ExitSuccess))
    ] ^++^

    subKeys "Actions"
    [ ("M-S-l", addName "Lock screen" $ spawn "i3lock-fancy -gp")
    , ("M-p", addName "Toggle monitors" $ spawn "toggleDisplayMode.sh")
    ] ^++^

    subKeys "Launchers"
    [ ("M-S-<Return>", addName "Terminal" $ spawn myTerminal)
    , ("M-s", addName "Launcher" $ shellPrompt myXPConfig)
    , ("M-d", addName "NSP Console" $ namedScratchpadAction scratchpads "console")
    , ("M-c", addName "NSP Chat" $ namedScratchpadAction scratchpads "signalApp")
    , ("M-f", addName "Firefox" $ spawn "firefox")
    , ("M-S-f", addName "Chromium Incognito" $ spawn "chromium --incognito")
    , ("M-o", addName "Unstuck xdotool" $ spawn "xdotool keyup super&")
    ] ^++^

    subKeys "Windows"
    [ ("M-S-c", addName "Kill" $ kill)
    , ("M-<Tab>", addName "Navigate D" $ windows W.focusDown)
    , ("M-S-<Tab>", addName "Navigate U" $ windows W.focusUp)
    , ("M-m", addName "Navigate M" $ windows W.focusMaster)
    , ("M-<Return>", addName "Swap master" $ windows W.swapMaster)
    , ("M-S-j", addName "Swap with next" $ windows W.swapDown)
    , ("M-S-k", addName "Swap with previous" $ windows W.swapUp)
    , ("M-t", addName "Push back" $ withFocused $ windows . W.sink)
    ] ^++^

    subKeys "Screens"
    (
       zipM "M-"  "Switch to screen" screenKeys [0..] (\ws -> screenWorkspace ws >>= flip whenJust (windows . W.view))
    ++ zipM "M-S-" "Move to screen" screenKeys [0..] (\ws -> screenWorkspace ws >>= flip whenJust (windows . W.shift))
    ) ^++^

    subKeys "Workspaces"
    (
       zipM "M-"  "View ws" wsKeys [0..] (withNthWorkspace W.greedyView)
    ++ zipM "M-S-" "Move ws" wsKeys [0..] (withNthWorkspace W.shift)
    ) ^++^

    subKeys "Layout Management"
    [ ("M-<Space>" , addName "Cycle all layouts" $ sendMessage NextLayout)
    , ("M-n" , addName "Resize" $ refresh)
    , ("M-S-x" , addName "Reflect" $ sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTX)
    ] ^++^

    subKeys "Resize"
    [ ("M-h" , addName "Shrink master" $ sendMessage Shrink)
    , ("M-l" , addName "Expand master" $ sendMessage Expand)
    , ("M-," , addName "Increase master windows" $ sendMessage (IncMasterN 1))
    , ("M-." , addName "Decrease master windows" $ sendMessage (IncMasterN (-1)))
    ]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

myEventHook = handleEventHook def <+> fullscreenEventHook <+> docksEventHook

myWorkspaces :: [WorkspaceId]
myWorkspaces = [ "1", "2", "3", "4", "5", "6", "7", "8", "9"]

topbar :: Dimension
gap :: Int
myFont, myWideFont, colorBlack, colorBlackAlt, colorBlue, colorGray,
  colorGrayAlt, colorWhite, base02, base03, blue, red, yellow, active :: String
myFont               = "xft:Roboto Condensed:style=Regular:pixelsize=16"
myWideFont           = "xft:Roboto Condensed:style=Regular:pixelsize=180"
colorBlack           = "#020202"
colorBlackAlt        = "#1c1c1c"
colorBlue            = "#3955c4"
colorGray            = "#444444"
colorGrayAlt         = "#161616"
colorWhite           = "#a9a6af"
base00               = "#657b83"
base02               = "#073642"
base03               = "#002b36"
blue                 = "#268bd2"
red                  = "#dc322f"
yellow               = "#b58900"
active               = blue
topbar               = 10
gap                  = 10
myNormalBorderColor  = colorBlackAlt
myFocusedBorderColor = colorGray

myXPConfig :: XPConfig
myXPConfig = defaultXPConfig
    { font               = myFont
    , bgColor            = colorBlack
    , fgColor            = colorWhite
    , bgHLight           = colorBlue
    , fgHLight           = colorWhite
    , borderColor        = colorGrayAlt
    , promptBorderWidth  = 1
    , height             = 16
    , position           = Top
    , historySize        = 100
    , historyFilter      = deleteConsecutive
    , autoComplete       = Nothing
    }

myTabTheme :: Theme
myTabTheme = defaultTheme
    { fontName            = myFont
    , activeColor         = active
    , inactiveColor       = base02
    , activeBorderColor   = active
    , inactiveBorderColor = base02
    , activeTextColor     = base03
    , inactiveTextColor   = base00
    }

topBarTheme :: Theme
topBarTheme = def
    { fontName            = myFont
    , inactiveBorderColor = base03
    , inactiveColor       = base03
    , inactiveTextColor   = base03
    , activeBorderColor   = active
    , activeColor         = active
    , activeTextColor     = active
    , urgentBorderColor   = red
    , urgentTextColor     = yellow
    , decoHeight          = topbar
    }

myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
    { swn_font              = myWideFont
    , swn_fade              = 0.5
    , swn_bgcolor           = "#000000"
    , swn_color             = "#FFFFFF"
    }

myNav2DConf :: Navigation2DConfig
myNav2DConf = def
    { defaultTiledNavigation    = centerNavigation
    , floatNavigation           = centerNavigation
    , screenNavigation          = lineNavigation
    , layoutNavigation          = [("Full", centerNavigation)]
    , unmappedWindowRect        = [("Full", singleWindowRect)]
    }

myLayout = showWorkspaceName
    $ reflectToggle
    $ flex ||| tabs
    where
        smallMonResWidth  = 1920

        showWorkspaceName = showWName' myShowWNameTheme
        reflectToggle     = mkToggle (single REFLECTX)

        named n           = renamed [(XMonad.Layout.Renamed.Replace n)]
        trimNamed w n     = renamed [(XMonad.Layout.Renamed.CutWordsLeft w),
                                     (XMonad.Layout.Renamed.PrependWords n)]
        suffixed n        = renamed [(XMonad.Layout.Renamed.AppendWords n)]
        trimSuffixed w n  = renamed [(XMonad.Layout.Renamed.CutWordsRight w),
                                     (XMonad.Layout.Renamed.AppendWords n)]

        addTopBar         = noFrillsDeco shrinkText topBarTheme

        mySpacing         = spacing gap
        mySmallSpacing    = spacing sGap
        sGap              = quot gap 2
        myGaps            = gaps [(U, gap),(D, gap),(L, gap),(R, gap)]
        mySmallGaps       = gaps [(U, sGap),(D, sGap),(L, sGap),(R, sGap)]

        flex = trimNamed 5 "Flex"
            $ avoidStruts
            $ windowNavigation
            $ addTopBar
            $ addTabs shrinkText myTabTheme
            $ subLayout [] (Simplest ||| Accordion)
            $ ifWider smallMonResWidth wideLayouts standardLayouts
            where
                wideLayouts = myGaps $ mySpacing
                    $ (suffixed "Wide 3Col" $ ThreeColMid 1 (1/20) (1/2))
                  ||| (trimSuffixed 1 "Wide BSP" $ hiddenWindows emptyBSP)
                standardLayouts = mySmallGaps $ mySmallSpacing
                    $ (suffixed "Std 2/3" $ ResizableTall 1 (1/20) (2/3) [])
                  ||| (suffixed "Std 1/2" $ ResizableTall 1 (1/20) (1/2) [])

        tabs = named "Tabs"
            $ avoidStruts
            $ addTopBar
            $ addTabs shrinkText myTabTheme
            $ Simplest

wrapClickWorkspace ws = "%{A:" ++ xdo index ++ ":}" ++ ws ++ "%{A}"
    where
        wsIdxToString Nothing = "1"
        wsIdxToString (Just n) = show $ mod (n+1) $ length myWorkspaces
        index = wsIdxToString (elemIndex ws myWorkspaces)
        xdo key = "xdotool key super+" ++ key

myLogHook :: D.Client -> PP
myLogHook dbus = def
    { ppOutput = dbusOutput dbus
    , ppCurrent = wrap "%{B#88000000}%{u#ddd} " " %{-u}%{B-}" . wrapClickWorkspace
    , ppVisible = wrap "%{B#88000000}%{u#808080} " " %{-u}%{B-}"
    , ppHidden = wrap " " " " . wrapClickWorkspace
    , ppHiddenNoWindows = wrap "%{F#44ffffff} " " %{F-}" . wrapClickWorkspace
    , ppSort = fmap (namedScratchpadFilterOutWorkspace .) (ppSort defaultPP)
		}

dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
             D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"

myConsole = "kitty --class=kittyScratch --title=console"
consoleResource = "kittyScratch"
isConsole = (className =? consoleResource)

signalAppCommand = "chromium --app-id=bikioccmkafdpakkkcpdbppfkghcmihk"
signalAppResource = "crx_bikioccmkafdpakkkcpdbppfkghcmihk"
isSignalApp = (resource =? signalAppResource)

scratchpads =
    [ (NS "console" myConsole isConsole (customFloating $ W.RationalRect 0 (1/50) 1 (3/4)))
    , (NS "signalApp" signalAppCommand isSignalApp defaultFloating)
    ]

{- IntelliJ popup fix from http://youtrack.jetbrains.com/issue/IDEA-74679#comment=27-417315 -}
{- and http://youtrack.jetbrains.com/issue/IDEA-101072#comment=27-456320 -}
(~=?) :: Eq a => Query [a] -> [a] -> Query Bool
q ~=? x = fmap (isPrefixOf x) q

manageIdeaCompletionWindow = (className ~=? "jetbrains-") <&&> (title ~=? "win") --> doIgnore

myManageHook :: ManageHook
myManageHook =
        manageSpecific
    <+> manageDocks
    <+> namedScratchpadManageHook scratchpads
    where
        manageSpecific = composeAll . concat $
            [ [className =? "stalonetray"    --> doIgnore ]
            , [title     =? "Clip to Evernote" --> doIgnore ]
            , [className =? c --> doShift (myWorkspaces !! 0) | c <- myWebS ]
            , [className =? "MPlayer"        --> doFloat  ]
            , [className =? "Gimp"           --> doFloat  ]
            , [resource  =? "desktop_window" --> doIgnore ]
            , [resource  =? "kdesktop"       --> doIgnore ]
            , [title =? "Password Required" --> doFloat ]
            , [appName   =? a --> doCenterFloat | a <- myFloatAS ]
            , [isFullscreen --> doFullFloat]
            , [manageIdeaCompletionWindow]
            , [appName =? "sun-awt-X11-XWindowPeer" <&&> className =? "jetbrains-idea" --> doIgnore]
            ]
            where
                myWebS = ["Chromium","Firefox"]
                myFloatAS = ["sun-awt-X11-XDialogPeer", "MATLAB", "Dialog",
                    "file_progress", "vncviewer"]

myStartupHook :: Maybe String -> X ()
myStartupHook maybeBarMonitor = do
    setDefaultCursor xC_left_ptr
    spawnOnce "wmname LG3D"
    spawnOnce "xset +dpms"
    spawnOnce "xset dpms 0 0 300"
    spawnOnce "xrdb -I$HOME $HOME/.Xresources && test -f ~/.Xresources.local && xrdb -merge ~/.Xresources.local"
    spawnOnce "nitrogen --restore"
    case maybeBarMonitor of
      Nothing -> spawn "polybar main"
      Just barMonitor -> spawn $ "MONITOR=" ++ barMonitor ++ " polybar main"
    spawnOnce "polybar main"
    spawnOnce "urxvtd -q -o -f"
    spawnOnce "udiskie"
    spawnOnce "xscreensaver -no-splash"
    spawn "rm -f ~/.xmonad/xmonad.state"
    spawnOnce "copyq"

myTerminal = "urxvtc"

data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

instance UrgencyHook LibNotifyUrgencyHook where
    urgencyHook LibNotifyUrgencyHook w = do
        name     <- getName w
        Just idx <- fmap (W.findTag w) $ gets windowset
        safeSpawn "notify-send" [show name, "workspace " ++ idx]

main :: IO ()
main = do
    barMonitor <- getBarMonitor
    dbus <- D.connectSession
    D.requestName dbus (D.busName_ "org.xmonad.Log")
        [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
    xmonad
        $ withNavigation2DConfig myNav2DConf
        $ withUrgencyHook LibNotifyUrgencyHook
        $ addDescrKeys' ((myModMask, xK_F1), showKeybindings) myKeys
        $ ewmh
        $ def
            { focusFollowsMouse  = myFocusFollowsMouse
            , clickJustFocuses   = myClickJustFocuses
            , borderWidth        = myBorderWidth
            , modMask            = mod4Mask
            , workspaces         = myWorkspaces
            , normalBorderColor  = myNormalBorderColor
            , focusedBorderColor = myFocusedBorderColor
            , mouseBindings      = myMouseBindings
            , layoutHook         = myLayout
            , manageHook         = myManageHook
            , handleEventHook    = myEventHook
            , logHook            = dynamicLogWithPP (myLogHook dbus)
            , startupHook        = myStartupHook barMonitor
            , terminal           = myTerminal
            }
