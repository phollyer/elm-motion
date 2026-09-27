module Factories.Properties.PerspectiveOrigin exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit exposing (Unit(..))


type alias Factory animBuilder builder =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initCssUnitX : Unit -> (animBuilder -> animBuilder)
    , initCssUnitY : Unit -> (animBuilder -> animBuilder)
    , initCssUnit : Unit -> (animBuilder -> animBuilder)
    , begin : animBuilder -> builder
    , end : builder -> animBuilder
    }


factory : Factory (AnimBuilder eng) (PerspectiveOrigin.Builder eng)
factory =
    { initX = PerspectiveOrigin.initX
    , initY = PerspectiveOrigin.initY
    , initXY = PerspectiveOrigin.initXY
    , initCssUnitX = PerspectiveOrigin.initCssUnitX
    , initCssUnitY = PerspectiveOrigin.initCssUnitY
    , initCssUnit = PerspectiveOrigin.initCssUnit
    , begin = PerspectiveOrigin.begin
    , end = PerspectiveOrigin.end
    }
