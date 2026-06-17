module Anim.Internal.Engine.WAAPI.Generator exposing
    ( generateAnimation
    , init
    , propertyBounds
    , propertyTypeString
    , resolveStartFromSnapshot
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus(..))
import Dict exposing (Dict)



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Builder.DefaultsConfig -> Builder.AnimGroupName -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init defaults animGroupName discreteEntryProps discreteExitProps properties =
    let
        processedProps =
            Builder.processProperties defaults animGroupName properties
    in
    AnimGroup.init
        |> AnimGroup.setSnapshot (endBounds processedProps)
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps



-- ============================================================
-- GENERATORS
-- ============================================================


generateAnimation :
    Builder.Iterations
    -> Builder.AnimationDirection
    -> Maybe (List TransformProperty)
    -> Dict String String
    -> Dict String Builder.DiscreteExitProperty
    -> Maybe AnimGroup
    -> List Builder.ProcessedPropertyConfig
    -> AnimGroup
generateAnimation iterations animationDirection globalTransformOrder discreteEntryProps discreteExitProps existingAnimation properties =
    let
        animationBounds =
            propertyBounds properties

        snapBounds =
            -- Snap properties commit their end value to the visual
            -- baseline immediately, so subsequent animations resolve
            -- their implicit start from the snapped position.
            propertyBounds
                (List.filter
                    (\p -> Builder.processedPropertyMode p == Builder.Snap)
                    properties
                )

        snapshot =
            case existingAnimation of
                Just existing ->
                    -- Keep current visual state when a new animation is queued.
                    -- Only merge explicit start values, so we never pre-paint
                    -- the next end state for a frame before WAAPI starts.
                    PropertyBaselines.merge (AnimGroup.getPropertySnapshot existing) animationBounds.start
                        |> PropertyBaselines.merge snapBounds.end

                Nothing ->
                    -- For brand-new groups, only apply explicit start bounds.
                    -- End values are applied by WAAPI updates as animation runs.
                    PropertyBaselines.merge animationBounds.start snapBounds.end

        existingPropertyVersions =
            existingAnimation
                |> Maybe.map AnimGroup.getPropertyStates
                |> Maybe.withDefault AnimGroups.init

        newPropertyVersions =
            properties
                |> List.map
                    (\property ->
                        let
                            propType =
                                propertyTypeString property

                            newVersion =
                                AnimGroups.get propType existingPropertyVersions
                                    |> Maybe.map .version
                                    |> Maybe.map ((+) 1)
                                    |> Maybe.withDefault 1

                            initialStatus =
                                if Builder.processedPropertyMode property == Builder.Snap then
                                    Complete

                                else
                                    NotStarted
                        in
                        ( propType
                        , { version = newVersion
                          , status = initialStatus
                          , config = resolveStartFromSnapshot snapshot property
                          }
                        )
                    )
                |> AnimGroups.fromList

        mergedPropertyVersions =
            AnimGroups.union newPropertyVersions existingPropertyVersions

        transformOrder =
            case globalTransformOrder of
                Just order ->
                    order

                Nothing ->
                    existingAnimation
                        |> Maybe.map AnimGroup.getTransformOrder
                        |> Maybe.withDefault TransformProperty.default
    in
    AnimGroup.init
        |> AnimGroup.setSnapshot snapshot
        |> AnimGroup.setPropertyStates mergedPropertyVersions
        |> AnimGroup.setTransformOrder transformOrder
        |> AnimGroup.setIterationCount iterations
        |> AnimGroup.setAnimationDirection animationDirection
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps


propertyTypeString : Builder.ProcessedPropertyConfig -> String
propertyTypeString property =
    case property of
        Builder.ProcessedTranslateConfig _ ->
            "translate"

        Builder.ProcessedRotateConfig _ ->
            "rotate"

        Builder.ProcessedSkewConfig _ ->
            "skew"

        Builder.ProcessedScaleConfig _ ->
            "scale"

        Builder.ProcessedOpacityConfig _ ->
            "opacity"

        Builder.ProcessedPerspectiveOriginConfig _ ->
            "perspectiveOrigin"

        Builder.ProcessedSizeConfig _ ->
            "size"

        Builder.ProcessedCustomPropertyConfig cssName _ _ ->
            "custom:" ++ cssName

        Builder.ProcessedCustomColorPropertyConfig cssName _ ->
            "customColor:" ++ cssName


{-| When a property config has `start = Nothing`, resolve it to the value
currently held in the snapshot. This anchors the per-frame Elm-side
interpolation to a fixed starting point for the lifetime of the animation,
so subsequent baseline mutations cannot cause the interpolation start to
drift.

If the snapshot also has no value for the property, `start` is left as
`Nothing` — `ProgressApply` falls back to property-specific identity values
in that case.

-}
resolveStartFromSnapshot : PropertyBaselines -> Builder.ProcessedPropertyConfig -> Builder.ProcessedPropertyConfig
resolveStartFromSnapshot snapshot property =
    let
        fill : Maybe a -> Maybe a -> Maybe a
        fill existing fromSnapshot =
            case existing of
                Just _ ->
                    existing

                Nothing ->
                    fromSnapshot
    in
    case property of
        Builder.ProcessedTranslateConfig config ->
            Builder.ProcessedTranslateConfig { config | start = fill config.start (PropertyBaselines.getTranslate snapshot) }

        Builder.ProcessedRotateConfig config ->
            Builder.ProcessedRotateConfig { config | start = fill config.start (PropertyBaselines.getRotate snapshot) }

        Builder.ProcessedSkewConfig config ->
            Builder.ProcessedSkewConfig { config | start = fill config.start (PropertyBaselines.getSkew snapshot) }

        Builder.ProcessedScaleConfig config ->
            Builder.ProcessedScaleConfig { config | start = fill config.start (PropertyBaselines.getScale snapshot) }

        Builder.ProcessedOpacityConfig config ->
            Builder.ProcessedOpacityConfig { config | start = fill config.start (PropertyBaselines.getOpacity snapshot) }

        Builder.ProcessedPerspectiveOriginConfig config ->
            Builder.ProcessedPerspectiveOriginConfig { config | start = fill config.start (PropertyBaselines.getPerspectiveOrigin snapshot) }

        Builder.ProcessedSizeConfig config ->
            Builder.ProcessedSizeConfig { config | start = fill config.start (PropertyBaselines.getSize snapshot) }

        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            Builder.ProcessedCustomPropertyConfig cssName unit { config | start = fill config.start (PropertyBaselines.getCustomProperty cssName snapshot) }

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Builder.ProcessedCustomColorPropertyConfig cssName { config | start = fill config.start (PropertyBaselines.getCustomColorProperty cssName snapshot) }



-- ============================================================
-- PROPERTY BOUNDS
-- ============================================================


propertyBounds : List Builder.ProcessedPropertyConfig -> { start : PropertyBaselines, end : PropertyBaselines }
propertyBounds properties =
    let
        setBounds : Builder.ProcessedPropertyConfig -> { start : PropertyBaselines, end : PropertyBaselines } -> { start : PropertyBaselines, end : PropertyBaselines }
        setBounds property { start, end } =
            case property of
                Builder.ProcessedCustomPropertyConfig cssName unit config ->
                    { start = maybeSet (\v -> PropertyBaselines.setCustomProperty cssName v unit) config.start start, end = PropertyBaselines.setCustomProperty cssName config.end unit end }

                Builder.ProcessedCustomColorPropertyConfig cssName config ->
                    { start = maybeSet (PropertyBaselines.setCustomColorProperty cssName) config.start start, end = PropertyBaselines.setCustomColorProperty cssName config.end end }

                Builder.ProcessedOpacityConfig config ->
                    { start = maybeSet PropertyBaselines.setOpacity config.start start, end = PropertyBaselines.setOpacity config.end end }

                Builder.ProcessedPerspectiveOriginConfig config ->
                    { start =
                        maybeSet PropertyBaselines.setPerspectiveOrigin config.start start
                            |> PropertyBaselines.setPerspectiveOriginUnits config.cssUnit
                    , end =
                        PropertyBaselines.setPerspectiveOrigin config.end end
                            |> PropertyBaselines.setPerspectiveOriginUnits config.cssUnit
                    }

                Builder.ProcessedRotateConfig config ->
                    { start = maybeSet PropertyBaselines.setRotate config.start start, end = PropertyBaselines.setRotate config.end end }

                Builder.ProcessedScaleConfig config ->
                    { start = maybeSet PropertyBaselines.setScale config.start start, end = PropertyBaselines.setScale config.end end }

                Builder.ProcessedSizeConfig config ->
                    { start =
                        maybeSet PropertyBaselines.setSize config.start start
                            |> PropertyBaselines.setSizeUnits config.cssUnit
                    , end =
                        PropertyBaselines.setSize config.end end
                            |> PropertyBaselines.setSizeUnits config.cssUnit
                    }

                Builder.ProcessedSkewConfig config ->
                    { start = maybeSet PropertyBaselines.setSkew config.start start, end = PropertyBaselines.setSkew config.end end }

                Builder.ProcessedTranslateConfig config ->
                    { start =
                        maybeSet PropertyBaselines.setTranslate config.start start
                            |> PropertyBaselines.setTranslateUnits config.cssUnit
                    , end =
                        PropertyBaselines.setTranslate config.end end
                            |> PropertyBaselines.setTranslateUnits config.cssUnit
                    }
    in
    List.foldl setBounds { start = PropertyBaselines.empty, end = PropertyBaselines.empty } properties


maybeSet : (a -> PropertyBaselines -> PropertyBaselines) -> Maybe a -> PropertyBaselines -> PropertyBaselines
maybeSet setter maybeValue baselines =
    case maybeValue of
        Just value ->
            setter value baselines

        Nothing ->
            baselines


endBounds : List Builder.ProcessedPropertyConfig -> PropertyBaselines
endBounds properties =
    let
        setBounds : Builder.ProcessedPropertyConfig -> PropertyBaselines -> PropertyBaselines
        setBounds property end =
            case property of
                Builder.ProcessedCustomPropertyConfig cssName unit config ->
                    PropertyBaselines.setCustomProperty cssName config.end unit end

                Builder.ProcessedCustomColorPropertyConfig cssName config ->
                    PropertyBaselines.setCustomColorProperty cssName config.end end

                Builder.ProcessedOpacityConfig config ->
                    PropertyBaselines.setOpacity config.end end

                Builder.ProcessedPerspectiveOriginConfig config ->
                    PropertyBaselines.setPerspectiveOrigin config.end end
                        |> PropertyBaselines.setPerspectiveOriginUnits config.cssUnit

                Builder.ProcessedRotateConfig config ->
                    PropertyBaselines.setRotate config.end end

                Builder.ProcessedScaleConfig config ->
                    PropertyBaselines.setScale config.end end

                Builder.ProcessedSizeConfig config ->
                    PropertyBaselines.setSize config.end end
                        |> PropertyBaselines.setSizeUnits config.cssUnit

                Builder.ProcessedSkewConfig config ->
                    PropertyBaselines.setSkew config.end end

                Builder.ProcessedTranslateConfig config ->
                    PropertyBaselines.setTranslate config.end end
                        |> PropertyBaselines.setTranslateUnits config.cssUnit
    in
    List.foldl setBounds PropertyBaselines.empty properties
