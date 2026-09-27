module Factories.Properties.CustomProperty exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property exposing (Property)


type alias InitFactory builder =
    { init : String -> Property -> Float -> builder }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { init = Property.init }
