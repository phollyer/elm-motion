module Factories.Properties.Scale exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale


type alias Factory animBuilder builder =
    { init : InitFactory animBuilder
    , to : ToFactory builder
    }


factory : Factory (AnimBuilder eng -> AnimBuilder eng) (Scale.Builder eng -> Scale.Builder eng)
factory =
    { init = initFactory
    , to = toFactory
    }


type alias InitFactory animBuilder =
    { initX : String -> Float -> animBuilder
    , initY : String -> Float -> animBuilder
    , initZ : String -> Float -> animBuilder
    , initXY : String -> Float -> Float -> animBuilder
    , initXZ : String -> Float -> Float -> animBuilder
    , initYZ : String -> Float -> Float -> animBuilder
    , initXYZ : String -> Float -> Float -> Float -> animBuilder
    }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { initX = Scale.initX
    , initY = Scale.initY
    , initZ = Scale.initZ
    , initXY = Scale.initXY
    , initXZ = Scale.initXZ
    , initYZ = Scale.initYZ
    , initXYZ = Scale.initXYZ
    }


type alias ToFactory builder =
    { toX : Float -> builder
    , toY : Float -> builder
    , toZ : Float -> builder
    , toXY : Float -> Float -> builder
    , toXZ : Float -> Float -> builder
    , toYZ : Float -> Float -> builder
    , toXYZ : Float -> Float -> Float -> builder
    }


toFactory : ToFactory (Scale.Builder eng -> Scale.Builder eng)
toFactory =
    { toX = Scale.toX
    , toY = Scale.toY
    , toZ = Scale.toZ
    , toXY = Scale.toXY
    , toXZ = Scale.toXZ
    , toYZ = Scale.toYZ
    , toXYZ = Scale.toXYZ
    }
