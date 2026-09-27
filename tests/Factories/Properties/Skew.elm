module Factories.Properties.Skew exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew


type alias InitFactory animBuilder =
    { initX : String -> Float -> animBuilder
    , initY : String -> Float -> animBuilder
    , initXY : String -> Float -> Float -> animBuilder
    }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    }
