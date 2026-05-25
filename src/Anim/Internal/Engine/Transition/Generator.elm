module Anim.Internal.Engine.Transition.Generator exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Transition.Styles as TransitionStyles
import Dict exposing (Dict)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Set
import Shared.Easing as InternalEasing



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init discreteTransitions discreteEntry discreteExit properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties
    in
    AnimGroup.init
        |> AnimGroup.setDiscreteEntry discreteEntry
        |> AnimGroup.setDiscreteExit discreteExit
        |> AnimGroup.setPropertyKeys (propertyKeysOf processedProps)
        |> AnimGroup.setWillChange (Builder.willChangeIndividual processedProps)
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions processedProps)
                processedProps
            )



-- ============================================================
-- GENERATORS
-- ============================================================


generateAnimation : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateAnimation discreteTransitions discreteEntry discreteExit processedProps =
    AnimGroup.init
        |> AnimGroup.setDiscreteEntry discreteEntry
        |> AnimGroup.setDiscreteExit discreteExit
        |> AnimGroup.setPropertyKeys (propertyKeysOf processedProps)
        |> AnimGroup.setWillChange (Builder.willChangeIndividual processedProps)
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions processedProps)
                processedProps
            )


propertyKeysOf : List Builder.ProcessedPropertyConfig -> Set.Set String
propertyKeysOf =
    List.foldl (Builder.processedPropertyType >> Set.insert) Set.empty


baseStyles : Bool -> List Builder.ProcessedPropertyConfig -> List ( String, String )
baseStyles discreteTransitions processedProps =
    let
        transitionBehavior =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []
    in
    ( "transition", generate processedProps ) :: transitionBehavior



-- ============================================================
-- CSS TRANSITION STRING
-- ============================================================


generate : List Builder.ProcessedPropertyConfig -> String
generate properties =
    let
        allDurationsZero =
            properties
                |> List.all
                    (\prop ->
                        case prop of
                            Builder.ProcessedCustomPropertyConfig _ _ config ->
                                config.duration == 0

                            Builder.ProcessedCustomColorPropertyConfig _ config ->
                                config.duration == 0

                            Builder.ProcessedOpacityConfig config ->
                                config.duration == 0

                            Builder.ProcessedPerspectiveOriginConfig config ->
                                config.duration == 0

                            Builder.ProcessedRotateConfig config ->
                                config.duration == 0

                            Builder.ProcessedScaleConfig config ->
                                config.duration == 0

                            Builder.ProcessedSizeConfig config ->
                                config.duration == 0

                            Builder.ProcessedSkewConfig config ->
                                config.duration == 0

                            Builder.ProcessedTranslateConfig config ->
                                config.duration == 0
                    )
    in
    if allDurationsZero then
        "none"

    else
        let
            transformTransition =
                transformTransitionFromProcessed properties

            nonTransformTransitions =
                List.filterMap nonTransformTransitionFromProcessed properties

            allTransitions =
                case transformTransition of
                    Just t ->
                        t :: nonTransformTransitions

                    Nothing ->
                        nonTransformTransitions
        in
        String.join ", " allTransitions



-- ============================================================
-- HELPERS
-- ============================================================


{-| Emits a single `transform` transition rule. When both rotate and skew are
present, rotate's settings take priority. If only skew is present, skew's
settings are used.
-}
transformTransitionFromProcessed : List Builder.ProcessedPropertyConfig -> Maybe String
transformTransitionFromProcessed properties =
    let
        rotateConfig =
            properties
                |> List.filterMap
                    (\p ->
                        case p of
                            Builder.ProcessedRotateConfig config ->
                                Just config

                            _ ->
                                Nothing
                    )
                |> List.head

        skewConfig =
            properties
                |> List.filterMap
                    (\p ->
                        case p of
                            Builder.ProcessedSkewConfig config ->
                                Just config

                            _ ->
                                Nothing
                    )
                |> List.head
    in
    case rotateConfig of
        Just config ->
            Just (transitionRule "transform" config)

        Nothing ->
            Maybe.map (transitionRule "transform") skewConfig


nonTransformTransitionFromProcessed : Builder.ProcessedPropertyConfig -> Maybe String
nonTransformTransitionFromProcessed property =
    case property of
        Builder.ProcessedCustomPropertyConfig cssName _ config ->
            Just (transitionRule cssName config)

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Just (transitionRule cssName config)

        Builder.ProcessedOpacityConfig config ->
            Just (transitionRule "opacity" config)

        Builder.ProcessedPerspectiveOriginConfig config ->
            Just (transitionRule "perspective-origin" config)

        Builder.ProcessedRotateConfig _ ->
            Nothing

        Builder.ProcessedScaleConfig config ->
            Just (transitionRule "scale" config)

        Builder.ProcessedSizeConfig config ->
            Just (transitionRule "width" config ++ ", " ++ transitionRule "height" config)

        Builder.ProcessedSkewConfig _ ->
            Nothing

        Builder.ProcessedTranslateConfig config ->
            Just (transitionRule "translate" config)


{-| Build a single CSS `transition` rule for a given property name.
-}
transitionRule : String -> Builder.ProcessedAnimationConfig a -> String
transitionRule cssName cfg =
    cssName
        ++ " "
        ++ String.fromInt cfg.duration
        ++ "ms "
        ++ timingFunction cfg.spring cfg.easing
        ++ " "
        ++ String.fromInt cfg.delay
        ++ "ms"


{-| Resolve the CSS `transition-timing-function` for a property. Falls back to
an overshoot cubic-bezier when a `Spring` is set.
-}
timingFunction : Maybe Spring -> Easing -> String
timingFunction maybeSpring easing =
    case maybeSpring of
        Just _ ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        Nothing ->
            InternalEasing.toCSS (Just easing)
