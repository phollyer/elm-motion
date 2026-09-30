module Factories.Engines.Transition exposing
    ( Factory
    , factory
    )

import Anim.Engine.Transition as Transition exposing (AnimState, EngineBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)


type alias Factory builder animState =
    { init : List (builder -> builder) -> animState
    , for : String -> (builder -> builder)
    , animate : animState -> (builder -> builder) -> animState
    , delay : Int -> builder -> builder
    , transformOrder : List TransformProperty -> builder -> builder
    }


factory : Factory EngineBuilder AnimState
factory =
    { init = Transition.init
    , for = Transition.for
    , animate = Transition.animate
    , delay = Transition.delay
    , transformOrder = Transition.transformOrder
    }
