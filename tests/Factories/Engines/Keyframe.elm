module Factories.Engines.Keyframe exposing
    ( Animation
    , Factory
    , animation
    , animationName
    , animationToString
    , createAnimation
    , factory
    , withDelay
    , withDirection
    , withDuration
    , withFillMode
    , withIterationCount
    , withTimingFunction
    )

import Anim.Engine.Keyframe as Keyframe exposing (AnimState, EngineBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)


type alias Factory builder animState =
    { init : List (builder -> builder) -> animState
    , for : String -> (builder -> builder)
    , animate : animState -> (builder -> builder) -> animState
    , delay : Int -> builder -> builder
    , transformOrder : List TransformProperty -> builder -> builder
    , keyframesString : String -> animState -> Maybe String
    }


factory : Factory EngineBuilder AnimState
factory =
    { init = Keyframe.init
    , for = Keyframe.for
    , animate = Keyframe.animate
    , delay = Keyframe.delay
    , transformOrder = Keyframe.transformOrder
    , keyframesString = Keyframe.maybeString
    }


type alias Animation =
    { name : String
    , duration : String
    , timingFunction : String
    , delay : String
    , iterationCount : String
    , direction : String
    , fillMode : String
    }


animationToString : Animation -> String
animationToString anim =
    String.join " "
        [ anim.name
        , anim.duration
        , anim.timingFunction
        , anim.delay
        , anim.iterationCount
        , anim.direction
        , anim.fillMode
        ]


animation : Animation
animation =
    { name = ""
    , duration = ""
    , timingFunction = ""
    , delay = ""
    , iterationCount = ""
    , direction = ""
    , fillMode = ""
    }


createAnimation : (String -> animState -> Maybe String) -> String -> animState -> Animation
createAnimation keyframesStringFunc animGroup animState =
    case animationName keyframesStringFunc animGroup animState of
        Just name ->
            { name = name
            , duration = "0ms"
            , timingFunction = "linear"
            , delay = "0ms"
            , iterationCount = "1"
            , direction = "normal"
            , fillMode = "forwards"
            }

        Nothing ->
            { name = ""
            , duration = ""
            , timingFunction = ""
            , delay = ""
            , iterationCount = ""
            , direction = ""
            , fillMode = ""
            }


withDuration : String -> Animation -> Animation
withDuration duration anim =
    { anim | duration = duration }


withTimingFunction : String -> Animation -> Animation
withTimingFunction timingFunction anim =
    { anim | timingFunction = timingFunction }


withDelay : String -> Animation -> Animation
withDelay delay anim =
    { anim | delay = delay }


withIterationCount : String -> Animation -> Animation
withIterationCount iterationCount anim =
    { anim | iterationCount = iterationCount }


withDirection : String -> Animation -> Animation
withDirection direction anim =
    { anim | direction = direction }


withFillMode : String -> Animation -> Animation
withFillMode fillMode anim =
    { anim | fillMode = fillMode }


animationName : (String -> animState -> Maybe String) -> String -> animState -> Maybe String
animationName keyframesStringFunc animGroup animState =
    keyframesStringFunc animGroup animState
        |> Maybe.andThen animationNameFromKeyframes


animationNameFromKeyframes : String -> Maybe String
animationNameFromKeyframes keyframes =
    case String.words keyframes of
        "@keyframes" :: name :: _ ->
            Just name

        _ ->
            Nothing
