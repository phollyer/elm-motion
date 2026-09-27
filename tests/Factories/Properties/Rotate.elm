module Factories.Properties.Rotate exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate


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


factory : Factory (AnimBuilder eng) (Rotate.Builder eng)
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
    , toX = Rotate.toX
    , toY = Rotate.toY
    , toZ = Rotate.toZ
    , toXY = Rotate.toXY
    , toXZ = Rotate.toXZ
    , toYZ = Rotate.toYZ
    , toXYZ = Rotate.toXYZ
    }
