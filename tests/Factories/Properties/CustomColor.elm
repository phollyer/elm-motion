module Factories.Properties.CustomColor exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color exposing (Color)
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty)


type alias InitFactory animBuilder =
    { init : String -> ColorProperty -> Color -> animBuilder }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { init = CustomColor.init }
