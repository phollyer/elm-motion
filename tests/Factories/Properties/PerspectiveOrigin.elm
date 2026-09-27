module Factories.Properties.PerspectiveOrigin exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit exposing (Unit(..))


type alias Factory animBuilder =
    { init : InitFactory animBuilder }


factory : Factory (AnimBuilder eng -> AnimBuilder eng)
factory =
    { init = initFactory
    }


type alias InitFactory animBuilder =
    { initX : String -> Float -> animBuilder
    , initY : String -> Float -> animBuilder
    , initXY : String -> Float -> Float -> animBuilder
    , initCssUnitX : Unit -> animBuilder
    , initCssUnitY : Unit -> animBuilder
    , initCssUnit : Unit -> animBuilder
    }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { initX = PerspectiveOrigin.initX
    , initY = PerspectiveOrigin.initY
    , initXY = PerspectiveOrigin.initXY
    , initCssUnitX = PerspectiveOrigin.initCssUnitX
    , initCssUnitY = PerspectiveOrigin.initCssUnitY
    , initCssUnit = PerspectiveOrigin.initCssUnit
    }
