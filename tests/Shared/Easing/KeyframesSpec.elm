module Shared.Easing.KeyframesSpec exposing (suite)

import Expect
import Motion.Easing exposing (Easing(..))
import Shared.Easing.Keyframes as Keyframes
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Shared.Easing.Keyframes bounce critical-point sampling"
        [ test "BounceOut includes an interior endpoint-impact sample" <|
            \_ ->
                let
                    samples =
                        Keyframes.generateKeyframes BounceOut 300

                    interiorValues =
                        samples
                            |> List.map .value
                            |> dropLast
                in
                containsNear 1 0.0000001 interiorValues
                    |> Expect.equal True
        , test "bounce keyframes include extra critical-point samples" <|
            \_ ->
                let
                    bounceOutCount =
                        Keyframes.generateKeyframes BounceOut 300
                            |> List.length

                    bounceInOutCount =
                        Keyframes.generateKeyframes BounceInOut 300
                            |> List.length
                in
                ( bounceOutCount > Keyframes.defaultKeyframeCount
                , bounceInOutCount > Keyframes.defaultKeyframeCount
                )
                    |> Expect.equal ( True, True )
        , test "elastic sampling remains uniform" <|
            \_ ->
                Keyframes.generateKeyframes ElasticOut 300
                    |> List.length
                    |> Expect.equal Keyframes.defaultKeyframeCount
        , test "samples carry their true time offsets, sorted on [0, 1]" <|
            \_ ->
                let
                    offsets =
                        Keyframes.generateKeyframes BounceOut 300
                            |> List.map .offset
                in
                ( List.head offsets
                , List.head (List.reverse offsets)
                , isSorted offsets
                )
                    |> Expect.equal ( Just 0, Just 1, True )
        , test "BounceOut samples include the 1/2.75 piece boundary as an offset" <|
            \_ ->
                Keyframes.generateKeyframes BounceOut 300
                    |> List.map .offset
                    |> containsNear (1 / 2.75) 0.0000001
                    |> Expect.equal True
        ]


containsNear : Float -> Float -> List Float -> Bool
containsNear target epsilon values =
    List.any (\v -> abs (v - target) <= epsilon) values


dropLast : List a -> List a
dropLast list =
    list
        |> List.reverse
        |> List.drop 1
        |> List.reverse


isSorted : List Float -> Bool
isSorted xs =
    case xs of
        [] ->
            True

        first :: rest ->
            List.foldl
                (\next ( prev, ok ) ->
                    ( next, ok && next >= prev )
                )
                ( first, True )
                rest
                |> Tuple.second
