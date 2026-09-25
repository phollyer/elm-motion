module Anim.Internal.Engine.Transition.Styles exposing (fromProcessedProperties, fromProcessedPropertiesWithControlledAxes)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Unit as InternalUnit
import Dict exposing (Dict)
import Set exposing (Set)


fromProcessedProperties : List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties baseStyles =
    Styles.fromProcessedProperties baseStyles (extractTransformStyles Nothing)


fromProcessedPropertiesWithControlledAxes : Dict String (Set String) -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedPropertiesWithControlledAxes controlledAxes baseStyles =
    Styles.fromProcessedPropertiesWithControlledAxes (Just controlledAxes) baseStyles (extractTransformStyles (Just controlledAxes))


extractTransformStyles : Maybe (Dict String (Set String)) -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeControlledAxes properties =
    let
        collected =
            List.foldl
                (\prop acc ->
                    case prop of
                        Builder.ProcessedTranslateConfig config ->
                            { acc | translate = translateTransformFor maybeControlledAxes config }

                        Builder.ProcessedRotateConfig config ->
                            { acc | rotate = Rotate.toCssString config.end }

                        Builder.ProcessedSkewConfig config ->
                            { acc | skew = skewTransformFor maybeControlledAxes config }

                        Builder.ProcessedScaleConfig config ->
                            { acc | scale = Scale.toCssString config.end }

                        _ ->
                            acc
                )
                { translate = "", rotate = "", skew = "", scale = "" }
                properties

        transformPart =
            [ collected.translate, collected.rotate, collected.skew, collected.scale ]
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


skewTransformFor : Maybe (Dict String (Set String)) -> Builder.ProcessedAnimationConfig Skew.Skew -> String
skewTransformFor maybeControlledAxes config =
    case maybeControlledAxes |> Maybe.andThen (Dict.get "skew") of
        Just axes ->
            let
                hasX =
                    Set.member "x" axes

                hasY =
                    Set.member "y" axes

                end =
                    Skew.toRecord config.end
            in
            [ if hasX then
                Just ("skewX(" ++ String.fromFloat end.x ++ "deg)")

              else
                Nothing
            , if hasY then
                Just ("skewY(" ++ String.fromFloat end.y ++ "deg)")

              else
                Nothing
            ]
                |> List.filterMap identity
                |> String.join " "

        Nothing ->
            Skew.toCssString config.end


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
