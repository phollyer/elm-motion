module Factories.Properties.Rotate exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate exposing (Builder)
import Factories.Capabilities exposing (WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing(..))
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
    , fromX : Float -> (Builder eng -> Builder eng)
    , fromY : Float -> (Builder eng -> Builder eng)
    , fromZ : Float -> (Builder eng -> Builder eng)
    , fromXY : Float -> Float -> (Builder eng -> Builder eng)
    , fromXZ : Float -> Float -> (Builder eng -> Builder eng)
    , fromYZ : Float -> Float -> (Builder eng -> Builder eng)
    , fromXYZ : Float -> Float -> Float -> (Builder eng -> Builder eng)
    , toX : Float -> (Builder eng -> Builder eng)
    , toY : Float -> (Builder eng -> Builder eng)
    , toZ : Float -> (Builder eng -> Builder eng)
    , toXY : Float -> Float -> (Builder eng -> Builder eng)
    , toXZ : Float -> Float -> (Builder eng -> Builder eng)
    , toYZ : Float -> Float -> (Builder eng -> Builder eng)
    , toXYZ : Float -> Float -> Float -> (Builder eng -> Builder eng)
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
    { initX = Rotate.initX
    , initY = Rotate.initY
    , initZ = Rotate.initZ
    , initXY = Rotate.initXY
    , initXZ = Rotate.initXZ
    , initYZ = Rotate.initYZ
    , initXYZ = Rotate.initXYZ
    , begin = Rotate.begin
    , end = Rotate.end
    , fromX = Rotate.fromX
    , fromY = Rotate.fromY
    , fromZ = Rotate.fromZ
    , fromXY = Rotate.fromXY
    , fromXZ = Rotate.fromXZ
    , fromYZ = Rotate.fromYZ
    , fromXYZ = Rotate.fromXYZ
    , toX = Rotate.toX
    , toY = Rotate.toY
    , toZ = Rotate.toZ
    , toXY = Rotate.toXY
    , toXZ = Rotate.toXZ
    , toYZ = Rotate.toYZ
    , toXYZ = Rotate.toXYZ
    , byX = Rotate.byX
    , byY = Rotate.byY
    , byZ = Rotate.byZ
    , byXY = Rotate.byXY
    , byXZ = Rotate.byXZ
    , byYZ = Rotate.byYZ
    , byXYZ = Rotate.byXYZ
    , delay = Rotate.delay
    , duration = Rotate.duration
    , speed = Rotate.speed
    , easing = Rotate.easing
    , spring = Rotate.spring
    , clampX = Rotate.clampX
    , clampY = Rotate.clampY
    , clampZ = Rotate.clampZ
    , unclampX = Rotate.unclampX
    , unclampY = Rotate.unclampY
    , unclampZ = Rotate.unclampZ
    , set = Rotate.set
    , setX = Rotate.setX
    , setY = Rotate.setY
    , setZ = Rotate.setZ
    , setXY = Rotate.setXY
    , setXZ = Rotate.setXZ
    , setYZ = Rotate.setYZ
    , setXYZ = Rotate.setXYZ
    }
