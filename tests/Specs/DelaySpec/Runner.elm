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
import Specs.DelaySpec.TestData exposing (EngineTestCase, MultiGroupTestCase, MultiPropertyTestCase, MultiPropertyTransformOrderTestCase, PropertyTestCase, TestCase(..), TestData)
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

        MultiGroupTest tc ->
            multiGroupRunner factory tc


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
                    expectKeyframeDelayForGroup f animGroup tc state

                Transition f ->
                    expectTransitionDelayForGroup f animGroup tc state


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
                    expectKeyframeDelayForGroup f_ animGroup tc state

                Transition f_ ->
                    expectTransitionDelayForGroup f_ animGroup tc state


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
                    expectKeyframeMultiPropertyDelaysForGroup f animGroup tc.properties state

                Transition f ->
                    expectTransitionMultiPropertyDelaysForGroup f animGroup [] tc.properties state


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
                    expectKeyframeMultiPropertyDelaysForGroup f_ animGroup tc.properties state

                Transition f_ ->
                    expectTransitionMultiPropertyDelaysForGroup f_ animGroup tc.transformOrder tc.properties state


multiGroupRunner : EngineFactory animBuilder animState -> MultiGroupTestCase animBuilder -> Test
multiGroupRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                state =
                    List.foldl
                        (\group acc ->
                            f.animate acc <|
                                f.for group.animGroup
                                    >> group.property.propertyPipeline
                        )
                        (f.init [])
                        tc.groups
            in
            Expect.all
                (List.map
                    (\group _ ->
                        case factory of
                            Keyframe f_ ->
                                expectKeyframeDelayForGroup f_ group.animGroup group.property state

                            Transition f_ ->
                                expectTransitionDelayForGroup f_ group.animGroup group.property state
                    )
                    tc.groups
                )
                ()


expectTransitionDelayForGroup : Transition.Factory animBuilder animState -> String -> { a | propertyName : String, delayMs : Int } -> animState -> Expect.Expectation
expectTransitionDelayForGroup factory animGroupName { propertyName, delayMs } state =
    case factory.transitionString animGroupName state of
        Nothing ->
            Expect.fail "Expected generated transition style, but none was produced"

        Just transitionString ->
            Expect.all
                [ \_ ->
                    Expect.transition transitionString factory.attributes animGroupName state
                , \_ ->
                    case factory.propertyString propertyName transitionString of
                        Nothing ->
                            Expect.fail ("Expected property string for property: " ++ propertyName ++ ", but got: " ++ transitionString)

                        Just propertyString ->
                            let
                                delaySuffix =
                                    String.fromInt delayMs ++ "ms"
                            in
                            if not <| String.endsWith delaySuffix propertyString then
                                Expect.fail ("Expected string to end with delay suffix: " ++ delaySuffix ++ ", but got: " ++ propertyString)

                            else
                                Expect.pass
                ]
                ()


expectTransitionMultiPropertyDelaysForGroup : Transition.Factory animBuilder animState -> String -> List TransformProperty -> List (PropertyTestCase animBuilder) -> animState -> Expect.Expectation
expectTransitionMultiPropertyDelaysForGroup factory animGroupName transformOrder properties state =
    let
        transformProperties =
            Properties.transformOnly properties

        nonTransforms =
            Properties.nonTransformOnly properties

        expectTransformDelay =
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
                    expectTransitionDelayForGroup factory animGroupName { propertyName = "transform", delayMs = delayMs } state

        expectNonTransformDelays =
            Expect.all
                (List.map
                    (\prop _ ->
                        expectTransitionDelayForGroup factory animGroupName prop state
                    )
                    nonTransforms
                )
                ()
    in
    case ( transformProperties, nonTransforms ) of
        ( [], [] ) ->
            Expect.fail "Expected at least one property, but none were provided"

        ( _, [] ) ->
            expectTransformDelay

        ( [], _ ) ->
            expectNonTransformDelays

        _ ->
            Expect.all
                [ \_ ->
                    expectTransformDelay
                , \_ ->
                    expectNonTransformDelays
                ]
                ()


expectKeyframeMultiPropertyDelaysForGroup : Keyframe.Factory animBuilder animState -> String -> List (PropertyTestCase animBuilder) -> animState -> Expect.Expectation
expectKeyframeMultiPropertyDelaysForGroup factory animGroupName propertyTestCases state =
    Expect.all
        (List.map
            (\prop _ ->
                expectKeyframeDelayForGroup factory animGroupName prop state
            )
            propertyTestCases
        )
        ()


expectKeyframeDelayForGroup : Keyframe.Factory animBuilder animState -> String -> PropertyTestCase animBuilder -> animState -> Expect.Expectation
expectKeyframeDelayForGroup factory animGroupName tc state =
    let
        maybeAnimationString =
            factory.animationString animGroupName state

        maybeKeyframesString =
            factory.keyframesString animGroupName state
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
