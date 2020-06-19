{-# LANGUAGE OverloadedStrings #-}

module Estuary.Widgets.Config where

import Reflex hiding (Request,Response)
import Reflex.Dom hiding (Request,Response)
import qualified Data.Text as T
import Data.Map.Strict

import Estuary.Widgets.Editor
import Estuary.Widgets.Generic
import Estuary.Types.Context
import Estuary.Types.Language
import Estuary.Render.DynamicsMode
import qualified Estuary.Types.Term as Term

import qualified Sound.Punctual.Resolution as Punctual

configWidget :: MonadWidget t m => Editor t m (Event t ContextChange)
configWidget = do

  canvasEnabledEv <- divClass "config-option primary-color ui-font" $ do
    text "Canvas: "
    canvasInput <- elClass "label" "switch" $ do
      x <- checkbox True def
      elClass "span" "slider round" (return x)
    el "div" $ dynText =<< (translatableText $ fromList [
      (English,"The drawing of visual elements on screen"),
      (Español,"Spanish placeholder text for canvas option" )
      ])
    return $ fmap (\x -> \c -> c { canvasOn = x }) $ _checkbox_change canvasInput
  elClass "hr" "dashed" $  text ""

  superDirtEnabledEv <- divClass "config-option primary-color ui-font" $ do
    text "SuperDirt: "
    sdInput <- elClass "label" "switch" $ do
      x <- checkbox False def
      elClass "span" "slider round" (return x)
    el "div" $ dynText =<< (translatableText $ fromList [
      (English,"SuperCollider implementation of the Dirt sampler for the Tidal programming language"),
      (Español,"Spanish placeholder text for superdirt option" )
      ])
    return $ fmap (\x -> (\c -> c { superDirtOn = x } )) $ _checkbox_change sdInput
  elClass "hr" "dashed" $  text ""

  webDirtEnabledEv <- divClass "config-option primary-color ui-font" $ do
    text "WebDirt: "
    wdInput <-elClass "label" "switch" $ do
      x <- checkbox True def
      elClass "span" "slider round" (return x)
    el "div" $ dynText =<< (translatableText $ fromList [
      (English,"A rewrite of Alex McLean's Dirt sampling engine (by Alex McLean) to run in the web browser using the Web Audio API"),
      (Español,"Spanish placeholder text for webdirt option" )
      ])
    return $ fmap (\x -> (\c -> c { webDirtOn = x } )) $ _checkbox_change wdInput
  elClass "hr" "dashed" $  text ""

  dynamicsModeEv <- divClass "config-option primary-color ui-font" $ do
    text "Dynamics: "
    let dmMap = fromList $ zip dynamicsModes (fmap (T.pack . show) dynamicsModes)
    dmChange <- _dropdown_change <$> dropdown DefaultDynamics (constDyn dmMap) (def & attributes .~ constDyn ("class" =: "ui-dropdownMenus primary-color primary-borders ui-font" <> "style" =: "background-color: transparent"))
    el "div" $ dynText =<< (translatableText $ fromList [
      (English,"The variation in volume in the audio signal"),
      (Español,"Spanish placeholder text for dynamics option" )
      ])
    return $ fmap (\x c -> c { dynamicsMode = x }) dmChange -- context -> context
  elClass "hr" "dashed" $  text ""

  resolutionChangeEv <- divClass "config-option primary-color ui-font" $ do
    term Term.Resolution >>= dynText
    text ": "
    let resolutions = [Punctual.QHD,Punctual.FHD,Punctual.HD,Punctual.WSVGA,Punctual.SVGA,Punctual.VGA,Punctual.QVGA]
    let resMap = fromList $ zip resolutions $ fmap (T.pack . show) resolutions
    resChange <- _dropdown_change <$> dropdown Punctual.HD (constDyn resMap) (def & attributes .~ constDyn ("class" =: "ui-dropdownMenus primary-color primary-borders ui-font"))
    el "div" $ dynText =<< (translatableText $ fromList [
      (English,"2560 × 1440 (QHD), 1920 × 1080 (FHD), 1280 × 720 (HD), 1024 × 576, 1024 × 600 (WSVGA), 800 × 600 (SVGA), 640 × 480 (VGA), 320 × 240 (QVGA)"),
      (Español,"Spanish placeholder text for resolution option" )
      ])
    return $ fmap (\x c -> c { resolution = x }) resChange
  elClass "hr" "dashed" $  text ""

  brightnessChangeEv <- divClass "config-option primary-color ui-font" $ do
    term Term.Brightness >>= dynText
    text ": "
    let brightnessMap = fromList [(1.0,"100%"),(0.5,"50%"),(0.25,"25%"),(0.1,"10%")]
    brightnessChange <- _dropdown_change <$> dropdown 1.0 (constDyn brightnessMap) (def & attributes .~ constDyn ("class" =: "ui-dropdownMenus primary-color primary-borders ui-font"))
    el "div" $ dynText =<< (translatableText $ fromList [
      (English,"Of canvas drawings"),
      (Español,"Spanish placeholder text for brightness option" )
      ])
    return $ fmap (\x c -> c { brightness = x }) brightnessChange

  return $ mergeWith (.) [canvasEnabledEv, superDirtEnabledEv, webDirtEnabledEv, dynamicsModeEv, resolutionChangeEv, brightnessChangeEv]
