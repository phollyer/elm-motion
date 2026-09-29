module Factories.Engines.Keyframe exposing
    ( Factory
    , factory
    )

import Anim.Engine.Keyframe as Keyframe exposing (AnimState, EngineBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)


type alias Factory builder animState =
    { init : List (builder -> builder) -> animState
    , for : String -> (builder -> builder)
    , animate : animState -> (builder -> builder) -> animState
    , transformOrder : List TransformProperty -> builder -> builder
    , keyframesString : String -> animState -> Maybe String
    }


factory : Factory EngineBuilder AnimState
factory =
    { init = Keyframe.init
    , for = Keyframe.for
    , animate = Keyframe.animate
    , transformOrder = Keyframe.transformOrder
    , keyframesString = Keyframe.maybeString
    }
