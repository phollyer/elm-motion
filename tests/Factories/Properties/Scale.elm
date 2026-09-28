module Factories.Properties.Scale exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale exposing (AxisBounds, Builder)
import Factories.Capabilities exposing (WithBounds, WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initZ : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initXZ : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initYZ : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initXYZ : String -> Float -> Float -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , from : Float -> Builder eng -> Builder eng
    , fromX : Float -> Builder eng -> Builder eng
    , fromY : Float -> Builder eng -> Builder eng
    , fromZ : Float -> Builder eng -> Builder eng
    , fromXY : Float -> Float -> Builder eng -> Builder eng
    , fromXZ : Float -> Float -> Builder eng -> Builder eng
    , fromYZ : Float -> Float -> Builder eng -> Builder eng
    , fromXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
    , toX : Float -> Builder eng -> Builder eng
    , toY : Float -> Builder eng -> Builder eng
    , toZ : Float -> Builder eng -> Builder eng
    , toXY : Float -> Float -> Builder eng -> Builder eng
    , toXZ : Float -> Float -> Builder eng -> Builder eng
    , toYZ : Float -> Float -> Builder eng -> Builder eng
    , toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
    , byX : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byY : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byZ : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byXY : Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byXZ : Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byYZ : Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byXYZ : Float -> Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing -> Builder eng -> Builder eng
    , spring : Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , bounds : String -> AxisBounds -> AnimBuilder (WithBounds eng) -> AnimBuilder (WithBounds eng)
    , clampX : Float -> Float -> Builder eng -> Builder eng
    , clampY : Float -> Float -> Builder eng -> Builder eng
    , clampZ : Float -> Float -> Builder eng -> Builder eng
    , unclampX : Builder eng -> Builder eng
    , unclampY : Builder eng -> Builder eng
    , unclampZ : Builder eng -> Builder eng
    , set : Float -> Builder eng -> Builder eng
    , setX : Float -> Builder eng -> Builder eng
    , setY : Float -> Builder eng -> Builder eng
    , setZ : Float -> Builder eng -> Builder eng
    , setXY : Float -> Float -> Builder eng -> Builder eng
    , setXZ : Float -> Float -> Builder eng -> Builder eng
    , setYZ : Float -> Float -> Builder eng -> Builder eng
    , setXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { initX = Scale.initX
    , initY = Scale.initY
    , initZ = Scale.initZ
    , initXY = Scale.initXY
    , initXZ = Scale.initXZ
    , initYZ = Scale.initYZ
    , initXYZ = Scale.initXYZ
    , begin = Scale.begin
    , end = Scale.end
    , from = Scale.from
    , fromX = Scale.fromX
    , fromY = Scale.fromY
    , fromZ = Scale.fromZ
    , fromXY = Scale.fromXY
    , fromXZ = Scale.fromXZ
    , fromYZ = Scale.fromYZ
    , fromXYZ = Scale.fromXYZ
    , toX = Scale.toX
    , toY = Scale.toY
    , toZ = Scale.toZ
    , toXY = Scale.toXY
    , toXZ = Scale.toXZ
    , toYZ = Scale.toYZ
    , toXYZ = Scale.toXYZ
    , byX = Scale.byX
    , byY = Scale.byY
    , byZ = Scale.byZ
    , byXY = Scale.byXY
    , byXZ = Scale.byXZ
    , byYZ = Scale.byYZ
    , byXYZ = Scale.byXYZ
    , delay = Scale.delay
    , duration = Scale.duration
    , speed = Scale.speed
    , easing = Scale.easing
    , spring = Scale.spring
    , bounds = Scale.bounds
    , clampX = Scale.clampX
    , clampY = Scale.clampY
    , clampZ = Scale.clampZ
    , unclampX = Scale.unclampX
    , unclampY = Scale.unclampY
    , unclampZ = Scale.unclampZ
    , set = Scale.set
    , setX = Scale.setX
    , setY = Scale.setY
    , setZ = Scale.setZ
    , setXY = Scale.setXY
    , setXZ = Scale.setXZ
    , setYZ = Scale.setYZ
    , setXYZ = Scale.setXYZ
    }
