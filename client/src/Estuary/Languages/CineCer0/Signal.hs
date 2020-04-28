{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

module Estuary.Languages.CineCer0.Signal where

import Data.Time
import Estuary.Types.Tempo


 --              Tempo    Video Length      render T   eval T    anchor t
type Signal a = Tempo -> NominalDiffTime -> UTCTime -> UTCTime -> UTCTime -> a

-- anchor in signal and not in videoSpec.
-- opacity (ramp 0 1 3) $ "myMov.mp4"

instance Num a => Num (Signal a) where
    x + y = \t dur renderTime evalTime anchTime -> (x t dur renderTime evalTime anchTime) + (y t dur renderTime evalTime anchTime)
    x * y = \t dur renderTime evalTime anchTime -> (x t dur renderTime evalTime anchTime) * (y t dur renderTime evalTime anchTime)
    negate x = \t dur renderTime evalTime anchTime -> negate (x t dur renderTime evalTime anchTime)
    abs x = \t dur renderTime evalTime anchTime -> abs (x t dur renderTime evalTime anchTime)
    signum x = \t dur renderTime evalTime anchTime -> signum (x t dur renderTime evalTime anchTime)
    fromInteger x = \t dur renderTime evalTime anchTime -> fromInteger x

multipleMaybeSignal :: Num a => Signal (Maybe a) -> Signal (Maybe a) -> Signal (Maybe a)
multiplyMaybeSignal x y = \a b c d -> multiplyMaybe (x a b c d) (y a b c d)

multiplyMaybe :: Num a => Maybe a -> Maybe a -> Maybe a
multiplyMaybe Nothing Nothing = Nothing
multiplyMaybe (Just x) Nothing = Just x
multiplyMaybe Nothing (Just x) = Just x
multiplyMaybe (Just x) (Just y) = Just (x*y)

------ functions that generate signals

constantSignal :: a -> Signal a
constantSignal x = \_ _ _ _ _ -> x


-- Two cases that should work:
-- opacity (ramp 0 1 3) $ "myMov.mp4" -- implicit quant 

-- opacity (ramp 0 1 3) $ quant 2 0.5 $ "myMov.mp4" 

defaultAnchor:: Tempo -> UTCTime -> UTCTime
defaultAnchor t eval = quantAnchor 1 0 t eval

quant:: Rational -> Rational -> Signal UTCTime -- parser "quant"
quant cycleMult offset t vl rT eT aT = quantAnchor cycleMult offset t eT

-- calculates the anchorTime 
quantAnchor:: Rational -> Rational -> Tempo -> UTCTime -> UTCTime
quantAnchor cycleMult offset t eval = 
  let ec = timeToCount t eval 
      currentCycle = fromIntegral (floor ec):: Rational
      align = if ec - currentCycle > 0.95 then 2 else 1 -- align with minimal evalTime / cognitionResponse interval (right now hardcoded to 0.95 of the cycle, I will provide something better if this works)
      toQuant = currentCycle + align -- as integer to go through the quantomatic
      quanted = quantomatic cycleMult toQuant 
      anchor = cycsToSecs t quanted -- into seconds (as NDT)
      -- offset should be in percentage of cycle!
      off = realToFrac $ (offset*(1/(freq t))) / 1
    in addUTCTime (anchor + off) $ time t -- as UTCTime

cycsToSecs:: Tempo -> Rational -> NominalDiffTime
cycsToSecs t x = realToFrac (x * (1/ freq t))

-- this function gets the next bar that aligns with the quant multiplier value
quantomatic:: Rational -> Rational -> Rational
quantomatic cycleMult nextBeat = 
  let quanted = if remIsZero nextBeat cycleMult then nextBeat else quantomatic cycleMult (nextBeat + 1)
  in quanted

  -- substitutes mod operation for one that would detect the remainder of a division when it is 0
remIsZero:: Rational -> Rational -> Bool
remIsZero nextBeat cycleMultiplier = 
  let divi = nextBeat / cycleMultiplier
      floored = realToFrac (floor divi) :: Rational
      remainder = divi - floored
  in if remainder == 0 then True else False 

-- Temporal Functions

------ Manually apply a rate into a video ------

-- backdoor function to manually change the rate of a video, 
-- if this func is used with any of the time funcs (that change rate and position) will override one of the two,
-- producing inconsistencies

applyRate:: Rational -> Signal (Maybe Rational)
applyRate rate t length render eval anchor = Just rate


------ Play at Natural Rate and without alteration ------

--playNatural _Pos and _Rate will play de video in its pregiven rate and the 0:00" position
-- of the video will align with the cycle 0 beat 0 of Estuary's clock (Tempo).
-- This function does not align in any way with the cycle and beat count of the Tempo
-- it has only one argument (that can also be found in every time function): shift, 
-- shift changes the start value of the video: 0.5 shift in a 12 secs video will align the 0 of the tempo
-- with the video at its 50% (6:00 secs)


playNatural_Pos:: Rational -> Signal (Maybe NominalDiffTime)
playNatural_Pos sh t vl render eval anchor =
    let vLen = realToFrac vl :: Rational
        cpDur = 1/(freq t)
        off = sh*cpDur
        difb0 = realToFrac (diffUTCTime render (origin t)) :: Rational
        difb0' = difb0 - off
        lengths = difb0' / vLen
        posNorm = lengths - fromIntegral (floor lengths) :: Rational
        result = reglaDeTres 1 posNorm vLen
    in Just (realToFrac result)

playNatural_Rate :: Rational-> Signal (Maybe Rational)
playNatural_Rate sh t vl render eval anchor = Just 1

------ Makes a video shorter or longer acording to given # of cycles ------

-- this fucntion aligns the position and stretches (or collapses) the video length 
--according to a given number of cycles. If a 3 is passed as the cycle argument,
-- the video provided is 12 secs long and the cycles of the Tempo last 2.5 secs, the function
-- will transform the video so it total duration is now 7.5 (the duration of 3 cycles) and its 0:00" mark
-- will align with the begining of a cycle.
-- the args for this func are cycle and shift

-- gets the onset time of the video in playEvery
playEvery_Pos:: Rational -> Rational -> Signal (Maybe NominalDiffTime)
playEvery_Pos c sh t vl render eval anchor =
    let n = c
        ec = (timeToCount t render)
        ecOf = ec - sh
        floored = floor (ecOf/n)
        nlb = (fromIntegral floored :: Rational)*n
        pos= (realToFrac vl) * ((ecOf-nlb)/n)
    in Just (realToFrac pos)

-- gets the rate time for the video in playEvery

playEvery_Rate:: Rational -> Rational -> Signal (Maybe Rational)
playEvery_Rate c sh t vl render eval anchor =
    let vLen = realToFrac vl :: Rational
        n = c
        freq' = freq t
        rate = vLen/(n/freq')
    in Just (realToFrac rate)

------ Rounds the duration of video to the nearest cycle ------

-- round _Rate and _Pos will modify the rate of a video to fit its length to the closest number of cycles,
-- if the video's length is 12 secs and the cycles last 2.5 secs the video will be fitted to 12.5 secs, 
-- in this way the video will be as close to its original length but will be aligned to the Tempo of Estuary
-- In this example, 5 cycles will hold the whole video.
-- this functions only accept from the player one argument: shift

playRound_Pos:: Rational -> Signal (Maybe NominalDiffTime)
playRound_Pos sh t vlen render eval anchor =
    let vl = realToFrac vlen :: Rational
        cps = (freq t)
        cpDur = 1/cps -- reciprocal of cps is duration in secs
        off = sh*cpDur
        cPerLen = vl/cpDur -- how many cycles for 1 whole video
        newLVinCPS = fromIntegral (round cPerLen) :: Rational -- this is new length
        inSecs = newLVinCPS *cpDur 
        difb0 = realToFrac (diffUTCTime render (origin t)) :: Rational
        difb0' = difb0 - off
        lengths = difb0' / inSecs
        posNorm = lengths - fromIntegral (floor lengths) :: Rational
        result = reglaDeTres 1 posNorm inSecs
    in Just (realToFrac  result) --transforms this into seconds

playRound_Rate:: Rational -> Signal (Maybe Rational)
playRound_Rate sh t vlen render eval anchor =
    let vl = realToFrac vlen :: Rational
        cps = (freq t)
        cpDur = 1/cps
        cPerLen = vl/cpDur
        floored = fromIntegral (floor cPerLen) :: Rational -- new length in cycles
        newVl = floored / cps -- new length in seconds
        rate = vl / newVl
    in Just rate


------------ playRoundMetre ------------

-- Similar to the above but it fits the length of the video to a power of 2 number of cycles so it can adapt
-- to common music understandings of period, phrase and subdivision. For example, if a video is 12 secs long 
-- and each cycle is 2.5 secs long, this functions will change the rate so the video fits in four cycles (10 secs)
-- this functions only accept from the player one argument: shift

------------ playRoundMetre ------------

-- Similar to the above but it fits the length of the video to a power of 2 number of cycles so it can adapt
-- to common music understandings of period, phrase and subdivision. For example, if a video is 12 secs long 
-- and each cycle is 2.5 secs long, this functions will change the rate so the video fits in four cycles (10 secs)
-- this functions only accept from the player one argument: shift

---- round the duration of the video to a power of 2 so it can align with the notion of metre
playRoundMetre_Pos:: Rational -> Signal (Maybe NominalDiffTime)
playRoundMetre_Pos sh t vlen render eval anchor =
    let vl = realToFrac vlen :: Rational
        cpDur = realToFrac (1/(freq t)) :: Rational --- cps expresado en duracion if 0.5 cps then 2 segundos (SEGUNDOS, NO ciclos!!)
        off = sh*cpDur
        cPerLen = vl/cpDur -- how many cycles for 1 whole video || if length is 28 secs and the cpDur is 2 = 14 (ciclos!!!!!!)
        newVLinCPS = stretchToMetre cPerLen     -- outputs de cycles that will be the new dur of the video (16 ciclos)
        inSecs = newVLinCPS *cpDur -- express the new video duration in secs rather than cycles 16*2 = 32
        difb0 = realToFrac (diffUTCTime render (origin t)) :: Rational -- the amount of time passed between render time and beatZero
        difb0' = difb0 - off
        lengths = difb0' / inSecs -- if dif 30 secs and inSecs is 16 then = 1.875. 1.875 ciclos han transcurrido
        posNorm = lengths - fromIntegral (floor lengths) :: Rational -- 0.875, this is the percentage of the duration of a cycle
        result = reglaDeTres 1 posNorm inSecs -- 100 % 87.5 % 
    in Just (realToFrac  result) --transforms this into seconds

playRoundMetre_Rate:: Rational -> Signal (Maybe Rational)
playRoundMetre_Rate sh t vlen render eval anchor =
    let vl = realToFrac vlen :: Rational
        cpDur = realToFrac (1/(freq t)) :: Rational
        off = (realToFrac sh :: Rational) *cpDur
        cPerLen = vl/cpDur -- how many cycles for 1 whole video
        newVLinCPS = stretchToMetre cPerLen
        newVLinSecs = newVLinCPS * cpDur
        rate = realToFrac vl / newVLinSecs
    in Just (realToFrac rate)


stretchToMetre:: Rational -> Rational
stretchToMetre cPlen =
    let ceilFloor =  getCeilFloor [0.125/16] cPlen
        ceil = last ceilFloor
        floor = last $ init ceilFloor
    in if (cPlen - floor) < (ceil - cPlen) then floor else ceil

getCeilFloor:: [Rational] -> Rational -> [Rational]
getCeilFloor [] _ = []
getCeilFloor n ln
        | last n < ln =
            let result = (last n)*2
            in result : getCeilFloor (n++[result]) ln
        | last n < ln = n
        | otherwise = []

------ Chop the video for any given cycles with normal rate ------

-- playChop _Pos' and _Rate' will take a startPosition normalised from 0 to 1 
-- (in which 100% is whole length) and an amount of cycles. The video will reproduce a
-- clip from the starting position forwards until it covers the cycles indicated.
-- For example, if a video lasts 12 secs and we pass a 0.5 of startPos and 2 cycles 
-- (with a tempo of 2.5 secs per cycle), we will align the 0:5" mark with the begining
-- of a cycle and it will keep going for 5 secs (until the video reaches 0:10") before it starts again
-- this function accepts from the player three args: startPos, cycles and shift

-- gets the interval of the video reproduced with an offset time and
-- a length in cycles, OJO the startPos is normalised from 0 to 1.
playChop_Pos':: Rational -> Rational -> Rational -> Signal (Maybe NominalDiffTime)
playChop_Pos' startPos cycles sh t vlen render eval anchor =
    let vl = realToFrac vlen :: Rational
        cd = cycles
        sP = reglaDeTres 1 startPos vl
        cp = (freq t)
        cpDur = 1/cp
        off = sh*cpDur
        cInSecs= cd * cpDur
        difb0 = realToFrac (diffUTCTime render (origin t)) :: Rational
        difb0' = difb0 - off
        lengths = difb0' / cInSecs
        posNorm = lengths - fromIntegral (floor lengths) :: Rational
        pos = reglaDeTres 1 posNorm cInSecs
    in Just (realToFrac (sP + pos))


              -- StartPos ->  Cycles ->  Shift    -> Tempo -> VideoLength ->         Now -> Rate
playChop_Rate':: Rational -> Rational -> Rational -> Signal (Maybe Rational)
playChop_Rate' startPos cycles sh t vlen render eval anchor = Just 1


------------- Gives a chop start and end position and adjust the rate to any given cycles ------
-------- the UBER chop ---------

-- Similar to the one above but it takes a start and an end position, bot normalised from 0 to 1

playChop_Pos:: Rational -> Rational -> Rational -> Rational -> Signal (Maybe NominalDiffTime)
playChop_Pos startPos endPos cycles sh t vlen render eval anchor =
    let cp = (freq t)
        cpsDur = 1/cp
        vl = realToFrac vlen :: Rational
        start = reglaDeTres 1 startPos vl
        end = reglaDeTres 1 endPos vl
        interval = end - start
        intCyc = interval / cpsDur
        rounded = fromIntegral (round intCyc) :: Rational
        inSecs = rounded * cpsDur
        ec = (timeToCount t render)
        ecOff = ec - sh
        ecFloored = fromIntegral (floor ecOff) :: Rational
        ecRender = ecOff - ecFloored
        pos = reglaDeTres 1 ecRender interval
        pos' = start + pos
    in Just (realToFrac pos')


playChop_Rate:: Rational -> Rational -> Rational -> Rational -> Signal (Maybe Rational)
playChop_Rate startPos endPos cycles sh t vlen render eval anchor
    | startPos == endPos = Just 0
    | otherwise =
    let cps = (freq t)
        cpsDur = 1/cps
        vl = realToFrac vlen :: Rational
        start = reglaDeTres 1 startPos vl
        end = reglaDeTres 1 endPos vl
        interval = end - start
        cPerLen = interval/cpsDur
        rounded = fromIntegral (round cPerLen) :: Rational -- new length in cycles
        newVl = rounded / cps -- new length in seconds
        rate = interval / newVl
        addNeg = if start > end then rate * (-1) else rate
    in  Just (realToFrac addNeg)

-------- the UBER chop with start and end position in seconds instead of 0 to 1 ---------

-- Similar to the one above but the start and end position are not percentages, but seconds

playChopSecs_Pos:: NominalDiffTime -> NominalDiffTime -> Rational -> Rational -> Signal (Maybe NominalDiffTime)
playChopSecs_Pos startPos endPos cycles sh t vlen render eval anchor =
    let cps = (freq t)
        cpsDur = 1/cps
        vl = realToFrac vlen :: Rational
        start = cycleSecs startPos vlen
        end = cycleSecs endPos vlen
        interval = end - start
        intCyc = interval / cpsDur
        rounded = fromIntegral (round intCyc) :: Rational
        inSecs = rounded * cpsDur
        ec = (timeToCount t render)
        ecOff = ec - sh
        ecFloored = fromIntegral (floor ecOff) :: Rational
        ecRender = ecOff - ecFloored
        pos = reglaDeTres 1 ecRender interval
        pos' = start + pos
    in Just (realToFrac pos')


playChopSecs_Rate:: NominalDiffTime -> NominalDiffTime -> Rational -> Rational -> Signal (Maybe Rational)
playChopSecs_Rate startPos endPos cycles sh t vlen render eval anchor
    | startPos == endPos = Just 0
    | otherwise =
    let cps = (freq t)
        cpsDur = 1/cps
        vl = realToFrac vlen :: Rational
        start = cycleSecs startPos vlen
        end = cycleSecs startPos vlen
        interval = end - start
        cPerLen = interval/cpsDur
        rounded = fromIntegral (round cPerLen) :: Rational -- new length in cycles
        newVl = rounded / cps -- new length in seconds
        rate = interval / newVl
        addNeg = if start > end then rate * (-1) else rate
    in  Just (realToFrac addNeg)

------- playNow  -- Starts the video with the evaluation time

-- this function is useless :D
-- giving a start position in seconds

           --  startPos        -- rate
playNow_Pos:: NominalDiffTime -> Rational -> Signal (Maybe NominalDiffTime)
playNow_Pos startPos rate t vlen render eval anchor = Just $ (realToFrac (cycleSecs startPos vlen))

playNow_Rate:: NominalDiffTime -> Rational -> Signal (Maybe Rational)
playNow_Rate startPos rate t vlen render eval anchor = Just rate

-- Geometry




-- Image


---- Opacity

-- sets a default opacity for new videos --
-- defaultOpacity :: Signal Rational
-- defaultOpacity = \_ _ _ _ -> 100

------ Manually changes the opacity of a video ------

opacityChanger:: Rational -> Signal Rational
opacityChanger arg t len rend eval anchor = arg


-- Dynamic Functions
-- durVal is the amount of time the process takes place

ramp :: NominalDiffTime -> Rational -> Rational -> Signal Rational
ramp durVal startVal endVal = \t vl renderTime evalTime anchorTime ->
  let startTime = anchorTime :: UTCTime -- place holder, add quant later
      endTime = addUTCTime durVal anchorTime
  in ramp' renderTime startTime endTime startVal endVal

-- Ramper with new features !!! ------ Creates a ramp given the rendering time (now)
ramp':: UTCTime -> UTCTime -> UTCTime -> Rational -> Rational -> Rational
ramp' renderTime startTime endTime startVal endVal -- delete what is not needed
    | startTime >= renderTime = startVal 
    | endTime <= renderTime = endVal
    | otherwise =    -- args: 3 secs of dur, startval: 0.2, endval: 0.7
        let segmentVal = endVal - startVal -- 0.5 
            processInterval = realTofrac (diffUTCTime endTime startTime) :: Rational --  3 segs
            momentAtRender = realToFrac (diffUTCTime renderTime startTime) :: Rational -- assuming render is half way through the process: 1.5 out of 3.0
            percOfProcessAtRender = getPercentage momentAtRender processInterval segmentVal
        in startVal + percOfProcessAtRender


--------- Helper Functions ------------

-- gets percentage and modulates the result to a new scale. Example:
-- value: 10 scale: 50 new scale: 1 -> 0.2  (10 is 20% of 50, 20% of 1 is 0.2)
getPercentage:: Rational -> Rational -> Rational -> Rational
getPercentage value scale newScale = (value/scale) * newScale

reglaDeTres:: Rational -> Rational -> Rational -> Rational
reglaDeTres normScale normPos realScale = (normPos*realScale) / normScale

    --   startorendPos           vidLength
cycleSecs:: NominalDiffTime -> NominalDiffTime -> Rational
cycleSecs startPos vlen
    | startPos < vlen = (realToFrac vlen :: Rational) - (realToFrac startPos :: Rational)
    | otherwise =
    let sp = realToFrac startPos :: Rational
        vl = realToFrac vlen :: Rational
        x = sp / vl
        floored = fromIntegral (floor x) :: Rational
        rest = vl * floored
        cycle = sp - rest
    in cycle

chronoIncrease:: UTCTime -> UTCTime -> UTCTime
chronoHorizon first second = 
  let diff = diffUTCTime second first
      increase = if signum diff == 1 then first else second
  in increase

chronoDecrease:: UTCTime -> UTCTime -> UTCTime
chronoDecrease first second = 
  let diff = diffUTCTime second first
      decrease = if signum diff == (-1) then first else second
  in decrease



-- test functions

today = fromGregorian 2019 07 18

myUTCTest = UTCTime today 30

myUTCTest2 = UTCTime today 60

myTempo = Tempo { freq= 0.5, time= myUTCTest, count= 10.3}

-- test functions for ramps

startPoint = UTCTime today 30

endPoint = UTCTime today 40

renderTime = UTCTime today 34.5
