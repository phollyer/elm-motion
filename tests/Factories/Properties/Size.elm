module Factories.Properties.Size exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Anim.Unit exposing (Unit(..))


type alias InitFactory animBuilder =
    { initH : String -> Float -> animBuilder
    , initW : String -> Float -> animBuilder
    , initHW : String -> Float -> Float -> animBuilder
    , initCssUnitH : Unit -> animBuilder
    , initCssUnitW : Unit -> animBuilder
    , initCssUnit : Unit -> animBuilder
    }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { initH = Size.initH
    , initW = Size.initW
    , initHW = Size.initHW
    , initCssUnitH = Size.initCssUnitH
    , initCssUnitW = Size.initCssUnitW
    , initCssUnit = Size.initCssUnit
    }
