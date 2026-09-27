module Factories.Engines.Keyframe exposing (..)

import Anim.Engine.Keyframe as Keyframe exposing (..)
import Factories.Engines.Factory exposing (Factory)


factory : Factory EngineBuilder AnimState
factory =
    { init = Keyframe.init
    , for = Keyframe.for
    , animate = Keyframe.animate
    }
