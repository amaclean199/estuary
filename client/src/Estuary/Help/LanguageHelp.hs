{-# LANGUAGE OverloadedStrings #-}

module Estuary.Help.LanguageHelp where

import Reflex
import Reflex.Dom
import Data.Text (Text)
import qualified Data.Text as Td
import Data.Map
import Control.Monad
import GHCJS.DOM.EventM -- just used for our test, maybe delete-able later

import Estuary.Help.MiniTidal
import Estuary.Help.LaCalle
import Estuary.Help.Alobestia
import Estuary.Help.ColombiaEsPasion
import Estuary.Help.CQenze
import Estuary.Help.Crudo
import Estuary.Help.Imagina
import Estuary.Help.Maria
import Estuary.Help.Medellin
import Estuary.Help.Morelia
import Estuary.Help.Natural
import Estuary.Help.NoHelpFile
import Estuary.Help.Puntoyya
import Estuary.Help.Saborts
import Estuary.Help.Saludos
import Estuary.Help.Sentidos
import Estuary.Help.Si
import Estuary.Help.Sucixxx
import Estuary.Help.Togo
import Estuary.Help.Vocesotrevez
import Estuary.Help.PunctualAudio
import Estuary.Types.TidalParser
import Estuary.Languages.TidalParsers
import Estuary.Types.TextNotation

parserToHelp :: (MonadWidget t m) => TextNotation -> m ()
parserToHelp (TidalTextNotation Alobestia) = alobestiaHelpFile
parserToHelp (TidalTextNotation ColombiaEsPasion) = colombiaEsPasionHelpFile
parserToHelp (TidalTextNotation CQenze) = cqenzeHelpFile
parserToHelp (TidalTextNotation Crudo) = crudoHelpFile
parserToHelp (TidalTextNotation Imagina) = imaginaHelpFile
parserToHelp (TidalTextNotation Maria) = mariaHelpFile
parserToHelp (TidalTextNotation Medellin) = medellinHelpFile
parserToHelp (TidalTextNotation Morelia) = moreliaHelpFile
parserToHelp (TidalTextNotation Natural) = naturalHelpFile
parserToHelp (TidalTextNotation Puntoyya) = puntoyyaHelpFile
parserToHelp (TidalTextNotation Saborts) = sabortsHelpFile
parserToHelp (TidalTextNotation Saludos) = saludosHelpFile
parserToHelp (TidalTextNotation Sentidos) = sentidosHelpFile
parserToHelp (TidalTextNotation Si) = siHelpFile
parserToHelp (TidalTextNotation Sucixxx) = sucixxxHelpFile
parserToHelp (TidalTextNotation MiniTidal) = miniTidalHelpFile
parserToHelp (TidalTextNotation LaCalle) = laCalleHelpFile
parserToHelp (TidalTextNotation Vocesotrevez) = vocesotrevezHelpFile
parserToHelp (TidalTextNotation Togo) = togoHelpFile
parserToHelp Punctual = punctualAudioHelpFile
parserToHelp _ = noHelpFile
