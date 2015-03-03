{-# LANGUAGE TypeSynonymInstances, MultiParamTypeClasses, DeriveDataTypeable,
    NoMonomorphismRestriction #-}

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.Master
import XMonad.Layout.MultiToggle
import XMonad.Layout.Named
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Reflect
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (hPutStrLn, runProcessWithInput, spawnPipe)
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce
import Graphics.X11.ExtraTypes.XF86

import Data.Char
import Data.Monoid
import Data.List
import GHC.IO.Handle
import System.Exit

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

splitString :: String -> [String]
splitString s = case dropWhile Data.Char.isSpace s of
    "" -> []
    s' -> w : splitString s''
        where (w, s'') = break Data.Char.isSpace s'

myIconPath = "/home/joko/.xmonad/"
xRes = 1920
panelBoxHeight = 12

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
    , ((modm .|. shiftMask, xK_l     ), spawn "xscreensaver-command --lock")
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
    , ((modm .|. shiftMask, xK_y),
        sendMessage $ XMonad.Layout.MultiToggle.Toggle REFLECTY)

    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))
    , ((modm              , xK_f     ), spawn "firefox")
    , ((modm .|. shiftMask, xK_f     ), spawn "chromium --incognito")
    , ((modm              , xK_o     ), spawn "xdotool keyup super&")
    , ((modm              , xK_q     ),
        spawn "killall status.sh dzen2 stalonetray; xmonad --restart")
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

myEventHook = handleEventHook defaultConfig <+> fullscreenEventHook

myWorkspaces :: [WorkspaceId]
myWorkspaces = [ "1", "2", "3", "4", "5", "6", "7", "8", "9"]

myDzenFont, myFont, colorBlack, colorBlue, colorGrayAlt, colorWhite,
    colorWhiteAlt :: String
myDzenFont           = "Segoe UI:size=10:style=Semibold"
myFont               = "xft:Segoe UI:size=10:style=Semibold"
colorBlack           = "#020202"
colorBlackAlt        = "#1c1c1c"
colorBlue            = "#3955c4"
colorBlueAlt         = "#9caae2"
colorGray            = "#444444"
colorGrayAlt         = "#161616"
colorGreen           = "#99cc66"
colorWhite           = "#a9a6af"
colorWhiteAlt        = "#9d9d9d"
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
    , inactiveBorderColor = colorBlackAlt
    , inactiveColor       = colorBlack
    , inactiveTextColor   = colorGray
    , activeBorderColor   = colorGray
    , activeColor         = colorBlackAlt
    , activeTextColor     = colorWhiteAlt
    , urgentBorderColor   = colorGray
    , urgentTextColor     = colorGreen
    , decoHeight          = 14
    }

statusBarWidth :: Int
statusBarWidth = 290

commonBarSettings :: String
commonBarSettings = "-y '0' -h '16' -fn '" ++ myDzenFont ++ "' -bg '"
    ++ colorBlack ++ "' -fg '" ++ colorWhiteAlt ++ "' -p -e 'onstart=lower'"
myWorkspaceBar, myStatusBar, myTray :: Int -> Int -> String
myWorkspaceBar x width = "dzen2 -x '" ++ show x ++ "' -w '" ++
    show (width - statusBarWidth) ++ "' -ta l " ++ commonBarSettings
myStatusBar x width = "DZEN_FG2=" ++ colorGray
    ++ " /home/joko/.xmonad/status.sh | dzen2 -x '" ++ show (x + width
    - statusBarWidth) ++ "' -w '" ++ show(statusBarWidth) ++ "' -ta r "
    ++ commonBarSettings
myTray x width = "stalonetray --grow-gravity NE --icon-gravity NE"
    ++ " --icon-size 16 --max-geometry 0x1 --window-layer top --background '"
    ++ colorBlack ++ "' --geometry 1x1+"
    ++ show (x + width - statusBarWidth - 20)

data TABBED = TABBED deriving (Read, Show, Eq, Typeable)
instance Transformer TABBED Window where
    transform TABBED x k = k myFull (\_ -> x)

myTile = named "RT" $ ResizableTall 1 0.03 0.5 []
myMirr = named "MR" $ Mirror myTile
myFull = named "TS" $ tabbedAlways shrinkText myTabTheme
myTabs = named "TS" $ tabbed shrinkText myTabTheme
myTabM = named "TM" $ mastered 0.01 0.4 $ tabbed shrinkText myTabTheme

myLayout = id $ avoidStruts $ smartBorders
    $ mkToggle (single TABBED)
    $ mkToggle (single REFLECTX)
    $ mkToggle (single REFLECTY)
    $ onWorkspace (myWorkspaces !! 0) webLayouts
    $ tiled ||| Mirror tiled ||| myTabs
    where
        webLayouts = myTabs ||| myMirr ||| myTabM
        tiled   = Tall nmaster delta ratio
        nmaster = 1
        ratio   = 1/2
        delta   = 3/100

wrapTextBox :: String -> String -> String -> String -> String
wrapTextBox fg bg1 bg2 t = "^fg(" ++ bg1 ++ ")^i(" ++ myIconPath  ++
    "boxleft.xbm)^ib(1)^r(" ++ show xRes ++ "x" ++ show panelBoxHeight ++
    ")^p(-" ++ show xRes ++ ")^fg(" ++ fg ++ ")" ++ t ++ "^fg(" ++ bg1 ++ 
    ")^i(" ++ myIconPath ++ "boxright.xbm)^fg(" ++ bg2 ++ ")^r(" ++ 
    show xRes ++ "x" ++ show panelBoxHeight ++ ")^p(-" ++ show xRes ++
    ")^fg()^ib(0)"

wrapClickWorkspace ws = "^ca(1," ++ xdo "w;" ++ xdo index ++ ")" ++ "^ca(3," ++
    xdo "w;" ++ xdo index ++ ")" ++ ws ++ "^ca()^ca()"
    where
        wsIdxToString Nothing = "1"
        wsIdxToString (Just n) = show $ mod (n+1) $ length myWorkspaces
        index = wsIdxToString (elemIndex ws myWorkspaces)
        xdo key = "/usr/bin/xdotool key super+" ++ key

myLogHook :: Handle -> X ()
myLogHook h = dynamicLogWithPP $ defaultPP
    { ppOutput = hPutStrLn h
    , ppSort = fmap (namedScratchpadFilterOutWorkspace .) (ppSort defaultPP)
    , ppCurrent = wrapTextBox colorBlack colorBlue colorBlack
    , ppVisible = wrapTextBox colorBlack colorBlueAlt colorBlack .
        wrapClickWorkspace
    , ppHidden = wrapTextBox colorWhiteAlt colorGrayAlt colorBlack .
        wrapClickWorkspace
    , ppHiddenNoWindows = wrapTextBox colorBlack colorGrayAlt colorBlack .
        wrapClickWorkspace
    , ppSep = " "
    , ppWsSep = ""
    }

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
	myFloatAS = ["sun-awt-X11-XFramePeer", "MATLAB", "Dialog",
		    "file_progress", "vncviewer"]

myStartupHook :: Int -> Int -> X ()
myStartupHook x width = do
    spawnOnce "wmname LG3D"
    spawnOnce "xset +dpms"
    spawnOnce "xset dpms 0 0 300"
    spawnOnce "xrdb -merge ~/.Xresources"
    spawnOnce "nitrogen --restore"
    spawn $ myTray x width
    spawn $ myStatusBar x width
    spawnOnce "xbindkeys"
    spawnOnce "kbdd"
    spawnOnce "urxvtd -q -o -f"
    spawnOnce "udiskie"
    spawnOnce "xscreensaver -no-splash"

main :: IO ()
main = do
    mainDisplayInfoS <-
        runProcessWithInput "/home/joko/.xmonad/getMainScreenWidth.sh" [] []
    let mainDisplayS = splitString mainDisplayInfoS
    let mainDisplayX = read (mainDisplayS !! 0) :: Int
    let mainDisplayWidth = read (mainDisplayS !! 1) :: Int
    workspaceBar <- spawnPipe $ myWorkspaceBar mainDisplayX mainDisplayWidth
    xmonad $ ewmh defaultConfig
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
        , manageHook         = myManageHook <+> manageScratchPad
        , handleEventHook    = myEventHook
        , logHook            = myLogHook workspaceBar
        , startupHook        = myStartupHook mainDisplayX mainDisplayWidth
        }
