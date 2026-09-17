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
                            applyTranslateRender maybeControlledAxes config acc

                        Builder.ProcessedRotateConfig config ->
                            { acc | rotate = Rotate.toCssString config.end }

                        Builder.ProcessedSkewConfig config ->
                            { acc | skew = Skew.toCssString config.end }

                        Builder.ProcessedScaleConfig config ->
                            { acc | scale = Just ( "scale", Scale.toCssPropertyValue config.end ) }

                        _ ->
                            acc
                )
                { translate = Nothing, translateTransform = "", rotate = "", skew = "", scale = Nothing }
                properties

        transformPart =
            [ collected.translateTransform, collected.rotate, collected.skew ]
                |> List.filter (String.isEmpty >> not)
                |> String.join " "

        transformStyle =
            if String.isEmpty transformPart then
                Nothing

            else
                Just ( "transform", transformPart )
    in
    List.filterMap identity
        [ collected.translate
        , transformStyle
        , collected.scale
        ]


applyTranslateRender : Maybe (Dict String (Set String)) -> Builder.ProcessedAnimationConfig Translate.Translate -> { a | rotate : String, scale : Maybe ( String, String ), skew : String, translate : Maybe ( String, String ), translateTransform : String } -> { a | rotate : String, scale : Maybe ( String, String ), skew : String, translate : Maybe ( String, String ), translateTransform : String }
applyTranslateRender maybeControlledAxes config acc =
    case controlledTranslateAxes maybeControlledAxes of
        Just axes ->
            if renderTranslateAsIndividualProperty axes then
                { acc | translate = Just ( "translate", translatePropertyValueForAxes axes config ) }

            else
                { acc | translateTransform = translateTransformForAxes axes config }

        Nothing ->
            { acc | translate = Just ( "translate", Translate.toCssPropertyValue config.cssUnit config.end ) }


controlledTranslateAxes : Maybe (Dict String (Set String)) -> Maybe (Set String)
controlledTranslateAxes maybeControlledAxes =
    maybeControlledAxes
        |> Maybe.andThen (Dict.get "translate")


renderTranslateAsIndividualProperty : Set String -> Bool
renderTranslateAsIndividualProperty axes =
    let
        hasX =
            Set.member "x" axes

        hasY =
            Set.member "y" axes

        hasZ =
            Set.member "z" axes
    in
    hasX && (hasY || not hasZ)


translatePropertyValueForAxes : Set String -> Builder.ProcessedAnimationConfig Translate.Translate -> String
translatePropertyValueForAxes axes config =
    if Set.size axes == 3 then
        Translate.toCssPropertyValue config.cssUnit config.end

    else
        let
            end =
                Translate.toRecord config.end

            xSuffix =
                InternalUnit.toCssSuffix config.cssUnit.x

            ySuffix =
                InternalUnit.toCssSuffix config.cssUnit.y
        in
        if Set.member "y" axes then
            String.fromFloat end.x ++ xSuffix ++ " " ++ String.fromFloat end.y ++ ySuffix

        else
            String.fromFloat end.x ++ xSuffix


translateTransformForAxes : Set String -> Builder.ProcessedAnimationConfig Translate.Translate -> String
translateTransformForAxes axes config =
    let
        end =
            Translate.toRecord config.end

        xSuffix =
            InternalUnit.toCssSuffix config.cssUnit.x

        ySuffix =
            InternalUnit.toCssSuffix config.cssUnit.y

        zSuffix =
            InternalUnit.toCssSuffix config.cssUnit.z
    in
    [ if Set.member "x" axes then
        Just ("translateX(" ++ String.fromFloat end.x ++ xSuffix ++ ")")

      else
        Nothing
    , if Set.member "y" axes then
        Just ("translateY(" ++ String.fromFloat end.y ++ ySuffix ++ ")")

      else
        Nothing
    , if Set.member "z" axes then
        Just ("translateZ(" ++ String.fromFloat end.z ++ zSuffix ++ ")")

      else
        Nothing
    ]
        |> List.filterMap identity
        |> String.join " "
