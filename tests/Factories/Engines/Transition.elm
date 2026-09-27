module Factories.Engines.Transition exposing (..)

import Anim.Engine.Transition as Transition exposing (..)
import Factories.Engines.Factory exposing (Factory)


factory : Factory EngineBuilder AnimState
factory =
    { init = Transition.init
    , for = Transition.for
    , animate = Transition.animate
    }
