module Factories.Engines.Factory exposing
    ( Factory(..)
    , animateFactory
    , initFactory
    , transformOrderFactory
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Factories.Engines.Keyframe as Keyframe
import Factories.Engines.Transition as Transition


type Factory animBuilder animState
    = Keyframe (Keyframe.Factory animBuilder animState)
    | Transition (Transition.Factory animBuilder animState)


type alias InitFactory animBuilder state =
    { init : List (animBuilder -> animBuilder) -> state }


initFactory : Factory a b -> InitFactory a b
initFactory factory =
    case factory of
        Keyframe f ->
            { init = f.init }

        Transition f ->
            { init = f.init }


type alias AnimateFactory animBuilder state =
    { init : List (animBuilder -> animBuilder) -> state
    , animate : state -> (animBuilder -> animBuilder) -> state
    , for : String -> animBuilder -> animBuilder
    }


animateFactory : Factory a b -> AnimateFactory a b
animateFactory factory =
    case factory of
        Keyframe f ->
            AnimateFactory
                f.init
                f.animate
                f.for

        Transition f ->
            AnimateFactory
                f.init
                f.animate
                f.for


type alias TransformOrderFactory animBuilder state =
    { init : List (animBuilder -> animBuilder) -> state
    , animate : state -> (animBuilder -> animBuilder) -> state
    , for : String -> animBuilder -> animBuilder
    , transformOrder : List TransformProperty -> animBuilder -> animBuilder
    }


transformOrderFactory : Factory a b -> TransformOrderFactory a b
transformOrderFactory factory =
    case factory of
        Keyframe f ->
            TransformOrderFactory
                f.init
                f.animate
                f.for
                f.transformOrder

        Transition f ->
            TransformOrderFactory
                f.init
                f.animate
                f.for
                f.transformOrder
