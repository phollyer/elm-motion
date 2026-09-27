module Factories.Properties.Translate exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))


type alias Factory animBuilder builder =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initZ : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initXZ : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initYZ : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initXYZ : String -> Float -> Float -> Float -> (animBuilder -> animBuilder)
    , initCssUnit : Unit -> (animBuilder -> animBuilder)
    , initCssUnitX : Unit -> (animBuilder -> animBuilder)
    , initCssUnitY : Unit -> (animBuilder -> animBuilder)
    , initCssUnitZ : Unit -> (animBuilder -> animBuilder)
    , begin : animBuilder -> builder
    , end : builder -> animBuilder
    , toX : Float -> (builder -> builder)
    , toY : Float -> (builder -> builder)
    , toZ : Float -> (builder -> builder)
    , toXY : Float -> Float -> (builder -> builder)
    , toXZ : Float -> Float -> (builder -> builder)
    , toYZ : Float -> Float -> (builder -> builder)
    , toXYZ : Float -> Float -> Float -> (builder -> builder)
    }


factory : Factory (AnimBuilder eng) (Translate.Builder eng)
factory =
    { initX = Translate.initX
    , initY = Translate.initY
    , initZ = Translate.initZ
    , initXY = Translate.initXY
    , initXZ = Translate.initXZ
    , initYZ = Translate.initYZ
    , initXYZ = Translate.initXYZ
    , initCssUnit = Translate.initCssUnit
    , initCssUnitX = Translate.initCssUnitX
    , initCssUnitY = Translate.initCssUnitY
    , initCssUnitZ = Translate.initCssUnitZ
    , begin = Translate.begin
    , end = Translate.end
    , toX = Translate.toX
    , toY = Translate.toY
    , toZ = Translate.toZ
    , toXY = Translate.toXY
    , toXZ = Translate.toXZ
    , toYZ = Translate.toYZ
    , toXYZ = Translate.toXYZ
    }
