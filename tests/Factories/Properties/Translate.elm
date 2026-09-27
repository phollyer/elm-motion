module Factories.Properties.Translate exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))


type alias Factory animBuilder builder =
    { init : InitFactory animBuilder
    , to : ToFactory builder
    }


factory : Factory (AnimBuilder eng -> AnimBuilder eng) (Translate.Builder eng -> Translate.Builder eng)
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
    , initCssUnit : Unit -> animBuilder
    , initCssUnitX : Unit -> animBuilder
    , initCssUnitY : Unit -> animBuilder
    , initCssUnitZ : Unit -> animBuilder
    }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
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


toFactory : ToFactory (Translate.Builder eng -> Translate.Builder eng)
toFactory =
    { toX = Translate.toX
    , toY = Translate.toY
    , toZ = Translate.toZ
    , toXY = Translate.toXY
    , toXZ = Translate.toXZ
    , toYZ = Translate.toYZ
    , toXYZ = Translate.toXYZ
    }
