module Factories.Properties.Scale exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale


type alias Factory animBuilder builder =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initZ : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initXZ : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initYZ : String -> Float -> Float -> (animBuilder -> animBuilder)
    , initXYZ : String -> Float -> Float -> Float -> (animBuilder -> animBuilder)
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


factory : Factory (AnimBuilder eng) (Scale.Builder eng)
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
    , toX = Scale.toX
    , toY = Scale.toY
    , toZ = Scale.toZ
    , toXY = Scale.toXY
    , toXZ = Scale.toXZ
    , toYZ = Scale.toYZ
    , toXYZ = Scale.toXYZ
    }
