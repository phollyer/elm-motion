module Factories.Properties.PerspectiveOrigin exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin exposing (AxisBounds, Builder)
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithBounds, WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , from : Float -> Builder eng -> Builder eng
    , fromXY : Float -> Float -> Builder eng -> Builder eng
    , fromX : Float -> Builder eng -> Builder eng
    , fromY : Float -> Builder eng -> Builder eng
    , to : Float -> Builder eng -> Builder eng
    , toXY : Float -> Float -> Builder eng -> Builder eng
    , toX : Float -> Builder eng -> Builder eng
    , toY : Float -> Builder eng -> Builder eng
    , by : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byXY : Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byX : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byY : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing -> Builder eng -> Builder eng
    , spring : Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , initCssUnitX : Unit -> (animBuilder -> animBuilder)
    , initCssUnitY : Unit -> (animBuilder -> animBuilder)
    , initCssUnit : Unit -> (animBuilder -> animBuilder)
    , cssUnit : Unit -> Builder eng -> Builder eng
    , cssUnitX : Unit -> Builder eng -> Builder eng
    , cssUnitY : Unit -> Builder eng -> Builder eng
    , bounds : String -> AxisBounds -> AnimBuilder (WithBounds eng) -> AnimBuilder (WithBounds eng)
    , clampX : Float -> Float -> Builder eng -> Builder eng
    , clampY : Float -> Float -> Builder eng -> Builder eng
    , unclampX : Builder eng -> Builder eng
    , unclampY : Builder eng -> Builder eng
    , set : Float -> Builder eng -> Builder eng
    , setXY : Float -> Float -> Builder eng -> Builder eng
    , setX : Float -> Builder eng -> Builder eng
    , setY : Float -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { initX = PerspectiveOrigin.initX
    , initY = PerspectiveOrigin.initY
    , initXY = PerspectiveOrigin.initXY
    , begin = PerspectiveOrigin.begin
    , end = PerspectiveOrigin.end
    , from = PerspectiveOrigin.from
    , fromXY = PerspectiveOrigin.fromXY
    , fromX = PerspectiveOrigin.fromX
    , fromY = PerspectiveOrigin.fromY
    , to = PerspectiveOrigin.to
    , toXY = PerspectiveOrigin.toXY
    , toX = PerspectiveOrigin.toX
    , toY = PerspectiveOrigin.toY
    , by = PerspectiveOrigin.by
    , byXY = PerspectiveOrigin.byXY
    , byX = PerspectiveOrigin.byX
    , byY = PerspectiveOrigin.byY
    , delay = PerspectiveOrigin.delay
    , duration = PerspectiveOrigin.duration
    , speed = PerspectiveOrigin.speed
    , easing = PerspectiveOrigin.easing
    , spring = PerspectiveOrigin.spring
    , initCssUnitX = PerspectiveOrigin.initCssUnitX
    , initCssUnitY = PerspectiveOrigin.initCssUnitY
    , initCssUnit = PerspectiveOrigin.initCssUnit
    , cssUnit = PerspectiveOrigin.cssUnit
    , cssUnitX = PerspectiveOrigin.cssUnitX
    , cssUnitY = PerspectiveOrigin.cssUnitY
    , bounds = PerspectiveOrigin.bounds
    , clampX = PerspectiveOrigin.clampX
    , clampY = PerspectiveOrigin.clampY
    , unclampX = PerspectiveOrigin.unclampX
    , unclampY = PerspectiveOrigin.unclampY
    , set = PerspectiveOrigin.set
    , setX = PerspectiveOrigin.setX
    , setY = PerspectiveOrigin.setY
    , setXY = PerspectiveOrigin.setXY
    }
