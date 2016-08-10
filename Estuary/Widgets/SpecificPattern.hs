{-# LANGUAGE RecursiveDo #-}
module Estuary.Widgets.SpecificPattern
where

import Reflex
import Reflex.Dom
import Estuary.Reflex.Container
import Estuary.Tidal.Types
import Estuary.Reflex.Utility
import Data.Map
import Estuary.Widgets.Generic
import Control.Monad
import Data.List(intersperse)
import GHCJS.DOM.EventM
import Data.Maybe(isJust)
import Text.Read(readMaybe)

panSampleWidget::MonadWidget t m => SpecificPattern -> Event t () -> m (Dynamic t (PatternChain,()))
panSampleWidget i e = do
  --sPattern <- sContainerWidget i e >>= mapDyn (\(a,b)->a)-- S (GeneralPattern String)
  --nPattern <- nContainerWidget i e >>= mapDyn (\(a,b)->a)
  samplePattern <- sampleContainerWidget i e >>= mapDyn (\(a,b)->a)
  panPattern <- panContainerWidget i e >>= mapDyn (\(a,b)->a)-- Pan (GeneralPattern Double)
  crushPattern <- crushContainerWidget i e >>= mapDyn (\(a,b)->a)

  --transS <- forDyn sPattern (TransformedPattern [NoTransformer])
  --transN <- forDyn nPattern (TransformedPattern [NoTransformer])
  transSample<- forDyn samplePattern (TransformedPattern [NoTransformer])
  transPan <- forDyn panPattern (TransformedPattern [NoTransformer])
  transCrush <- forDyn crushPattern (TransformedPattern [NoTransformer])

  patternChain <-combineDyn (\pan crush-> (PatternChain' pan Add (PatternChain crush))) transPan transCrush -- Dynamic t PatternChain
  patternChain' <- combineDyn (\sample chain-> PatternChain' sample Add chain) transSample patternChain
  --patternChain' <- combineDyn (\chain tN -> PatternChain' tN Add chain) patternChain transN
  --patternChain'' <- combineDyn (\chain tS-> PatternChain' tS Add chain) patternChain' transS
  forDyn patternChain' (show) >>=display
  forDyn patternChain' (\k -> (k,()))

  -- panSampleWidget::MonadWidget t m => SpecificPattern -> Event t () -> m (Dynamic t (PatternChain,()))
  -- panSampleWidget i e = do
  --   sPattern <- sContainerWidget i e >>= mapDyn (\(a,b)->a)-- S (GeneralPattern String)
  --   nPattern <- nContainerWidget i e >>= mapDyn (\(a,b)->a)
  --   panPattern <- panContainerWidget i e >>= mapDyn (\(a,b)->a)-- Pan (GeneralPattern Double)
  --   crushPattern <- crushContainerWidget i e >>= mapDyn (\(a,b)->a)
  --
  --   transS <- forDyn sPattern (TransformedPattern [NoTransformer])
  --   transN <- forDyn nPattern (TransformedPattern [NoTransformer])
  --   transPan <- forDyn panPattern (TransformedPattern [NoTransformer])
  --   transCrush <- forDyn crushPattern (TransformedPattern [NoTransformer])
  --
  --
  --   patternChain <-combineDyn (\pan crush-> (PatternChain' pan Add (PatternChain crush))) transPan transCrush -- Dynamic t PatternChain
  --   patternChain' <- combineDyn (\chain tN -> PatternChain' tN Add chain) patternChain transN
  --   patternChain'' <- combineDyn (\chain tS-> PatternChain' tS Add chain) patternChain' transS
  --   forDyn patternChain'' (show) >>=display
  --   forDyn patternChain'' (\k -> (k,()))

  --combineDyn (\a b-> (show $ Prelude.fst a)++" |+| " ++ (show $ Prelude.fst b) ) samplePattern panPattern -- Dyn (sPat,panPat)


-- generalContainerWidget::MonadWidget t m => SpecificPattern -> Event t () -> m (Dynamic t (SpecificPattern,Event t GenericSignal))
-- generalContainerWidget iVal _ = el "div" $ mdo
--   let initialMap = (0::Int)=:(Right ())
--   addGroupButton <- button' "Add Group" (fromList$ zip [0,1] [Insert $ Right (),Insert $ Left $ Group [defaultIVal] Once])
--   let cEvents = mergeWith (union) [makeSMap,deleteMap,addGroupButton]
--   (values,events) <- eitherContainer' initialMap cEvents never never widgetBuilder miscButton -- values:dyn Map k GeneralPattern,
--   let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
--   let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
--   let deleteMap = fmap (fromList) deleteList
--   let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
--   let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert $ Left defaultIVal)])) makeSKeys
--   let makeSMap = fmap (fromList) makeSList
--   values' <- forDyn values (elems)
--   returnVal <- forDyn values' (\x-> (param $ Group x Once))
--   display returnVal
--   returnVal'<-forDyn returnVal (\x->(x,never))
--   return returnVal'
--   where
--     miscButton _ _ = pingButton "+"
--     intersperse' x [] = [x]
--     intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]
--     (widgetBuilder,defaultIVal,param) = case iVal of
--       (S _) -> (textWidget,Atom Blank Once,S)
--       (N _) -> (crushWidget,Atom 0 Once,N)
--       (Pan _) -> (panWidget,Atom 0.5 Once,Pan)
--       (Crush _) -> (crushWidget,Atom 16 Once,Crush)
--       otherwise -> (textWidget,Atom Blank Once,N)
--       -- @Sound _ =






crushContainerWidget::(MonadWidget t m) => SpecificPattern -> Event t () -> m (Dynamic t (SpecificPattern,Event t ()))
crushContainerWidget iVal _ = el "div" $ mdo
  let initialMap = (0::Int)=:(Right ())
  addGroupButton <- button' "Add Group" (fromList$ zip [0,1] [Insert $ Right (),Insert $ Left $ Group [Atom 16 Once] Once])
  let cEvents = mergeWith (union) [makeSMap,deleteMap,addGroupButton]
  (values,events) <- eitherContainer' initialMap cEvents never  never crushWidget miscButton -- values:dyn Map k GeneralPattern,
  let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
  let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
  let deleteMap = fmap (fromList) deleteList
  let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
  let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert (Left (Atom 16 Once)))])) makeSKeys
  let makeSMap = fmap (fromList) makeSList
  values' <- forDyn values (elems)
  returnVal <- forDyn values' (\x-> (Crush $ Group x Once))
  display returnVal
  returnVal'<-forDyn returnVal (\x->(x,never))
  return returnVal'
  where
    miscButton _ _ = pingButton "+"
    intersperse' x [] = [x]
    intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]


sampleContainerWidget::(MonadWidget t m) => SpecificPattern -> Event t () -> m (Dynamic t (SpecificPattern,Event t ()))
sampleContainerWidget (S genPat) _ = el "div" $ mdo
  let initialMap = (0::Int)=:(Right ())
  let cEvents = mergeWith (union) [makeSMap,deleteMap]
  (values,events) <- eitherContainer' initialMap cEvents never  never sampleWidget miscButton -- values:dyn Map k GeneralPattern,
  let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
  let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
  let deleteMap = fmap (fromList) deleteList
  let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
  let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert $ Left $ Atom (Sample ("a",0)) Once)])) makeSKeys
  let makeSMap = fmap (fromList) makeSList
  values' <- forDyn values (elems)
  returnVal <- forDyn values' (\x-> (Sound $ Group x Once))
  display returnVal
  returnVal'<-forDyn returnVal (\x->(x,never))
  return returnVal'
  where
    miscButton _ _ = pingButton "+"
    intersperse' x [] = [x]
    intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]

panContainerWidget::(MonadWidget t m) => SpecificPattern -> Event t () -> m (Dynamic t (SpecificPattern,Event t ()))
panContainerWidget iVal _ = el "div" $ mdo
  let initialMap = (0::Int)=:(Right ())
  addGroupButton <- button' "Add Group" (fromList$ zip [0,1] [Insert $ Right (),Insert $ Left $ Group [Atom 0.5 Once] Once])
  let cEvents = mergeWith (union) [makeSMap,deleteMap,addGroupButton]
  (values,events) <- eitherContainer' initialMap cEvents never  never panWidget miscButton -- values:dyn Map k GeneralPattern,
  let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
  let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
  let deleteMap = fmap (fromList) deleteList
  let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
  let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert (Left (Atom 0.5 Once)))])) makeSKeys
  let makeSMap = fmap (fromList) makeSList
  values' <- forDyn values (elems)
  returnVal <- forDyn values' (\x-> (Pan $ Group x Once))
  display returnVal
  returnVal'<-forDyn returnVal (\x->(x,never))
  return returnVal'
  where
    miscButton _ _ = pingButton "+"
    intersperse' x [] = [x]
    intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]


nContainerWidget::(MonadWidget t m) => SpecificPattern -> Event t () -> m (Dynamic t (SpecificPattern,Event t ()))
nContainerWidget iVal _ = el "div" $ mdo
  let initialMap = (0::Int)=:(Right ())
  addGroupButton <- button' "Add Group" (fromList $ zip [0,1] [Insert $ Right (),Insert $ Left $ Group [Atom 0 Once] Once])
  let cEvents = mergeWith (union) [makeSMap,deleteMap,addGroupButton]
  (values,events) <- eitherContainer' initialMap cEvents never  never nWidget miscButton -- values:dyn Map k GeneralPattern,
  let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
  let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
  let deleteMap = fmap (fromList) deleteList
  let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
  let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert (Left Blank))])) makeSKeys
  let makeSMap = fmap (fromList) makeSList
  values' <- forDyn values (elems)
  returnVal <- forDyn values' (\x-> (N $ Group x Once))
  display returnVal
  returnVal'<-forDyn returnVal (\x->(x,never))
  return returnVal'
  where
    miscButton _ _ = pingButton "+"
    intersperse' x [] = [x]
    intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]

sContainerWidget::(MonadWidget t m) => SpecificPattern -> Event t () -> m (Dynamic t (SpecificPattern,Event t ()))
sContainerWidget (S genPat) _ = el "div" $ mdo
  let initialMap = (0::Int)=:(Right ())
  let cEvents = mergeWith (union) [makeSMap,deleteMap]
  (values,events) <- eitherContainer' initialMap cEvents never  never textWidget miscButton -- values:dyn Map k GeneralPattern,
  let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
  let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
  let deleteMap = fmap (fromList) deleteList
  let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
  let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert (Left Blank))])) makeSKeys
  let makeSMap = fmap (fromList) makeSList
  values' <- forDyn values (elems)
  returnVal <- forDyn values' (\x-> (S $ Group x Once))
  display returnVal
  returnVal'<-forDyn returnVal (\x->(x,never))
  return returnVal'
  where
    miscButton _ _ = pingButton "+"
    intersperse' x [] = [x]
    intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]

--miscSelectButton:: MonadWidget t m => GeneralPattern a -> Event t () ->  m (Dynamic t ((),Event t GenericSignal))
--miscSelectButton

panWidget::MonadWidget t m => GeneralPattern Double -> Event t () -> m (Dynamic t (GeneralPattern Double, Event t GenericSignal))
panWidget iVal _ = do
  text "0"
  let attrs = constDyn $ fromList $ zip ["type","min","max","step","style"] ["range","0","1","0.01","width:75px"]
  slider<-textInput $ def & textInputConfig_inputType .~ "range" & textInputConfig_attributes .~ attrs
  text "1"
  let panVal = _textInput_value slider
  panVal' <- forDyn panVal (\x-> if isJust (readMaybe x::Maybe Double) then Atom (read x::Double) Once else Atom 0.5 Once)
  deleteButton <- button' "-" DeleteMe
  forDyn panVal' (\k -> (k,deleteButton))

crushWidget::MonadWidget t m => GeneralPattern Int -> Event t () -> m (Dynamic t (GeneralPattern Int, Event t GenericSignal))
crushWidget iVal _ = do
  text "0"
  let attrs = constDyn $ fromList $ zip ["type","min","max","step","style"] ["range","0","16","1","width:75px"]
  slider<-textInput $ def & textInputConfig_inputType .~ "range" & textInputConfig_attributes .~ attrs
  text "16"
  let panVal = _textInput_value slider
  panVal' <- forDyn panVal (\x-> if isJust (readMaybe x::Maybe Int) then Atom (read x::Int) Once else Atom 16 Once)
  deleteButton <- button' "-" DeleteMe
  forDyn panVal' (\k -> (k,deleteButton))

textWidget::MonadWidget t m => GeneralPattern String-> Event t () -> m (Dynamic t (GeneralPattern String,Event t GenericSignal))
textWidget iVal _ = do
  text "  Sample:"
  textField <-textInput $ def & textInputConfig_attributes .~ constDyn ("style"=:"width:50px;") & textInputConfig_initialValue .~ (show iVal)
  let inputVal = _textInput_value textField
  plusButton <- button "^" >>=count
  minusButton <- button "v">>=count
  deleteButton <- button' "-" (DeleteMe)
  repeats <- combineDyn (\a b ->(a+1-b)) plusButton minusButton
  repeats' <- forDyn repeats (\k->if k>0 then Rep k else Div (abs (k-2)))
  genPat <- combineDyn (\str rep-> if str=="" ||str=="~" then Blank else Atom str rep) inputVal repeats'
  forDyn genPat (\k-> (k,deleteButton))

nWidget::MonadWidget t m => GeneralPattern Int-> Event t () -> m (Dynamic t (GeneralPattern Int,Event t GenericSignal))
nWidget iVal _ = do
  let attrs = def & textInputConfig_attributes .~ constDyn ("style"=:"width:20px;") & textInputConfig_initialValue .~ (show iVal) & textInputConfig_inputType .~"number"
  textField <-textInput attrs
  let inputVal = _textInput_value textField
  plusButton <- button "^" >>=count
  minusButton <- button "v">>=count
  deleteButton <- button' "-" (DeleteMe)
  repeats <- combineDyn (\a b ->(a+1-b)) plusButton minusButton
  repeats' <- forDyn repeats (\k->if k>0 then Rep k else Div (abs (k-2)))
  genPat <- combineDyn (\str rep-> if isJust (readMaybe str::Maybe Int) then Atom (read str::Int) rep else Atom 0 rep ) inputVal repeats'
  forDyn genPat (\k-> (k,deleteButton))


builder:: MonadWidget t m => GeneralPattern String -> Event t () -> m (Dynamic t (GeneralPattern String, Event t GenericSignal))
builder Blank _ = textWidget Blank never
builder (Atom a rep) _ = textWidget (Atom a rep) never
builder (Group l rep) _ = groupWidget (Group l rep) never


groupWidget::MonadWidget t m => GeneralPattern String -> Event t () -> m (Dynamic t (GeneralPattern String, Event t GenericSignal))
groupWidget iVal _= mdo
  text " ["
  textField <-textInput $ def & textInputConfig_attributes .~ constDyn ("style"=:"width:50px;") & textInputConfig_initialValue .~ (show iVal)
  let inputVal = _textInput_value textField
  text "]"
  display repeats'
  text "  "
  plusButton <- button "^" >>=count
  minusButton <- button "v">>=count
  deleteButton <- button' "-" (DeleteMe)
  repeats <- combineDyn (\a b ->(a+1-b)) plusButton minusButton
  repeats' <- forDyn repeats (\k->if k>0 then Rep k else Div (abs (k-2)))
  samples <- forDyn inputVal (words) -- dyn [str]
  samples' <- forDyn samples (Prelude.map (\x->if x=="~" then Blank else Atom x Once)) -- dyn [general Pat]
  genPat <- combineDyn (\list rep-> if list == [] then Group [Blank] Once else Group list rep) samples' repeats'
  forDyn genPat (\k-> (k,deleteButton))


groupWidget'::MonadWidget t m => GeneralPattern String -> Event t () -> m (Dynamic t (GeneralPattern String, Event t GenericSignal))
groupWidget' iVal _ = mdo
  let initialMap = (0::Int)=:(Right ())
  let cEvents = mergeWith (union) [makeSMap,deleteMap]
  (values,events) <- eitherContainer' initialMap cEvents never  never textWidget miscButton -- values:dyn Map k GeneralPattern,
  let deleteKeys = fmap (keys . Data.Map.filter (==DeleteMe)) events --Event [keys]
  let deleteList = fmap (concat . Prelude.map (\k -> [(k,Delete),(k+1,Delete)])) deleteKeys -- Evnt []
  let deleteMap = fmap (fromList) deleteList
  let makeSKeys = fmap (keys . Data.Map.filter (==Ping)) events
  let makeSList = fmap (concat . Prelude.map (\k -> [(k,Insert (Right ())),(k+1,Insert (Left Blank))])) makeSKeys
  let makeSMap = fmap (fromList) makeSList
  values' <- forDyn values (elems)
  returnVal <- forDyn values' (\x-> (Group x Once))
  display returnVal
  returnVal'<-forDyn returnVal (\x->(x,never))
  return returnVal'
  where
    miscButton _ _ = pingButton "+"
    intersperse' x [] = [x]
    intersperse' x xs = [x] ++ (intersperse x xs) ++ [x]

sampleWidget::MonadWidget t m => GeneralPattern Sample-> Event t () -> m (Dynamic t (GeneralPattern Sample,Event t GenericSignal))
sampleWidget (Atom (Sample s) r) _ = do
  let (iName,iN) = s
  text "  Sample:"
  sampleField <-textInput $ def & textInputConfig_attributes .~ constDyn ("style"=:"width:50px;") & textInputConfig_initialValue .~ (show iName)
  let sampleName = _textInput_value sampleField
  nField <-textInput $ def & textInputConfig_attributes .~ constDyn ("style"=:"width:20px;") & textInputConfig_initialValue .~ (show iN) & textInputConfig_inputType .~"number"
  let nVal' = _textInput_value nField
  nVal <- forDyn nVal' (\x-> if isJust (readMaybe x::Maybe Int) then read x::Int else 0)
  sample <- combineDyn (\a b -> Sample (a,b)) sampleName nVal
  plusButton <- button "^" >>=count
  minusButton <- button "v">>=count
  deleteButton <- button' "-" (DeleteMe)
  repeats <- combineDyn (\a b ->(a+1-b)) plusButton minusButton
  repeats' <- forDyn repeats (\k->if k>0 then Rep k else Div (abs (k-2)))
  genPat <- combineDyn (\samp rep-> Atom samp rep) sample repeats'
  forDyn genPat (\k-> (k,deleteButton))
--sampleWidget (Atom (Blank) r) _ =


textWidget'::(MonadWidget t m)=> GeneralPattern SampleName-> Event t () -> m (Dynamic t (GeneralPattern SampleName,Event t GenericSignal))
textWidget' iVal _ = mdo
  (element,result)<-elDynAttr' "div" attrs $ do
    text "Sample:"
    textField <-textInput $ def & textInputConfig_attributes .~ constDyn ("style"=:"width:50px;") & textInputConfig_initialValue .~ (show iVal)
    let inputVal = _textInput_value textField
    plusButton <- button "^" >>=count
    minusButton <- button "v">>=count
    repeats <- combineDyn (\a b ->(a+1-b)) plusButton minusButton
    repeats' <- forDyn repeats (\k->if k>0 then Rep k else Div (abs (k-2)))
    genPat <- combineDyn (\str rep-> if str=="" ||str=="~" then Blank else Atom str rep) inputVal repeats'
    forDyn genPat (\k-> (k,never))
  mouseOver <- wrapDomEvent (_el_element element) (onEventName Mouseover) (mouseXY)
  mouseOut <- wrapDomEvent (_el_element element) (onEventName Mouseout) (mouseXY)
  let mouse = leftmost [mouseOut,mouseOver]
  mouseOverToggle <- toggle False mouse
  attrs <- forDyn mouseOverToggle (\k -> if k then "style"=:"float:left;background-color:lightblue;width:210px" else "style"=:"float:left")
  return result
