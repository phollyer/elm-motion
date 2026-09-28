module Factories.Properties.Translate exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate exposing (AxisBounds, Builder)
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithBounds, WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { initX : String -> Float -> animBuilder -> animBuilder
    , initY : String -> Float -> animBuilder -> animBuilder
    , initZ : String -> Float -> animBuilder -> animBuilder
    , initXY : String -> Float -> Float -> animBuilder -> animBuilder
    , initXZ : String -> Float -> Float -> animBuilder -> animBuilder
    , initYZ : String -> Float -> Float -> animBuilder -> animBuilder
    , initXYZ : String -> Float -> Float -> Float -> animBuilder -> animBuilder
    , begin : animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
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
    , initCssUnit : Unit -> animBuilder -> animBuilder
    , initCssUnitX : Unit -> animBuilder -> animBuilder
    , initCssUnitY : Unit -> animBuilder -> animBuilder
    , initCssUnitZ : Unit -> animBuilder -> animBuilder
    , cssUnit : Unit -> Builder eng -> Builder eng
    , cssUnitX : Unit -> Builder eng -> Builder eng
    , cssUnitY : Unit -> Builder eng -> Builder eng
    , cssUnitZ : Unit -> Builder eng -> Builder eng
    , bounds : String -> AxisBounds -> AnimBuilder (WithBounds eng) -> AnimBuilder (WithBounds eng)
    , clampX : Float -> Float -> Builder eng -> Builder eng
    , clampY : Float -> Float -> Builder eng -> Builder eng
    , clampZ : Float -> Float -> Builder eng -> Builder eng
    , unclampX : Builder eng -> Builder eng
    , unclampY : Builder eng -> Builder eng
    , unclampZ : Builder eng -> Builder eng
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
    { initX = Translate.initX
    , initY = Translate.initY
    , initZ = Translate.initZ
    , initXY = Translate.initXY
    , initXZ = Translate.initXZ
    , initYZ = Translate.initYZ
    , initXYZ = Translate.initXYZ
    , begin = Translate.begin
    , end = Translate.end
    , fromX = Translate.fromX
    , fromY = Translate.fromY
    , fromZ = Translate.fromZ
    , fromXY = Translate.fromXY
    , fromXZ = Translate.fromXZ
    , fromYZ = Translate.fromYZ
    , fromXYZ = Translate.fromXYZ
    , toX = Translate.toX
    , toY = Translate.toY
    , toZ = Translate.toZ
    , toXY = Translate.toXY
    , toXZ = Translate.toXZ
    , toYZ = Translate.toYZ
    , toXYZ = Translate.toXYZ
    , byX = Translate.byX
    , byY = Translate.byY
    , byZ = Translate.byZ
    , byXY = Translate.byXY
    , byXZ = Translate.byXZ
    , byYZ = Translate.byYZ
    , byXYZ = Translate.byXYZ
    , delay = Translate.delay
    , duration = Translate.duration
    , speed = Translate.speed
    , easing = Translate.easing
    , spring = Translate.spring
    , initCssUnit = Translate.initCssUnit
    , initCssUnitX = Translate.initCssUnitX
    , initCssUnitY = Translate.initCssUnitY
    , initCssUnitZ = Translate.initCssUnitZ
    , cssUnit = Translate.cssUnit
    , cssUnitX = Translate.cssUnitX
    , cssUnitY = Translate.cssUnitY
    , cssUnitZ = Translate.cssUnitZ
    , bounds = Translate.bounds
    , clampX = Translate.clampX
    , clampY = Translate.clampY
    , clampZ = Translate.clampZ
    , unclampX = Translate.unclampX
    , unclampY = Translate.unclampY
    , unclampZ = Translate.unclampZ
    , setX = Translate.setX
    , setY = Translate.setY
    , setZ = Translate.setZ
    , setXY = Translate.setXY
    , setXZ = Translate.setXZ
    , setYZ = Translate.setYZ
    , setXYZ = Translate.setXYZ
    }
