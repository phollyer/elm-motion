module Anim.Internal.Engine.Transition.Styles exposing (fromProcessedProperties, fromProcessedPropertiesWithControlledAxes)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Unit as InternalUnit
import Dict exposing (Dict)
import Set exposing (Set)


fromProcessedProperties : Maybe (List TransformProperty) -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties maybeOrder baseStyles =
    Styles.fromProcessedProperties baseStyles (extractTransformStyles Nothing maybeOrder)


fromProcessedPropertiesWithControlledAxes : Maybe (List TransformProperty) -> Dict String (Set String) -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedPropertiesWithControlledAxes maybeOrder controlledAxes baseStyles =
    Styles.fromProcessedPropertiesWithControlledAxes (Just controlledAxes) baseStyles (extractTransformStyles (Just controlledAxes) maybeOrder)


extractTransformStyles : Maybe (Dict String (Set String)) -> Maybe (List TransformProperty) -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeControlledAxes maybeOrder properties =
    let
        collected =
            List.foldl
                (\prop acc ->
                    case prop of
                        Builder.ProcessedTranslateConfig config ->
                            { acc | translate = translateTransformFor maybeControlledAxes config }

                        Builder.ProcessedRotateConfig config ->
                            { acc | rotate = Styles.rotateToCss maybeControlledAxes config.end }

                        Builder.ProcessedSkewConfig config ->
                            { acc | skew = Styles.skewToCss maybeControlledAxes config.end }

                        Builder.ProcessedScaleConfig config ->
                            { acc | scale = Scale.toCssString config.end }

                        _ ->
                            acc
                )
                { translate = "", rotate = "", skew = "", scale = "" }
                properties

        transformPart =
            generateTransformComponents maybeOrder collected
                |> List.filter (String.isEmpty >> not)
                |> String.join " "

        transformStyle =
            if String.isEmpty transformPart then
                Nothing

            else
                Just ( "transform", transformPart )
    in
    List.filterMap identity
        [ transformStyle
        ]


generateTransformComponents : Maybe (List TransformProperty) -> { translate : String, rotate : String, skew : String, scale : String } -> List String
generateTransformComponents maybeOrder parts =
    case maybeOrder of
        Nothing ->
            [ parts.translate, parts.rotate, parts.skew, parts.scale ]

        Just order ->
            List.filterMap
                (\prop ->
                    let
                        part =
                            case prop of
                                Translate ->
                                    parts.translate

                                Rotate ->
                                    parts.rotate

                                Skew ->
                                    parts.skew

                                Scale ->
                                    parts.scale
                    in
                    if String.isEmpty part then
                        Nothing

                    else
                        Just part
                )
                order


translateTransformFor : Maybe (Dict String (Set String)) -> Builder.ProcessedAnimationConfig Translate.Translate -> String
translateTransformFor maybeControlledAxes config =
    case controlledTranslateAxes maybeControlledAxes of
        Just axes ->
            translateTransformForAxes axes config

        Nothing ->
            Translate.toCssString config.cssUnit config.end


controlledTranslateAxes : Maybe (Dict String (Set String)) -> Maybe (Set String)
controlledTranslateAxes maybeControlledAxes =
    maybeControlledAxes
        |> Maybe.andThen (Dict.get "translate")


translateTransformForAxes : Set String -> Builder.ProcessedAnimationConfig Translate.Translate -> String
translateTransformForAxes axes config =
    let
        hasX =
            Set.member "x" axes

        hasY =
            Set.member "y" axes

        hasZ =
            Set.member "z" axes

        end =
            Translate.toRecord config.end

        xSuffix =
            InternalUnit.toCssSuffix config.cssUnit.x

        ySuffix =
            InternalUnit.toCssSuffix config.cssUnit.y

        zSuffix =
            InternalUnit.toCssSuffix config.cssUnit.z
    in
    if hasX && hasY && hasZ then
        "translate3d(" ++ String.fromFloat end.x ++ xSuffix ++ ", " ++ String.fromFloat end.y ++ ySuffix ++ ", " ++ String.fromFloat end.z ++ zSuffix ++ ")"

    else
        [ if hasX then
            Just ("translateX(" ++ String.fromFloat end.x ++ xSuffix ++ ")")

          else
            Nothing
        , if hasY then
            Just ("translateY(" ++ String.fromFloat end.y ++ ySuffix ++ ")")

          else
            Nothing
        , if hasZ then
            Just ("translateZ(" ++ String.fromFloat end.z ++ zSuffix ++ ")")

          else
            Nothing
        ]
            |> List.filterMap identity
            |> String.join " "
