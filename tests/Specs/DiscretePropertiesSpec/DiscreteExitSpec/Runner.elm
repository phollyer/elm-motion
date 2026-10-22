module Specs.DiscretePropertiesSpec.DiscreteExitSpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (AnimateTestCase, InitTestCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)
import Specs.Shared.TimingProfile as TimingProfile
import Test exposing (Test, describe, test)


run : EngineFactory animBuilder animState -> List TestData -> List Test
run factory =
    List.map (runTestData factory)


runTestData : EngineFactory animBuilder animState -> TestData -> Test
runTestData factory td =
    describe td.description <|
        List.map (runTestCase factory) td.testCases


runTestCase : EngineFactory animBuilder animState -> TestCase -> Test
runTestCase factory testCase =
    case testCase of
        InitTest tc ->
            initRunner factory tc

        AnimateTest tc ->
            animateRunner factory tc


initRunner : EngineFactory animBuilder animState -> InitTestCase -> Test
initRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                initFuncs =
                    [ f.discreteExit tc.discreteProperty tc.fromValue tc.toValue
                    , f.seedInit animGroup
                    ]

                state =
                    Factory.animate factory animGroup initFuncs <|
                        TimingProfile.apply factory tc.timing <|
                            f.seedAnimation animGroup
            in
            case factory of
                Keyframe f_ ->
                    Expect.equal Nothing (f_.styleValue animGroup tc.discreteProperty state)

                Transition f_ ->
                    Expect.equal Nothing (f_.styleValue animGroup tc.discreteProperty state)


animateRunner : EngineFactory animBuilder animState -> AnimateTestCase -> Test
animateRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                expected =
                    [ NameValuePair tc.discreteProperty <|
                        expectedDiscreteValue tc.timing tc.fromValue tc.toValue
                    ]

                state =
                    Factory.animate factory animGroup [] <|
                        TimingProfile.apply factory tc.timing <|
                            f.discreteExit tc.discreteProperty tc.fromValue tc.toValue
                                >> f.seedAnimation animGroup
            in
            case factory of
                Keyframe f_ ->
                    Expect.styles expected f_.attributes animGroup state

                Transition f_ ->
                    Expect.styles expected f_.attributes animGroup state


expectedDiscreteValue : TimingProfile.TimingProfile -> String -> String -> String
expectedDiscreteValue timing fromValue toValue =
    case timing of
        TimingProfile.NoTiming ->
            toValue

        TimingProfile.DelayMs _ ->
            fromValue

        TimingProfile.DurationMs _ ->
            fromValue
