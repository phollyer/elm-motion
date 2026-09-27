module Factories.Properties.Rotate exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate


type alias Factory animBuilder builder =
    { init : InitFactory animBuilder
    , to : ToFactory builder
    }


factory : Factory (AnimBuilder eng -> AnimBuilder eng) (Rotate.Builder eng -> Rotate.Builder eng)
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
    { initX = Rotate.initX
    , initY = Rotate.initY
    , initZ = Rotate.initZ
    , initXY = Rotate.initXY
    , initXZ = Rotate.initXZ
    , initYZ = Rotate.initYZ
    , initXYZ = Rotate.initXYZ
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


toFactory : ToFactory (Rotate.Builder eng -> Rotate.Builder eng)
toFactory =
    { toX = Rotate.toX
    , toY = Rotate.toY
    , toZ = Rotate.toZ
    , toXY = Rotate.toXY
    , toXZ = Rotate.toXZ
    , toYZ = Rotate.toYZ
    , toXYZ = Rotate.toXYZ
    }
