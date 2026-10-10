module Specs.DelaySpec.Runner exposing (run)

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Factories.Engines.Keyframe as Keyframe
import Factories.Engines.Transition as Transition
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Properties as Properties
import Parsers.Keyframe as KeyframeParser
import Specs.DelaySpec.TestData exposing (EngineTestCase, MultiPropertyTestCase, MultiPropertyTransformOrderTestCase, PropertyTestCase, TestCase(..), TestData)
import Test exposing (Test, describe, test)


run :
    EngineFactory animBuilder state
    -> List (TestData animBuilder)
    -> List Test
run factory =
    List.map (runTestData factory)


runTestData :
    EngineFactory animBuilder state
    -> TestData animBuilder
    -> Test
runTestData factory td =
    describe td.description <|
        List.map (runTestCase factory) td.testCases


runTestCase :
    EngineFactory animBuilder state
    -> TestCase animBuilder
    -> Test
runTestCase factory testCase =
    case testCase of
        PropertyTest tc ->
            propertyRunner factory tc

        EngineTest tc ->
            engineRunner factory tc

        MultiPropertyTest tc ->
            multiPropertyRunner factory tc

        MultiPropertyTransformOrderTest tc ->
            multiPropertyTransformOrderRunner factory tc


propertyRunner : EngineFactory animBuilder animState -> PropertyTestCase animBuilder -> Test
propertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                state =
                    Factory.animate factory animGroup [] tc.propertyPipeline
            in
            case factory of
                Keyframe f ->
                    expectKeyframeDelay f tc state

                Transition f ->
                    expectTransitionPropertyDelay f tc state


engineRunner : EngineFactory animBuilder animState -> EngineTestCase animBuilder -> Test
engineRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                state =
                    Factory.animate factory animGroup [] <|
                        f.delay tc.delayMs
                            >> tc.propertyPipeline
            in
            case factory of
                Keyframe f_ ->
                    expectKeyframeDelay f_ tc state

                Transition f_ ->
                    expectTransitionPropertyDelay f_ tc state


multiPropertyRunner : EngineFactory animBuilder animState -> MultiPropertyTestCase animBuilder -> Test
multiPropertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                state =
                    Factory.animate factory animGroup [] <|
                        List.foldl (\prop acc -> acc >> prop.propertyPipeline) identity tc.properties
            in
            case factory of
                Keyframe f ->
                    Expect.all
                        (List.map
                            (\prop _ ->
                                expectKeyframeDelay f prop state
                            )
                            tc.properties
                        )
                        ()

                Transition f ->
                    expectTransitionMultiPropertyDelay f [] tc.properties state


multiPropertyTransformOrderRunner : EngineFactory animBuilder animState -> MultiPropertyTransformOrderTestCase animBuilder -> Test
multiPropertyTransformOrderRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                state =
                    Factory.build f [] <|
                        f.for animGroup
                            >> f.transformOrder tc.transformOrder
                            >> List.foldl (\prop acc -> acc >> prop.propertyPipeline) identity tc.properties
            in
            case factory of
                Keyframe f_ ->
                    Expect.all
                        (List.map
                            (\prop _ ->
                                expectKeyframeDelay f_ prop state
                            )
                            tc.properties
                        )
                        ()

                Transition f_ ->
                    expectTransitionMultiPropertyDelay f_ tc.transformOrder tc.properties state


expectTransitionPropertyDelay : Transition.Factory animBuilder animState -> PropertyTestCase animBuilder -> animState -> Expect.Expectation
expectTransitionPropertyDelay factory tc state =
    case factory.transitionString animGroup state of
        Nothing ->
            Expect.fail "Expected generated transition style, but none was produced"

        Just transitionString ->
            Expect.all
                [ \_ ->
                    Expect.transition transitionString factory.attributes animGroup state
                , \_ ->
                    case factory.propertyString tc.propertyName transitionString of
                        Nothing ->
                            Expect.fail ("Expected property string for property: " ++ tc.propertyName ++ ", but got: " ++ transitionString)

                        Just propertyString ->
                            let
                                delaySuffix =
                                    String.fromInt tc.delayMs ++ "ms"
                            in
                            if not <| String.endsWith delaySuffix propertyString then
                                Expect.fail ("Expected property string to end with delay suffix: " ++ delaySuffix ++ ", but got: " ++ propertyString)

                            else
                                Expect.pass
                ]
                ()


expectTransitionMultiPropertyDelay : Transition.Factory animBuilder animState -> List TransformProperty -> List (PropertyTestCase animBuilder) -> animState -> Expect.Expectation
expectTransitionMultiPropertyDelay factory transformOrder properties state =
    let
        transformProperties =
            Properties.transformOnly properties

        nonTransforms =
            Properties.nonTransformOnly properties
    in
    Expect.all
        [ \_ ->
            if List.isEmpty nonTransforms then
                Expect.pass

            else
                Expect.all
                    (List.map
                        (\prop _ ->
                            expectTransitionPropertyDelay factory prop state
                        )
                        nonTransforms
                    )
                    ()
        , if List.isEmpty transformProperties then
            \_ -> Expect.pass

          else
            \_ ->
                case factory.transitionString animGroup state of
                    Nothing ->
                        Expect.fail "Expected generated transition style, but none was produced"

                    Just transitionString ->
                        Expect.all
                            [ \_ ->
                                Expect.transition transitionString factory.attributes animGroup state
                            , \_ ->
                                if not <| String.startsWith "transform" transitionString then
                                    Expect.fail ("Expected transition string to start with: transform, but got: " ++ transitionString)

                                else
                                    Expect.pass
                            , \_ ->
                                let
                                    maybeTargetDelay =
                                        Properties.toTransformOrder transformOrder transformProperties
                                            |> List.map .delayMs
                                            |> List.head
                                in
                                case maybeTargetDelay of
                                    Nothing ->
                                        Expect.fail "Expected a transform delay, but none was configured"

                                    Just delayMs ->
                                        let
                                            delaySuffix =
                                                String.fromInt delayMs ++ "ms"
                                        in
                                        if not <| String.endsWith delaySuffix transitionString then
                                            Expect.fail ("Expected transition string to end with delay suffix: " ++ delaySuffix ++ ", but got: " ++ transitionString)

                                        else
                                            Expect.pass
                            ]
                            ()
        ]
        ()


expectKeyframeDelay : Keyframe.Factory animBuilder animState -> PropertyTestCase animBuilder -> animState -> Expect.Expectation
expectKeyframeDelay factory tc state =
    let
        maybeAnimationString =
            factory.animationString animGroup state

        maybeKeyframesString =
            factory.keyframesString animGroup state
    in
    case ( maybeAnimationString, maybeKeyframesString ) of
        ( Nothing, Nothing ) ->
            Expect.fail "Expected generated animation style and @keyframes CSS, but neither was produced"

        ( Nothing, _ ) ->
            Expect.fail "Expected generated animation style, but none was produced"

        ( _, Nothing ) ->
            Expect.fail "Expected generated @keyframes CSS, but none was produced"

        ( Just animationString, Just keyframesString ) ->
            case KeyframeParser.parseDuration animationString of
                Nothing ->
                    Expect.fail ("Expected animation duration in style string, got: " ++ animationString)

                Just totalDurationMs ->
                    if totalDurationMs <= 0 then
                        Expect.fail ("Expected positive keyframe duration, got: " ++ String.fromInt totalDurationMs)

                    else
                        let
                            keyframes =
                                KeyframeParser.parseKeyframes tc.propertyName keyframesString

                            thresholdPercent =
                                toFloat tc.delayMs
                                    / toFloat totalDurationMs
                                    * 100

                            beforeThresholdCount =
                                keyframes
                                    |> List.filter (\( percent, _ ) -> percent <= thresholdPercent)
                                    |> List.length

                            leadingStartCount =
                                countLeadingSameValues keyframes
                        in
                        Expect.all
                            [ \_ ->
                                if keyframes /= [] then
                                    Expect.pass

                                else
                                    Expect.fail "Expected non-empty keyframes"
                            , \_ ->
                                if leadingStartCount == beforeThresholdCount || leadingStartCount == beforeThresholdCount - 1 then
                                    Expect.pass

                                else
                                    Expect.fail ("Expected leadingStartCount to be equal to beforeThresholdCount or beforeThresholdCount - 1, but got: " ++ String.fromInt leadingStartCount ++ " vs " ++ String.fromInt beforeThresholdCount)
                            ]
                            ()


countLeadingSameValues : List ( Float, String ) -> Int
countLeadingSameValues samples =
    case samples of
        [] ->
            0

        ( _, startValue ) :: _ ->
            countLeadingValue startValue samples


countLeadingValue : String -> List ( Float, String ) -> Int
countLeadingValue startValue samples =
    case samples of
        [] ->
            0

        ( _, value ) :: remaining ->
            if value == startValue then
                1 + countLeadingValue startValue remaining

            else
                0
