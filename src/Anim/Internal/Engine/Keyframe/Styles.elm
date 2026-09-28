module Anim.Internal.Engine.Keyframe.Styles exposing
    ( baselineTransformParts
    , fromProcessedPropertiesWithControlledAxes
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.CSS.Transform as Transform
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Unit as InternalUnit
import Dict exposing (Dict)
import Set exposing (Set)



-- ============================================================
-- GENERATORS
-- ============================================================


fromProcessedPropertiesWithControlledAxes : Dict String (Set String) -> Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedPropertiesWithControlledAxes controlledAxes maybeOrder maybeTargetValues baseStyles =
    Styles.fromProcessedPropertiesWithControlledAxes (Just controlledAxes) baseStyles <|
        extractTransformStyles (Just controlledAxes) maybeOrder maybeTargetValues


extractTransformStyles : Maybe (Dict String (Set String)) -> Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeControlledAxes maybeOrder maybeTargetValues properties =
    let
        transformParts =
            Transform.extractParts maybeControlledAxes properties

        merged =
            mergeWithBaselines maybeControlledAxes maybeTargetValues properties transformParts
    in
    List.filterMap identity
        [ Transform.toStyle maybeOrder merged ]



-- ============================================================
-- BASELINES
-- ============================================================


mergeWithBaselines : Maybe (Dict String (Set String)) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts -> Builder.TransformParts
mergeWithBaselines maybeControlledAxes maybeTargetValues processedProps animated =
    let
        baselines =
            baselineTransformParts maybeControlledAxes maybeTargetValues processedProps

        selectOrBaseline accessor =
            if accessor animated /= "" then
                accessor animated

            else
                accessor baselines
    in
    { translate = selectOrBaseline .translate
    , rotate = selectOrBaseline .rotate
    , skew = selectOrBaseline .skew
    , scale = selectOrBaseline .scale
    }


baselineTransformParts : Maybe (Dict String (Set String)) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
baselineTransformParts maybeControlledAxes maybeTargetValues processedProps =
    case maybeTargetValues of
        Nothing ->
            Builder.emptyTransformParts

        Just targets ->
            let
                baseline isAnimated maybeValue toCssString =
                    if List.any isAnimated processedProps then
                        ""

                    else
                        maybeValue
                            |> Maybe.map toCssString
                            |> Maybe.withDefault ""

                isTranslate p =
                    case p of
                        Builder.ProcessedTranslateConfig _ ->
                            True

                        _ ->
                            False

                isRotate p =
                    case p of
                        Builder.ProcessedRotateConfig _ ->
                            True

                        _ ->
                            False

                isScale p =
                    case p of
                        Builder.ProcessedScaleConfig _ ->
                            True

                        _ ->
                            False

                isSkew p =
                    case p of
                        Builder.ProcessedSkewConfig _ ->
                            True

                        _ ->
                            False
            in
            { translate =
                baseline isTranslate
                    (PropertyBaselines.getTranslate targets)
                    (Styles.translateToCss maybeControlledAxes
                        (Maybe.withDefault { x = InternalUnit.default, y = InternalUnit.default, z = InternalUnit.default } <|
                            PropertyBaselines.getTranslateUnits targets
                        )
                    )
            , rotate = baseline isRotate (PropertyBaselines.getRotate targets) Rotate.toCssString
            , skew = baseline isSkew (PropertyBaselines.getSkew targets) Skew.toCssString
            , scale = baseline isScale (PropertyBaselines.getScale targets) Scale.toCssString
            }
