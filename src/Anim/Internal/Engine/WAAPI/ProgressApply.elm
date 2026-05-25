module Anim.Internal.Engine.WAAPI.ProgressApply exposing (applyPropertyProgress)

{-| Apply per-property raw progress (sent over the JS port) to the
`PropertyBaselines` snapshot, using the easing and start/end from the
`ProcessedPropertyConfig` stored on each `PropertyState`.

This is the Elm side of the per-property progress wire format: JS sends
`{ propType -> rawProgress }` and Elm interpolates locally rather than
trusting JS-computed absolute values.

@docs applyPropertyProgress

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Shared.Interpolation as Interpolation
import Anim.Internal.Engine.WAAPI.AnimGroup exposing (PropertyState)
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Dict exposing (Dict)
import Shared.Easing



-- ============================================================
-- APPLY
-- ============================================================


{-| Apply each entry of `propertyProgress` to `baselines`, looking up the
matching `PropertyState` (and its stored config) in `propertyStates`.

Properties not in `propertyStates` are silently skipped; the JS side only
sends progress for properties Elm has registered.

For each property the raw progress is passed through the config's easing
function before interpolation. When the config has `start = Nothing` we
fall back to the current baseline value (which is the value snapshotted
at animation creation time on the first invocation).

-}
applyPropertyProgress :
    Dict String Float
    -> AnimGroups PropertyState
    -> PropertyBaselines
    -> PropertyBaselines
applyPropertyProgress propertyProgress propertyStates baselines =
    Dict.foldl
        (\propType rawProgress acc ->
            case AnimGroups.get propType propertyStates of
                Nothing ->
                    acc

                Just propState ->
                    applyConfigProgress propState.config rawProgress acc
        )
        baselines
        propertyProgress


applyConfigProgress : Builder.ProcessedPropertyConfig -> Float -> PropertyBaselines -> PropertyBaselines
applyConfigProgress config rawProgress baselines =
    case config of
        Builder.ProcessedOpacityConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getOpacity baselines) Opacity.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setOpacity (Interpolation.interpolateOpacity t start cfg.end) baselines

        Builder.ProcessedTranslateConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getTranslate baselines) Translate.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setTranslate (Interpolation.interpolateTranslate t start cfg.end) baselines

        Builder.ProcessedRotateConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getRotate baselines) Rotate.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setRotate (Interpolation.interpolateRotate t start cfg.end) baselines

        Builder.ProcessedScaleConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getScale baselines) Scale.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setScale (Interpolation.interpolateScale t start cfg.end) baselines

        Builder.ProcessedSkewConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getSkew baselines) Skew.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setSkew (Interpolation.interpolateSkew t start cfg.end) baselines

        Builder.ProcessedSizeConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getSize baselines) Size.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setSize (Interpolation.interpolateSize t start cfg.end) baselines

        Builder.ProcessedPerspectiveOriginConfig cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getPerspectiveOrigin baselines) PerspectiveOrigin.default

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setPerspectiveOrigin (Interpolation.interpolatePerspectiveOrigin t start cfg.end) baselines

        Builder.ProcessedCustomPropertyConfig cssName unit cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getCustomProperty cssName baselines) 0

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setCustomProperty cssName (Interpolation.interpolateFloat t start cfg.end) unit baselines

        Builder.ProcessedCustomColorPropertyConfig cssName cfg ->
            let
                start =
                    resolveStart cfg.start (PropertyBaselines.getCustomColorProperty cssName baselines) Color.transparent

                t =
                    Shared.Easing.toFunction cfg.easing rawProgress
            in
            PropertyBaselines.setCustomColorProperty cssName (Color.interpolate t start cfg.end) baselines



-- ============================================================
-- HELPERS
-- ============================================================


{-| Resolve the animation's start value with a three-tier fallback:
the explicit config start, the current baseline (snapshotted when the
animation began on the first invocation), or the type's default.
-}
resolveStart : Maybe a -> Maybe a -> a -> a
resolveStart configStart baselineCurrent default =
    case configStart of
        Just value ->
            value

        Nothing ->
            Maybe.withDefault default baselineCurrent
