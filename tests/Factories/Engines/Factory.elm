module Factories.Engines.Factory exposing (Factory)

import Anim.Extra.TransformOrder exposing (TransformProperty)


type alias Factory builder animState =
    { init : List (builder -> builder) -> animState
    , for : String -> (builder -> builder)
    , animate : animState -> (builder -> builder) -> animState
    , transformOrder : List TransformProperty -> builder -> builder
    }
