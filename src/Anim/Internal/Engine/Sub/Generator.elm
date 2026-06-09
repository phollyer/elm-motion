module Anim.Internal.Engine.Sub.Generator exposing (generateAnimation, init)

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Engine.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Sub.Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Sub.Animations as Animations
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Dict exposing (Dict)
import Motion.Internal.Spring as SpringInt
import Motion.Spring exposing (Spring)
import Shared.Easing as Easing
import Shared.Spring as SpringSolver



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Builder.DefaultsConfig -> Builder.AnimGroupName -> Dict String Builder.DiscreteEntryProperty -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init defaults animGroupName discreteEntryProps discreteExitProps properties =
    let
        processedProps =
            Builder.processProperties defaults animGroupName properties

        animations =
            List.filterMap (toAnimation True) processedProps
                |> Animations.fromList
    in
    AnimGroup.init
        |> AnimGroup.setPlayState PlayState.Complete
        |> AnimGroup.setAnimations animations
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps
        |> AnimGroup.setWillChange (Builder.willChangeComposite processedProps)



-- ============================================================
-- GENERATORS
-- ============================================================


generateAnimation :
    Builder.Iterations
    -> Builder.AnimationDirection
    -> Maybe (List TransformProperty)
    -> Dict String Builder.DiscreteEntryProperty
    -> Dict String Builder.DiscreteExitProperty
    -> Maybe AnimGroup
    -> List Builder.ProcessedPropertyConfig
    -> AnimGroup
generateAnimation iterationCount directionConfig maybeOrder discreteEntryProps discreteExitProps existingAnimation properties =
    let
        adjustedProperties =
            properties
                |> List.map (scaleInterruptDuration existingAnimation)

        animations =
            List.filterMap (toAnimation False) adjustedProperties
                |> Animations.fromList

        transformOrder =
            case maybeOrder of
                Just order ->
                    order

                Nothing ->
                    existingAnimation
                        |> Maybe.map AnimGroup.getTransformOrder
                        |> Maybe.withDefault TransformProperty.default
    in
    AnimGroup.init
        |> AnimGroup.setAnimations animations
        |> AnimGroup.setPlayState PlayState.Running
        |> AnimGroup.setIterationCount iterationCount
        |> AnimGroup.setAnimationDirection directionConfig
        |> AnimGroup.setCurrentIteration 1
        |> AnimGroup.setTransformOrder transformOrder
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps
        |> AnimGroup.setWillChange (Builder.willChangeComposite adjustedProperties)



-- ============================================================
-- HELPERS
-- ============================================================


toAnimation : Bool -> Builder.ProcessedPropertyConfig -> Maybe ( String, Animation )
toAnimation isComplete propertyConfig =
    let
        -- Snap mode bypasses the frame-loop entirely: the PropertyAnimation
        -- is born already complete at its end value, so the renderer reads
        -- `end` on every query and no progress events ever fire.
        snapped =
            Builder.processedPropertyMode propertyConfig == Builder.Snap

        completeFlag =
            isComplete || snapped

        build : property -> Builder.ProcessedAnimationConfig property -> PropertyAnimation property
        build default config =
            let
                durationMs =
                    toFloat config.duration

                easingFn =
                    case config.spring of
                        Just s ->
                            springEasingFunction s durationMs

                        Nothing ->
                            Easing.toFunction config.easing

                resolvedStart =
                    Maybe.withDefault default config.start
            in
            { start = resolvedStart
            , end = config.end
            , easingFunction = easingFn
            , delayMs = toFloat config.delay
            , isComplete = completeFlag
            , totalDurationMs = durationMs
            , elapsedMs =
                if snapped then
                    durationMs + toFloat config.delay

                else
                    0.0
            }
    in
    case propertyConfig of
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            Just
                ( "custom:" ++ cssName
                , CustomProperty cssName unit <|
                    build 0 config
                )

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Just
                ( "customColor:" ++ cssName
                , CustomColorProperty cssName <|
                    build (Color.fromRGB { r = 0, g = 0, b = 0 }) config
                )

        Builder.ProcessedOpacityConfig config ->
            Just
                ( "opacity"
                , Opacity <|
                    build Opacity.default config
                )

        Builder.ProcessedPerspectiveOriginConfig config ->
            Just
                ( "perspectiveOrigin"
                , PerspectiveOrigin config.cssUnit <|
                    build PerspectiveOrigin.default config
                )

        Builder.ProcessedRotateConfig config ->
            Just
                ( "rotate"
                , Rotate <|
                    build Rotate.default config
                )

        Builder.ProcessedScaleConfig config ->
            Just
                ( "scale"
                , Scale <|
                    build Scale.default config
                )

        Builder.ProcessedSizeConfig config ->
            Just
                ( "size"
                , Size config.cssUnit <|
                    build Size.default config
                )

        Builder.ProcessedSkewConfig config ->
            Just
                ( "skew"
                , Skew <|
                    build Skew.default config
                )

        Builder.ProcessedTranslateConfig config ->
            Just
                ( "translate"
                , Translate config.cssUnit <|
                    build Translate.default config
                )


scaleInterruptDuration : Maybe AnimGroup -> Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig
scaleInterruptDuration maybeExisting propertyConfig =
    case ( maybeExisting, propertyConfig ) of
        ( Just existing, Builder.ProcessedOpacityConfig cfg ) ->
            case Animations.get "opacity" (AnimGroup.getAnimations existing) of
                Just (Opacity prev) ->
                    if prev.isComplete then
                        propertyConfig

                    else
                        let
                            prevDistance =
                                Opacity.distance prev.start prev.end

                            prevDurationMs =
                                prev.totalDurationMs

                            nextStart =
                                Maybe.withDefault Opacity.default cfg.start

                            nextDistance =
                                Opacity.distance nextStart cfg.end

                            scaledDurationMs =
                                if prevDistance <= 0 || prevDurationMs <= 0 then
                                    toFloat cfg.duration

                                else
                                    nextDistance * (prevDurationMs / prevDistance)

                            scaledDurationInt =
                                max 0 (round scaledDurationMs)
                        in
                        Builder.ProcessedOpacityConfig { cfg | duration = scaledDurationInt }

                _ ->
                    propertyConfig

        _ ->
            propertyConfig



-- ============================================================
-- SPRING
-- ============================================================


{-| Build a `Float -> Float` interpolator that maps `t` (in `[0, 1]`)
to the spring's normalised position at time `t * durationMs`.

Used by `Sub`'s per-frame loop so that spring-driven motion plugs
into the same `easingFunction` slot as a regular easing curve. The
spring is parametrised on `from = 0` to `to = 1`; the engine then
linearly interpolates between the property's actual start and end
values using that fraction.

-}
springEasingFunction : Spring -> Float -> (Float -> Float)
springEasingFunction s durationMs =
    let
        motion =
            { spring = SpringInt.unwrap s
            , from = 0
            , to = 1
            }

        safeDuration =
            if durationMs <= 0 then
                1

            else
                durationMs
    in
    \t ->
        SpringSolver.valueAt motion (t * safeDuration)
