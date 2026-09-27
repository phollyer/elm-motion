module Factories.Properties.Skew exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew


type alias Factory animBuilder =
    { initX : String -> Float -> (animBuilder -> animBuilder)
    , initY : String -> Float -> (animBuilder -> animBuilder)
    , initXY : String -> Float -> Float -> (animBuilder -> animBuilder)
    }


factory : Factory (AnimBuilder eng)
factory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    }
