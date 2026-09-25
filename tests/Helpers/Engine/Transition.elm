module Helpers.Engine.Transition exposing (..)

import Anim.Builder as Builder
import Anim.Engine.Transition as Transition
import Anim.Property.Translate as Translate
import Helpers.AnimGroups exposing (animGroup)


type alias AxisFunction eng =
    Translate.Builder eng -> Translate.Builder eng


type alias TransitionAxisFunction =
    Translate.Builder Builder.ForTransition -> Translate.Builder Builder.ForTransition


type alias TransitionBuilderFunction =
    Transition.EngineBuilder -> Transition.EngineBuilder


animate : TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
animate axisFunction state =
    Transition.animate state <|
        Transition.for animGroup
            >> translatePipeline axisFunction


animateWithDuration : Int -> TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
animateWithDuration duration axisFunction state =
    Transition.animate state <|
        Transition.duration duration
            >> Transition.for animGroup
            >> translatePipeline axisFunction


animateMultiple : List TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
animateMultiple axesFunctions state =
    List.foldl animate state axesFunctions


animateMultipleWithDuration : Int -> List TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
animateMultipleWithDuration duration axesFunctions state =
    List.foldl (animateWithDuration duration) state axesFunctions


translatePipeline : AxisFunction eng -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
translatePipeline axisFunction =
    Translate.begin
        >> axisFunction
        >> Translate.end


retarget : TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
retarget axisFunction state =
    Transition.retarget state <|
        Transition.for animGroup
            >> translatePipeline axisFunction


retargetMultiple : List TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
retargetMultiple axesFunctions state =
    List.foldl retarget state axesFunctions


retargetWith : List TransitionAxisFunction -> Transition.AnimState -> Transition.AnimState
retargetWith axesFunctions state =
    Transition.retarget state <|
        Transition.for animGroup
            >> List.foldl
                (\axisFunction acc ->
                    acc >> translatePipeline axisFunction
                )
                identity
                axesFunctions
