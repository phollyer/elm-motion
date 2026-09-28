module Anim.Internal.Engine.CSS.Transform exposing
    ( extractParts
    , generateComponents
    , toStyle
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles
import Anim.Internal.Property.Scale as Scale
import Dict exposing (Dict)
import Set exposing (Set)


generateComponents : Maybe (List TransformProperty) -> Builder.TransformParts -> List String
generateComponents maybeOrder transformParts =
    let
        ordered =
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
    in
    List.filter (String.isEmpty >> not) ordered


type alias TransformParts =
    { rotate : String
    , scale : String
    , skew : String
    , translate : String
    }


extractParts : Maybe (Dict String (Set String)) -> List Builder.ProcessedPropertyConfig -> TransformParts
extractParts maybeControlledAxes properties =
    List.foldl
        (\property acc ->
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { acc | translate = Styles.translateToCss maybeControlledAxes config.cssUnit config.end }

                Builder.ProcessedRotateConfig config ->
                    { acc | rotate = Styles.rotateToCss maybeControlledAxes config.end }

                Builder.ProcessedSkewConfig config ->
                    { acc | skew = Styles.skewToCss maybeControlledAxes config.end }

                Builder.ProcessedScaleConfig config ->
                    { acc | scale = Scale.toCssString config.end }

                _ ->
                    acc
        )
        Builder.emptyTransformParts
        properties


toStyle : Maybe (List TransformProperty) -> Builder.TransformParts -> Maybe ( String, String )
toStyle maybeOrder transformParts =
    let
        value =
            toCssString maybeOrder transformParts
    in
    if String.isEmpty value then
        Nothing

    else
        Just ( "transform", value )


toCssString : Maybe (List TransformProperty) -> Builder.TransformParts -> String
toCssString maybeOrder transformParts =
    generateComponents maybeOrder transformParts
        |> String.join " "
