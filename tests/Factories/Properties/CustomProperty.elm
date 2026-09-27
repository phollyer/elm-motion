module Factories.Properties.CustomProperty exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property exposing (Property)


type alias Factory builder =
    { init : String -> Property -> Float -> builder }


factory : Factory (AnimBuilder eng -> AnimBuilder eng)
factory =
    { init = Property.init }
