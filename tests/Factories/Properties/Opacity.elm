module Factories.Properties.Opacity exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity


type alias Factory animBuilder builder =
    { init : String -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> builder
    , end : builder -> animBuilder
    }


factory : Factory (AnimBuilder eng) (Opacity.Builder eng)
factory =
    { init = Opacity.init
    , begin = Opacity.begin
    , end = Opacity.end
    }
