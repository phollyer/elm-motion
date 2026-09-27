module Factories.Engines.Transition exposing (factory)

import Anim.Engine.Transition as Transition exposing (AnimState, EngineBuilder)
import Factories.Engines.Factory exposing (Factory)


factory : Factory EngineBuilder AnimState
factory =
    { init = Transition.init
    , for = Transition.for
    , animate = Transition.animate
    , transformOrder = Transition.transformOrder
    }
