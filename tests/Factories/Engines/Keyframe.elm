module Factories.Engines.Keyframe exposing (factory)

import Anim.Engine.Keyframe as Keyframe exposing (AnimState, EngineBuilder)
import Factories.Engines.Factory exposing (Factory)


factory : Factory EngineBuilder AnimState
factory =
    { init = Keyframe.init
    , for = Keyframe.for
    , animate = Keyframe.animate
    , transformOrder = Keyframe.transformOrder
    }
