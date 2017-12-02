{-# LANGUAGE TypeSynonymInstances, MultiParamTypeClasses, DeriveDataTypeable,
    NoMonomorphismRestriction, FlexibleContexts #-}

import XMonad hiding ( (|||) ) -- get III from X.L.LayoutCombinators
import XMonad.Actions.Navigation2D
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
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
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (hPutStrLn, runProcessWithInput, spawnPipe)
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce
import Graphics.X11.ExtraTypes.XF86

import Control.Monad.Trans (lift)
import Control.Monad.Trans.Maybe
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
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)
    , ((modm,               xK_s     ), shellPrompt myXPConfig)
    , ((modm,               xK_d     ), myScratchPad)
    , ((modm .|. shiftMask, xK_l     ), spawn "i3lock-fancy -gp")
    , ((modm,               xK_p     ), spawn "toggleDisplayMode.sh")
    -- close focused window
    , ((modm .|. shiftMask, xK_c     ), kill)

     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)

    , ((modm,               xK_Tab   ), windows W.focusDown)
    , ((modm .|. shiftMask, xK_Tab   ), windows W.focusUp  )

    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm,               xK_Return), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )

    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)

    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modm,               xK_t     ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

    , ((modm .|. shiftMask, xK_x),
        sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTX)

    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))
    , ((modm              , xK_f     ), spawn "firefox")
    , ((modm .|. shiftMask, xK_f     ), spawn "chromium --incognito")
    , ((modm              , xK_o     ), spawn "xdotool keyup super&")
    , ((modm              , xK_q     ),
        spawn "pkill polybar; xmonad --restart")
    , ((0, xF86XK_AudioMute), spawn "amixer -D pulse set Master toggle")
    ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


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

myEventHook = handleEventHook defaultConfig <+> fullscreenEventHook <+> docksEventHook

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

manageScratchPad :: ManageHook
manageScratchPad = scratchpadManageHook (W.RationalRect 0 (1/50) 1 (3/4))

myScratchPad :: X ()
myScratchPad = scratchpadSpawnActionCustom "urxvtc -name scratchpad"

myManageHook :: ManageHook
myManageHook = composeAll . concat $
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
    ] where
        myWebS = ["Chromium","Firefox"]
	myFloatAS = ["sun-awt-X11-XDialogPeer", "MATLAB", "Dialog",
		    "file_progress", "vncviewer"]

myStartupHook :: Maybe String -> X ()
myStartupHook maybeBarMonitor = do
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

main :: IO ()
main = do
    barMonitor <- getBarMonitor
    dbus <- D.connectSession
    D.requestName dbus (D.busName_ "org.xmonad.Log")
        [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
    xmonad $ withNavigation2DConfig myNav2DConf $ ewmh defaultConfig
        { terminal           = "urxvtc"
        , focusFollowsMouse  = myFocusFollowsMouse
        , clickJustFocuses   = myClickJustFocuses
        , borderWidth        = myBorderWidth
        , modMask            = mod4Mask
        , workspaces         = myWorkspaces
        , normalBorderColor  = myNormalBorderColor
        , focusedBorderColor = myFocusedBorderColor
        , keys               = myKeys
        , mouseBindings      = myMouseBindings
        , layoutHook         = myLayout
        , manageHook         = manageDocks <+> myManageHook <+> manageScratchPad
        , handleEventHook    = myEventHook
        , logHook            = dynamicLogWithPP (myLogHook dbus)
        , startupHook        = myStartupHook barMonitor
        }
