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

                    interiorSamples =
                        dropLast samples
                in
                containsNear 1 0.0000001 interiorSamples
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
