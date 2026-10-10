module Factories.Engines.Factory exposing
    ( EngineFactory(..)
    , animate
    , animate2
    , build
    , create
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Factories.Engines.Keyframe as Keyframe
import Factories.Engines.Transition as Transition


type EngineFactory animBuilder animState
    = Keyframe (Keyframe.Factory animBuilder animState)
    | Transition (Transition.Factory animBuilder animState)


type alias Factory animBuilder state =
    { init : List (animBuilder -> animBuilder) -> state
    , animate : state -> (animBuilder -> animBuilder) -> state
    , for : String -> animBuilder -> animBuilder
    , delay : Int -> animBuilder -> animBuilder
    , transformOrder : List TransformProperty -> animBuilder -> animBuilder
    }


create : EngineFactory a b -> Factory a b
create factory_ =
    case factory_ of
        Keyframe f ->
            Factory
                f.init
                f.animate
                f.for
                f.delay
                f.transformOrder

        Transition f ->
            Factory
                f.init
                f.animate
                f.for
                f.delay
                f.transformOrder


build : Factory a b -> List (a -> a) -> (a -> a) -> b
build f initFuncs =
    f.init initFuncs
        |> (\initialState -> f.animate initialState)


animate : EngineFactory a b -> String -> List (a -> a) -> (a -> a) -> b
animate factory animGroup initFuncs animateFuncs =
    let
        f =
            create factory
    in
    build f initFuncs <|
        f.for animGroup
            >> animateFuncs


animate2 : EngineFactory a b -> String -> List (a -> a) -> (a -> a) -> (a -> a) -> b
animate2 factory animGroup initFuncs animateFuncs animateFuncs2 =
    let
        f =
            create factory

        state =
            animate factory animGroup initFuncs animateFuncs
    in
    f.animate state <|
        f.for animGroup
            >> animateFuncs2
