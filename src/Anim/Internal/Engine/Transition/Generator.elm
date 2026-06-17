module Anim.Internal.Engine.Transition.Generator exposing
    ( generate
    , generateAnimation
    , init
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Transition.Styles as TransitionStyles
import Dict exposing (Dict)
import Motion.Easing exposing (Easing)
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


init : Builder.DefaultsConfig -> AnimGroupName -> Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init defaults animGroupName discreteTransitions discreteEntry discreteExit properties =
    let
        processedProps =
            Builder.processProperties defaults animGroupName properties
    in
    AnimGroup.init
        |> AnimGroup.setDiscreteEntry discreteEntry
        |> AnimGroup.setDiscreteExit discreteExit
        |> AnimGroup.setPropertyKeys (propertyKeysOf processedProps)
        |> AnimGroup.setWillChange (Builder.willChangeIndividual processedProps)
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions discreteEntry discreteExit processedProps)
                processedProps
            )


baseStyles : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.ProcessedPropertyConfig -> List ( String, String )
baseStyles discreteTransitions discreteEntry discreteExit processedProps =
    let
        transitionBehavior =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []
    in
    ( "transition", generate discreteTransitions discreteEntry discreteExit processedProps ) :: transitionBehavior


propertyKeysOf : List Builder.ProcessedPropertyConfig -> Set.Set String
propertyKeysOf =
    List.foldl (Builder.processedPropertyType >> Set.insert) Set.empty



-- ============================================================
-- GENERATORS
-- ============================================================


generate : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.ProcessedPropertyConfig -> String
generate discreteTransitions discreteEntry discreteExit properties =
    let
        animated =
            (Builder.partitionByMode properties).animate

        allDurationsZero =
            animated
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

        discretePropNames =
            if discreteTransitions then
                discretePropertyNames discreteEntry discreteExit

            else
                []
    in
    if allDurationsZero then
        case discretePropNames of
            [] ->
                "none"

            _ ->
                -- Discrete properties only - they participate via
                -- `transition-behavior: allow-discrete`. Duration 0 means
                -- the discrete flip happens immediately at start.
                String.join ", " (List.map (\n -> n ++ " 0ms") discretePropNames)

    else
        let
            transformTransition =
                transformTransitionFromProcessed animated

            nonTransformTransitions =
                List.filterMap nonTransformTransitionFromProcessed animated

            mainDuration =
                maxAnimationDuration animated

            discreteTransitions_ =
                List.map
                    (\n -> n ++ " " ++ String.fromInt mainDuration ++ "ms")
                    discretePropNames

            allTransitions =
                case transformTransition of
                    Just t ->
                        t :: nonTransformTransitions ++ discreteTransitions_

                    Nothing ->
                        nonTransformTransitions ++ discreteTransitions_
        in
        String.join ", " allTransitions


{-| Collect the distinct CSS property names that appear in `discreteEntry`
or `discreteExit`. These need to be added to `transition-property` so the
browser will respect `transition-behavior: allow-discrete` when flipping
them.
-}
discretePropertyNames : Dict String String -> Dict String Builder.DiscreteExitProperty -> List String
discretePropertyNames discreteEntry discreteExit =
    let
        entryKeys =
            Dict.keys discreteEntry

        exitKeys =
            Dict.keys discreteExit
    in
    entryKeys ++ List.filter (\k -> not (List.member k entryKeys)) exitKeys


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


{-| Build a single CSS `transition` rule for a given property name.
-}
transitionRule : String -> Builder.ProcessedAnimationConfig a -> String
transitionRule cssName cfg =
    cssName
        ++ " "
        ++ String.fromInt cfg.duration
        ++ "ms "
        ++ timingFunction cfg.easing
        ++ " "
        ++ String.fromInt cfg.delay
        ++ "ms"


{-| Resolve the CSS `transition-timing-function` for a property.
-}
timingFunction : Easing -> String
timingFunction easing =
    InternalEasing.toCSS (Just easing)


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


{-| The longest animation duration across the processed properties, used
to time discrete property flips so they finish in lockstep with the
animatable properties (e.g. opacity fades to 0 before `display: none`
takes effect on exit).
-}
maxAnimationDuration : List Builder.ProcessedPropertyConfig -> Int
maxAnimationDuration =
    List.foldl
        (\prop acc ->
            let
                d =
                    case prop of
                        Builder.ProcessedCustomPropertyConfig _ _ config ->
                            config.duration

                        Builder.ProcessedCustomColorPropertyConfig _ config ->
                            config.duration

                        Builder.ProcessedOpacityConfig config ->
                            config.duration

                        Builder.ProcessedPerspectiveOriginConfig config ->
                            config.duration

                        Builder.ProcessedRotateConfig config ->
                            config.duration

                        Builder.ProcessedScaleConfig config ->
                            config.duration

                        Builder.ProcessedSizeConfig config ->
                            config.duration

                        Builder.ProcessedSkewConfig config ->
                            config.duration

                        Builder.ProcessedTranslateConfig config ->
                            config.duration
            in
            max acc d
        )
        0


generateAnimation : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateAnimation discreteTransitions discreteEntry discreteExit processedProps =
    AnimGroup.init
        |> AnimGroup.setDiscreteEntry discreteEntry
        |> AnimGroup.setDiscreteExit discreteExit
        |> AnimGroup.setPropertyKeys (propertyKeysOf processedProps)
        |> AnimGroup.setWillChange (Builder.willChangeIndividual processedProps)
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions discreteEntry discreteExit processedProps)
                processedProps
            )
