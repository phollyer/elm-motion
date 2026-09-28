module Factories.Properties.Skew exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew exposing (Builder)
import Factories.Capabilities exposing (WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , fromX : Float -> Builder eng -> Builder eng
    , fromY : Float -> Builder eng -> Builder eng
    , fromXY : Float -> Float -> Builder eng -> Builder eng
    , toX : Float -> Builder eng -> Builder eng
    , toY : Float -> Builder eng -> Builder eng
    , toXY : Float -> Float -> Builder eng -> Builder eng
    , byX : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byY : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byXY : Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , spring : Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , clampX : Float -> Float -> Builder eng -> Builder eng
    , clampY : Float -> Float -> Builder eng -> Builder eng
    , unclampX : Builder eng -> Builder eng
    , unclampY : Builder eng -> Builder eng
    , setX : Float -> Builder eng -> Builder eng
    , setY : Float -> Builder eng -> Builder eng
    , setXY : Float -> Float -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    , begin = Skew.begin
    , end = Skew.end
    , fromX = Skew.fromX
    , fromY = Skew.fromY
    , fromXY = Skew.fromXY
    , toX = Skew.toX
    , toY = Skew.toY
    , toXY = Skew.toXY
    , byX = Skew.byX
    , byY = Skew.byY
    , byXY = Skew.byXY
    , delay = Skew.delay
    , duration = Skew.duration
    , speed = Skew.speed
    , easing = Skew.easing
    , spring = Skew.spring
    , clampX = Skew.clampX
    , clampY = Skew.clampY
    , unclampX = Skew.unclampX
    , unclampY = Skew.unclampY
    , setX = Skew.setX
    , setY = Skew.setY
    , setXY = Skew.setXY
    }
