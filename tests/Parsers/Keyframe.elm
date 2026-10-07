module Parsers.Keyframe exposing
    ( parseDuration
    , parseKeyframes
    )

import Parsers.Parser exposing (parseMs)


parseKeyframes : String -> String -> List ( Float, String )
parseKeyframes propertyName keyframes =
    keyframes
        |> String.lines
        |> List.foldl
            (parseProperty propertyName)
            { currentPercent = Nothing
            , keyframes = []
            }
        |> .keyframes
        |> List.reverse


parseProperty : String -> String -> { currentPercent : Maybe Float, keyframes : List ( Float, String ) } -> { currentPercent : Maybe Float, keyframes : List ( Float, String ) }
parseProperty propertyName line acc =
    let
        trimmed =
            String.trim line

        propertyPrefix =
            propertyName ++ ":"
    in
    if String.endsWith "% {" trimmed then
        { acc
            | currentPercent =
                trimmed
                    |> String.dropRight 3
                    |> String.toFloat
        }

    else if trimmed == "}" then
        { acc | currentPercent = Nothing }

    else if String.startsWith propertyPrefix trimmed then
        addCurrentPercentKeyframe
            (trimmed
                |> String.dropLeft (String.length propertyPrefix)
                |> String.trim
                |> removeTrailingSemicolon
            )
            acc

    else if String.startsWith "transform:" trimmed && isTransformComponent propertyName then
        case extractTransformComponent propertyName trimmed of
            Nothing ->
                acc

            Just componentValue ->
                addCurrentPercentKeyframe componentValue acc

    else
        acc


parseDuration : String -> Maybe Int
parseDuration animationString =
    case String.words animationString of
        _ :: duration :: _ ->
            parseMs duration

        _ ->
            Nothing


addCurrentPercentKeyframe : String -> { currentPercent : Maybe Float, keyframes : List ( Float, String ) } -> { currentPercent : Maybe Float, keyframes : List ( Float, String ) }
addCurrentPercentKeyframe value acc =
    case acc.currentPercent of
        Nothing ->
            acc

        Just percent ->
            { acc | keyframes = ( percent, value ) :: acc.keyframes }


removeTrailingSemicolon : String -> String
removeTrailingSemicolon raw =
    if String.endsWith ";" raw then
        String.dropRight 1 raw

    else
        raw


isTransformComponent : String -> Bool
isTransformComponent propertyName =
    List.member propertyName [ "translate", "scale", "rotate", "skew" ]


extractTransformComponent : String -> String -> Maybe String
extractTransformComponent propertyName transformLine =
    let
        transformValue =
            transformLine
                |> String.dropLeft (String.length "transform:")
                |> String.trim
                |> removeTrailingSemicolon

        prefixes =
            case propertyName of
                "translate" ->
                    [ "translate(", "translateX(", "translateY(", "translateZ(", "translate3d(" ]

                "scale" ->
                    [ "scale(", "scaleX(", "scaleY(", "scaleZ(", "scale3d(" ]

                "rotate" ->
                    [ "rotate(", "rotateX(", "rotateY(", "rotateZ(", "rotate3d(" ]

                "skew" ->
                    [ "skew(", "skewX(", "skewY(" ]

                _ ->
                    []

        components =
            transformValue
                |> String.words
                |> List.filter
                    (\component ->
                        List.any (\prefix -> String.startsWith prefix component) prefixes
                    )
    in
    if components == [] then
        Nothing

    else
        Just (String.join " " components)
