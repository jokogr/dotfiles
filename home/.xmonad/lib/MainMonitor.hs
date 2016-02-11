module MainMonitor
  ( Monitor(..)
  , getMonitor
  ) where

import Graphics.X11.Xlib
import Graphics.X11.Xrandr
import Control.Monad
import Control.Monad.Trans
import Control.Monad.Trans.Maybe
import Data.Maybe

data Monitor = Monitor { width :: Int
                       -- , height :: Int
                       , posX :: Int
                       -- , posY :: Int
                       , isPrimary :: Bool
                       } deriving (Eq, Show)

xrrCrtcInfoToMonitor :: RROutput -> XRRCrtcInfo -> Monitor
xrrCrtcInfoToMonitor primaryOutput crtcInfo =
  Monitor { width = fromIntegral (xrr_ci_width crtcInfo)
          -- , height = fromIntegral (xrr_ci_height crtcInfo)
          , posX = fromIntegral (xrr_ci_x crtcInfo)
          -- , posY = fromIntegral (xrr_ci_y crtcInfo)
          , isPrimary = elem primaryOutput (xrr_ci_outputs crtcInfo)
          }

xrrGetOutputInfoAll :: Display -> XRRScreenResources -> IO [XRROutputInfo]
xrrGetOutputInfoAll dpy res = do
  outputInfos <- mapM (xrrGetOutputInfo dpy res) (xrr_sr_outputs res) 
  return (catMaybes outputInfos)

xrrGetCrtcInfoAll :: Display -> XRRScreenResources -> [RRCrtc] -> IO [XRRCrtcInfo]
xrrGetCrtcInfoAll dpy res rrCtrcs = do
  xrrCrtcInfos <- mapM (xrrGetCrtcInfo dpy res) rrCtrcs
  return (catMaybes xrrCrtcInfos)

getCurCrtc :: XRROutputInfo -> Maybe RRCrtc
getCurCrtc xrrOutputInfo = if xrr_oi_crtc xrrOutputInfo == 0 then Nothing
                           else Just $ xrr_oi_crtc xrrOutputInfo

-- Gets the primary monitor
getPrimaryMonitor :: [Monitor] -> Maybe Monitor
getPrimaryMonitor [] = Nothing
getPrimaryMonitor (x:xs) =
  if isPrimary x == True
    then Just x
    else getPrimaryMonitor xs

-- Gets the widest monitor
getBiggestMonitor :: [Monitor] -> Maybe Monitor
getBiggestMonitor [] = Nothing
getBiggestMonitor [x] = Just x
getBiggestMonitor (x:xs) = Just $ foldr checkMax x xs where
  checkMax x acc = if width x > width acc then x else acc

getMonitor :: IO (Maybe (Maybe Monitor))
getMonitor = runMaybeT $ do
  dpy <- lift $ openDisplay ""
  root <- lift $ rootWindow dpy (defaultScreen dpy)
  res <- MaybeT $ xrrGetScreenResourcesCurrent dpy root
  primary_output <- lift $ xrrGetOutputPrimary dpy root
  output_infos <- lift $ xrrGetOutputInfoAll dpy res
  curr_crtcs <- lift $ xrrGetCrtcInfoAll dpy res (catMaybes $ map getCurCrtc output_infos)
  let monitors = map (xrrCrtcInfoToMonitor primary_output) curr_crtcs
      monitor = (if getPrimaryMonitor monitors == Nothing then getBiggestMonitor monitors else getPrimaryMonitor monitors)
  return monitor
