module Factories.Properties.CustomColor exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color exposing (Color)
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty)


type alias Factory animBuilder =
    { init : String -> ColorProperty -> Color -> animBuilder }


factory : Factory (AnimBuilder eng -> AnimBuilder eng)
factory =
    { init = CustomColor.init }
