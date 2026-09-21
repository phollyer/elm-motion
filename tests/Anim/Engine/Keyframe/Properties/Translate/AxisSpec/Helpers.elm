module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.Helpers exposing (..)

import Anim.Builder as Builder
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Translate as Translate


type alias AxisFunction eng =
    Translate.Builder eng -> Translate.Builder eng


type alias KeyframeAxisFunction =
    Translate.Builder Builder.ForKeyframe -> Translate.Builder Builder.ForKeyframe


type alias KeyframeBuilderFunction =
    Keyframe.EngineBuilder -> Keyframe.EngineBuilder


animate : KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
animate axisFunction state =
    Keyframe.animate state <|
        Keyframe.for animGroup
            >> translatePipeline axisFunction


animateWithDuration : Int -> KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
animateWithDuration duration axisFunction state =
    Keyframe.animate state <|
        Keyframe.duration duration
            >> Keyframe.for animGroup
            >> translatePipeline axisFunction


animateMultiple : List KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
animateMultiple axesFunctions state =
    List.foldl animate state axesFunctions


animateMultipleWithDuration : Int -> List KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
animateMultipleWithDuration duration axesFunctions state =
    List.foldl (animateWithDuration duration) state axesFunctions


translatePipeline : AxisFunction eng -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
translatePipeline axisFunction =
    Translate.begin
        >> axisFunction
        >> Translate.end


retarget : KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
retarget axisFunction state =
    Keyframe.retarget state <|
        Keyframe.for animGroup
            >> translatePipeline axisFunction


retargetMultiple : List KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
retargetMultiple axesFunctions state =
    List.foldl retarget state axesFunctions


retargetWith : List KeyframeAxisFunction -> Keyframe.AnimState -> Keyframe.AnimState
retargetWith axesFunctions state =
    Keyframe.retarget state <|
        Keyframe.for animGroup
            >> List.foldl
                (\axisFunction acc ->
                    acc >> translatePipeline axisFunction
                )
                identity
                axesFunctions


animGroup : String
animGroup =
    "el"


keyframeString : Keyframe.AnimState -> String
keyframeString state =
    Keyframe.maybeString animGroup state
        |> Maybe.withDefault ""
