module Factories.Properties.Skew exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew


type alias Factory animBuilder =
    { init : InitFactory animBuilder
    }


factory : Factory (AnimBuilder eng -> AnimBuilder eng)
factory =
    { init = initFactory
    }


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
