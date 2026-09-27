module Factories.Properties.Opacity exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity


type alias Factory animBuilder =
    { init : String -> Float -> (animBuilder -> animBuilder) }


factory : Factory (AnimBuilder eng)
factory =
    { init = Opacity.init
    }
