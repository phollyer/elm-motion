module Anim.Internal.Engine.Keyframe.Styles exposing
    ( baselineTransformParts
    , fromProcessedProperties
    , fromProcessedPropertiesWithControlledAxes
    , generateTransformComponents
    , translateToCss
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Unit as InternalUnit
import Dict
import Set



-- ============================================================
-- GENERATORS
-- ============================================================


generateTransformComponents : Maybe (List TransformProperty) -> Builder.TransformParts -> List String
generateTransformComponents maybeOrder transformParts =
    List.filter (String.isEmpty >> not) <|
        case maybeOrder of
            Nothing ->
                [ transformParts.translate, transformParts.rotate, transformParts.skew, transformParts.scale ]

            Just order ->
                List.filterMap
                    (\o ->
                        let
                            part =
                                case o of
                                    Translate ->
                                        transformParts.translate

                                    Rotate ->
                                        transformParts.rotate

                                    Skew ->
                                        transformParts.skew

                                    Scale ->
                                        transformParts.scale
                        in
                        if part /= "" then
                            Just part

                        else
                            Nothing
                    )
                    order


fromProcessedProperties : Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties maybeOrder maybeTargetValues baseStyles =
    Styles.fromProcessedPropertiesWithControlledAxes Nothing baseStyles <|
        extractTransformStyles Nothing maybeOrder maybeTargetValues


fromProcessedPropertiesWithControlledAxes : Dict.Dict String (Set.Set String) -> Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedPropertiesWithControlledAxes controlledAxes maybeOrder maybeTargetValues baseStyles =
    Styles.fromProcessedPropertiesWithControlledAxes (Just controlledAxes) baseStyles <|
        extractTransformStyles (Just controlledAxes) maybeOrder maybeTargetValues


extractTransformStyles : Maybe (Dict.Dict String (Set.Set String)) -> Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeControlledAxes maybeOrder maybeTargetValues processedProps =
    let
        transforms =
            processedProps
                |> extractTransformsFromProcessed maybeControlledAxes
                |> mergeWithBaselines maybeControlledAxes maybeTargetValues processedProps
                |> generateTransformComponents maybeOrder
                |> String.join " "
    in
    if String.isEmpty transforms then
        []

    else
        [ ( "transform", transforms ) ]



-- ============================================================
-- BASELINES
-- ============================================================


mergeWithBaselines : Maybe (Dict.Dict String (Set.Set String)) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts -> Builder.TransformParts
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


baselineTransformParts : Maybe (Dict.Dict String (Set.Set String)) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
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
                    (translateToCss maybeControlledAxes
                        (Maybe.withDefault { x = InternalUnit.default, y = InternalUnit.default, z = InternalUnit.default } <|
                            PropertyBaselines.getTranslateUnits targets
                        )
                    )
            , rotate = baseline isRotate (PropertyBaselines.getRotate targets) Rotate.toCssString
            , skew = baseline isSkew (PropertyBaselines.getSkew targets) Skew.toCssString
            , scale = baseline isScale (PropertyBaselines.getScale targets) Scale.toCssString
            }


extractTransformsFromProcessed : Maybe (Dict.Dict String (Set.Set String)) -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
extractTransformsFromProcessed maybeControlledAxes properties =
    List.foldl
        (\property acc ->
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { acc | translate = translateToCss maybeControlledAxes config.cssUnit config.end }

                Builder.ProcessedRotateConfig config ->
                    { acc | rotate = Rotate.toCssString config.end }

                Builder.ProcessedSkewConfig config ->
                    { acc | skew = Skew.toCssString config.end }

                Builder.ProcessedScaleConfig config ->
                    { acc | scale = Scale.toCssString config.end }

                _ ->
                    acc
        )
        Builder.emptyTransformParts
        properties


translateToCss : Maybe (Dict.Dict String (Set.Set String)) -> InternalUnit.ResolvedCssUnitAxes -> Translate.Translate -> String
translateToCss maybeControlledAxes cssUnitAxes value =
    case maybeControlledAxes |> Maybe.andThen (Dict.get "translate") of
        Just axes ->
            let
                hasX =
                    Set.member "x" axes

                hasY =
                    Set.member "y" axes

                hasZ =
                    Set.member "z" axes

                coords =
                    Translate.toRecord value

                xSuffix =
                    InternalUnit.toCssSuffix cssUnitAxes.x

                ySuffix =
                    InternalUnit.toCssSuffix cssUnitAxes.y

                zSuffix =
                    InternalUnit.toCssSuffix cssUnitAxes.z

                partial =
                    [ if hasX then
                        Just ("translateX(" ++ String.fromFloat coords.x ++ xSuffix ++ ")")

                      else
                        Nothing
                    , if hasY then
                        Just ("translateY(" ++ String.fromFloat coords.y ++ ySuffix ++ ")")

                      else
                        Nothing
                    , if hasZ then
                        Just ("translateZ(" ++ String.fromFloat coords.z ++ zSuffix ++ ")")

                      else
                        Nothing
                    ]
                        |> List.filterMap identity
                        |> String.join " "
            in
            if Set.size axes == 3 then
                Translate.toCssString cssUnitAxes value

            else if String.isEmpty partial then
                Translate.toCssString cssUnitAxes value

            else
                partial

        Nothing ->
            Translate.toCssString cssUnitAxes value
