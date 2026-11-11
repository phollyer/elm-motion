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
import Html


type EngineFactory animBuilder animState
    = Keyframe (Keyframe.Factory animBuilder animState)
    | Transition (Transition.Factory animBuilder animState)


type alias Factory animBuilder state =
    { init : List (animBuilder -> animBuilder) -> state
    , attributes : String -> state -> List (Html.Attribute Never)
    , animate : state -> (animBuilder -> animBuilder) -> state
    , retarget : state -> (animBuilder -> animBuilder) -> state
    , complete : String -> state -> Result String state
    , isRunning : String -> state -> Maybe Bool
    , isComplete : String -> state -> Maybe Bool
    , for : String -> animBuilder -> animBuilder
    , seedInit : String -> animBuilder -> animBuilder
    , seedAnimation : String -> animBuilder -> animBuilder
    , discreteEntry : String -> String -> animBuilder -> animBuilder
    , discreteExit : String -> String -> String -> animBuilder -> animBuilder
    , delay : Int -> animBuilder -> animBuilder
    , duration : Int -> animBuilder -> animBuilder
    , transformOrder : List TransformProperty -> animBuilder -> animBuilder
    , styleValue : String -> String -> state -> Maybe String
    }


create : EngineFactory a b -> Factory a b
create factory_ =
    case factory_ of
        Keyframe f ->
            Factory
                f.init
                f.attributes
                f.animate
                f.retarget
                f.complete
                f.isRunning
                f.isComplete
                f.for
                f.seedInit
                f.seedAnimation
                f.discreteEntry
                f.discreteExit
                f.delay
                f.duration
                f.transformOrder
                f.styleValue

        Transition f ->
            Factory
                f.init
                f.attributes
                f.animate
                f.retarget
                f.complete
                f.isRunning
                f.isComplete
                f.for
                f.seedInit
                f.seedAnimation
                f.discreteEntry
                f.discreteExit
                f.delay
                f.duration
                f.transformOrder
                f.styleValue


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
