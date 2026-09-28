module Factories.Properties.Size exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size exposing (AxisBounds, Builder)
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithBounds, WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { initH : String -> Float -> (animBuilder -> animBuilder)
    , initW : String -> Float -> (animBuilder -> animBuilder)
    , initHW : String -> Float -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , fromH : Float -> Builder eng -> Builder eng
    , fromW : Float -> Builder eng -> Builder eng
    , fromHW : Float -> Float -> Builder eng -> Builder eng
    , toH : Float -> Builder eng -> Builder eng
    , toW : Float -> Builder eng -> Builder eng
    , toHW : Float -> Float -> Builder eng -> Builder eng
    , byH : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byW : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , byHW : Float -> Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing -> Builder eng -> Builder eng
    , spring : Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , initCssUnitH : Unit -> animBuilder -> animBuilder
    , initCssUnitW : Unit -> animBuilder -> animBuilder
    , initCssUnit : Unit -> animBuilder -> animBuilder
    , cssUnit : Unit -> Builder eng -> Builder eng
    , cssUnitH : Unit -> Builder eng -> Builder eng
    , cssUnitW : Unit -> Builder eng -> Builder eng
    , bounds : String -> AxisBounds -> AnimBuilder (WithBounds eng) -> AnimBuilder (WithBounds eng)
    , clampWidth : Float -> Float -> Builder eng -> Builder eng
    , clampHeight : Float -> Float -> Builder eng -> Builder eng
    , unclampWidth : Builder eng -> Builder eng
    , unclampHeight : Builder eng -> Builder eng
    , set : Float -> Builder eng -> Builder eng
    , setHW : Float -> Float -> Builder eng -> Builder eng
    , setH : Float -> Builder eng -> Builder eng
    , setW : Float -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { initH = Size.initH
    , initW = Size.initW
    , initHW = Size.initHW
    , begin = Size.begin
    , end = Size.end
    , fromH = Size.fromH
    , fromW = Size.fromW
    , fromHW = Size.fromHW
    , toH = Size.toH
    , toW = Size.toW
    , toHW = Size.toHW
    , byH = Size.byH
    , byW = Size.byW
    , byHW = Size.byHW
    , delay = Size.delay
    , duration = Size.duration
    , speed = Size.speed
    , easing = Size.easing
    , spring = Size.spring
    , initCssUnitH = Size.initCssUnitH
    , initCssUnitW = Size.initCssUnitW
    , initCssUnit = Size.initCssUnit
    , cssUnit = Size.cssUnit
    , cssUnitH = Size.cssUnitH
    , cssUnitW = Size.cssUnitW
    , bounds = Size.bounds
    , clampWidth = Size.clampWidth
    , clampHeight = Size.clampHeight
    , unclampWidth = Size.unclampWidth
    , unclampHeight = Size.unclampHeight
    , set = Size.set
    , setHW = Size.setHW
    , setH = Size.setH
    , setW = Size.setW
    }
