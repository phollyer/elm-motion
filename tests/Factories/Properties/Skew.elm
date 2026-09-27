module Factories.Properties.Skew exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew


type alias Factory animBuilder builder =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> builder
    , end : builder -> animBuilder
    }


factory : Factory (AnimBuilder eng) (Skew.Builder eng)
factory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    , begin = Skew.begin
    , end = Skew.end
    }
