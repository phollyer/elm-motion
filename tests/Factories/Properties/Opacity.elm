module Factories.Properties.Opacity exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity


type alias Factory animBuilder =
    { init : InitFactory animBuilder }


factory : Factory (AnimBuilder eng -> AnimBuilder eng)
factory =
    { init = initFactory
    }


type alias InitFactory animBuilder =
    { init : String -> Float -> animBuilder }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { init = Opacity.init }
