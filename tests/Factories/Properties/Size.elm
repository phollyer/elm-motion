module Factories.Properties.Size exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Anim.Unit exposing (Unit(..))


type alias Factory animBuilder builder =
    { initH : String -> Float -> (animBuilder -> animBuilder)
    , initW : String -> Float -> (animBuilder -> animBuilder)
    , initHW : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initCssUnitH : Unit -> (animBuilder -> animBuilder)
    , initCssUnitW : Unit -> (animBuilder -> animBuilder)
    , initCssUnit : Unit -> (animBuilder -> animBuilder)
    , begin : animBuilder -> builder
    , end : builder -> animBuilder
    }


factory : Factory (AnimBuilder eng) (Size.Builder eng)
factory =
    { initH = Size.initH
    , initW = Size.initW
    , initHW = Size.initHW
    , initCssUnitH = Size.initCssUnitH
    , initCssUnitW = Size.initCssUnitW
    , initCssUnit = Size.initCssUnit
    , begin = Size.begin
    , end = Size.end
    }
