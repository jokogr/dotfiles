module BarMonitor (getBarMonitor) where

import Control.Monad
import Control.Monad.Trans.Class
import Control.Monad.Trans.Maybe
import Data.Maybe
import Graphics.X11.Xlib
import Graphics.X11.Xrandr

xrrGetOutputInfoAll :: Display -> XRRScreenResources -> IO [XRROutputInfo]
xrrGetOutputInfoAll dpy res = do
  outputInfos <- mapM (xrrGetOutputInfo dpy res) (xrr_sr_outputs res)
  return (catMaybes outputInfos)

getWidestMonitor :: Display -> XRRScreenResources -> [XRROutputInfo] -> IO XRROutputInfo
getWidestMonitor dpy sres [x] = return x
getWidestMonitor dpy sres (x:xs) = foldM checkWideness x xs where
  checkWideness currentWidest toBeChecked = do
    maybeCurrentWidestInfo <- xrrGetCrtcInfo dpy sres $ xrr_oi_crtc currentWidest
    maybeCheckInfo <- xrrGetCrtcInfo dpy sres $ xrr_oi_crtc toBeChecked
    case (maybeCurrentWidestInfo, maybeCheckInfo) of
      (Nothing, _) -> return currentWidest
      (_, Nothing) -> return currentWidest
      (Just currentWidestInfo, Just checkInfo) -> if xrr_ci_width checkInfo < xrr_ci_width currentWidestInfo
         then return currentWidest
         else return toBeChecked

-- |The 'getBarMonitor' function returns the monitor to have the status bar.
-- It returns the primary monitor if it is connected; if it is not, then it
-- returns the widest monitor.
getBarMonitor :: IO (Maybe String)
getBarMonitor = runMaybeT $ do
  dpy <- lift $ openDisplay ""
  root <- lift $ rootWindow dpy (defaultScreen dpy)
  -- TODO What's the difference?
  -- xrrGetScreenResources :: Display -> Window -> IO (Maybe XRRScreenResources)
  -- xrrGetScreenResourcesCurrent :: Display -> Window -> IO (Maybe XRRScreenResources)
  screenRes <- MaybeT $ xrrGetScreenResourcesCurrent dpy root
  primaryOutput <- lift $ xrrGetOutputPrimary dpy root
  primaryOutputInfo <- MaybeT $ xrrGetOutputInfo dpy screenRes primaryOutput
  if xrr_oi_connection primaryOutputInfo == 0
  then return $ xrr_oi_name primaryOutputInfo
  else do
    availableOutputInfo <- lift $ xrrGetOutputInfoAll dpy screenRes
    -- xrr_oi_connection 0 if connected, 1 if disconnected
    let connectedOutputs = filter (\o -> xrr_oi_connection o == 0) availableOutputInfo
    widestMonitor <- lift $ getWidestMonitor dpy screenRes connectedOutputs
    return $ show $ xrr_oi_name widestMonitor
