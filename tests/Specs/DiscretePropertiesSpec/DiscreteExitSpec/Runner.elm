module Specs.DiscretePropertiesSpec.DiscreteExitSpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Html
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (ExitIsolationTestConfig, ExitTestConfig, TestCase(..), TestData)
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

        AnimateCompleteTest tc ->
            animateCompleteRunner factory tc

        Animate2Test tc ->
            animate2Runner factory tc

        AnimateCompleteAnimateTest tc ->
            animateCompleteAnimateRunner factory tc

        AnimateIsolationTest tc ->
            animateIsolationRunner factory tc

        RetargetIsolationTest tc ->
            retargetIsolationRunner factory tc

        NoOpAfterCompleteTest tc ->
            noOpAfterCompleteRunner factory tc


initRunner : EngineFactory animBuilder animState -> ExitTestConfig -> Test
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


animateRunner : EngineFactory animBuilder animState -> ExitTestConfig -> Test
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


animateCompleteRunner : EngineFactory animBuilder animState -> ExitTestConfig -> Test
animateCompleteRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                expected =
                    [ NameValuePair tc.discreteProperty tc.toValue ]

                stateBeforeCompletion =
                    Factory.animate factory animGroup [] <|
                        TimingProfile.apply factory tc.timing <|
                            f.discreteExit tc.discreteProperty tc.fromValue tc.toValue
                                >> f.seedAnimation animGroup
            in
            case f.complete animGroup stateBeforeCompletion of
                Err message ->
                    Expect.fail message

                Ok completedState ->
                    case factory of
                        Keyframe f_ ->
                            Expect.styles expected f_.attributes animGroup completedState

                        Transition f_ ->
                            Expect.styles expected f_.attributes animGroup completedState


animate2Runner : EngineFactory animBuilder animState -> ExitTestConfig -> Test
animate2Runner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                animateWithDiscreteExit =
                    TimingProfile.apply factory tc.timing <|
                        f.discreteExit tc.discreteProperty tc.fromValue tc.toValue
                            >> f.seedAnimation animGroup

                state =
                    Factory.animate2 factory animGroup [] animateWithDiscreteExit animateWithDiscreteExit
            in
            case factory of
                Keyframe f_ ->
                    Expect.styles
                        [ NameValuePair tc.discreteProperty (expectedDiscreteValue tc.timing tc.fromValue tc.toValue) ]
                        f_.attributes
                        animGroup
                        state

                Transition f_ ->
                    -- The first transition is still in flight (no transitionend
                    -- has arrived) so the exit `from` value must be held.
                    Expect.styles
                        [ NameValuePair tc.discreteProperty tc.fromValue ]
                        f_.attributes
                        animGroup
                        state


animateCompleteAnimateRunner : EngineFactory animBuilder animState -> ExitTestConfig -> Test
animateCompleteAnimateRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                animateWithDiscreteExit =
                    TimingProfile.apply factory tc.timing <|
                        f.discreteExit tc.discreteProperty tc.fromValue tc.toValue
                            >> f.seedAnimation animGroup

                stateBeforeCompletion =
                    Factory.animate factory animGroup [] animateWithDiscreteExit
            in
            case f.complete animGroup stateBeforeCompletion of
                Err message ->
                    Expect.fail message

                Ok completedState ->
                    let
                        -- Identical output after completion won't start a new CSS
                        -- transition, so the group must settle as Complete and
                        -- render the exit `to` value rather than get stuck Running.
                        state =
                            f.animate completedState <|
                                f.for animGroup
                                    >> animateWithDiscreteExit
                    in
                    case factory of
                        Keyframe f_ ->
                            Expect.styles
                                [ NameValuePair tc.discreteProperty (expectedDiscreteValue tc.timing tc.fromValue tc.toValue) ]
                                f_.attributes
                                animGroup
                                state

                        Transition f_ ->
                            Expect.styles
                                [ NameValuePair tc.discreteProperty tc.toValue ]
                                f_.attributes
                                animGroup
                                state


animateIsolationRunner : EngineFactory animBuilder animState -> ExitIsolationTestConfig -> Test
animateIsolationRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                stateAfterSubjectAnimate =
                    f.init [ f.seedInit tc.subjectGroup, f.seedInit tc.bystanderGroup ]
                        |> (\s ->
                                f.animate s <|
                                    f.for tc.subjectGroup
                                        >> applyDiscreteExit f tc
                           )
            in
            case completeSubjectWhenTimed tc f stateAfterSubjectAnimate of
                Err message ->
                    Expect.fail message

                Ok settledState ->
                    let
                        state =
                            f.animate settledState <|
                                f.for tc.bystanderGroup
                                    >> animateBystander f tc

                        expectedSubjectValue =
                            case factory of
                                Keyframe _ ->
                                    tc.fromValue

                                Transition _ ->
                                    tc.toValue
                    in
                    Expect.all
                        [ \_ -> expectDiscreteStyle f tc state expectedSubjectValue
                        , \_ -> f.isRunning tc.bystanderGroup state |> Expect.equal (Just True)
                        ]
                        ()


retargetIsolationRunner : EngineFactory animBuilder animState -> ExitIsolationTestConfig -> Test
retargetIsolationRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                stateAfterSubjectAnimate =
                    f.init [ f.seedInit tc.subjectGroup, f.seedInit tc.bystanderGroup ]
                        |> (\s ->
                                f.animate s <|
                                    f.for tc.subjectGroup
                                        >> applyDiscreteExit f tc
                           )
            in
            case completeSubjectWhenTimed tc f stateAfterSubjectAnimate of
                Err message ->
                    Expect.fail message

                Ok settledState ->
                    let
                        stateAfterBystanderAnimate =
                            f.animate settledState <|
                                f.for tc.bystanderGroup
                                    >> animateBystander f tc

                        state =
                            f.retarget stateAfterBystanderAnimate <|
                                f.for tc.bystanderGroup
                                    >> animateBystander f tc

                        expectedSubjectValue =
                            case factory of
                                Keyframe _ ->
                                    tc.fromValue

                                Transition _ ->
                                    tc.toValue
                    in
                    Expect.all
                        [ \_ -> expectDiscreteStyle f tc state expectedSubjectValue ]
                        ()


noOpAfterCompleteRunner : EngineFactory animBuilder animState -> ExitIsolationTestConfig -> Test
noOpAfterCompleteRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                stateAfterSubjectAnimate =
                    f.init [ f.seedInit tc.subjectGroup, f.seedInit tc.bystanderGroup ]
                        |> (\s ->
                                f.animate s <|
                                    f.for tc.subjectGroup
                                        >> applyDiscreteExit f tc
                           )
            in
            case completeSubjectWhenTimed tc f stateAfterSubjectAnimate of
                Err message ->
                    Expect.fail message

                Ok settledState ->
                    let
                        state =
                            f.animate settledState <|
                                f.for tc.subjectGroup
                                    >> applyDiscreteExit f tc
                    in
                    case tc.timing of
                        TimingProfile.NoTiming ->
                            expectDiscreteStyle f tc state tc.toValue

                        _ ->
                            case factory of
                                Keyframe _ ->
                                    Expect.all
                                        [ \_ -> f.isRunning tc.subjectGroup state |> Expect.equal (Just True)
                                        , \_ -> expectDiscreteStyle f tc state tc.fromValue
                                        ]
                                        ()

                                Transition _ ->
                                    Expect.all
                                        [ \_ -> f.isComplete tc.subjectGroup state |> Expect.equal (Just True)
                                        , \_ -> expectDiscreteStyle f tc state tc.toValue
                                        ]
                                        ()


expectedDiscreteValue : TimingProfile.TimingProfile -> String -> String -> String
expectedDiscreteValue timing fromValue toValue =
    case timing of
        TimingProfile.NoTiming ->
            toValue

        TimingProfile.DelayMs _ ->
            fromValue

        TimingProfile.DurationMs _ ->
            fromValue


applyDiscreteExit :
    { a
        | discreteExit : String -> String -> String -> builder -> builder
        , seedAnimation : String -> builder -> builder
        , delay : Int -> builder -> builder
        , duration : Int -> builder -> builder
    }
    -> ExitIsolationTestConfig
    -> builder
    -> builder
applyDiscreteExit f tc =
    applyTiming tc.timing f <|
        f.discreteExit tc.discreteProperty tc.fromValue tc.toValue
            >> f.seedAnimation tc.subjectGroup


animateBystander :
    { a
        | seedAnimation : String -> builder -> builder
        , duration : Int -> builder -> builder
    }
    -> ExitIsolationTestConfig
    -> builder
    -> builder
animateBystander f tc =
    f.duration 300
        >> f.seedAnimation tc.bystanderGroup


completeSubjectWhenTimed :
    ExitIsolationTestConfig
    -> { a | complete : String -> state -> Result String state }
    -> state
    -> Result String state
completeSubjectWhenTimed tc f state =
    case tc.timing of
        TimingProfile.NoTiming ->
            Ok state

        _ ->
            f.complete tc.subjectGroup state


applyTiming :
    TimingProfile.TimingProfile
    ->
        { a
            | delay : Int -> builder -> builder
            , duration : Int -> builder -> builder
        }
    -> (builder -> builder)
    -> (builder -> builder)
applyTiming timing f builder =
    case timing of
        TimingProfile.NoTiming ->
            builder

        TimingProfile.DelayMs delayMs ->
            f.delay delayMs
                >> builder

        TimingProfile.DurationMs durationMs ->
            f.duration durationMs
                >> builder


expectDiscreteStyle :
    { a | attributes : String -> state -> List (Html.Attribute Never) }
    -> ExitIsolationTestConfig
    -> state
    -> String
    -> Expect.Expectation
expectDiscreteStyle f tc state expectedValue =
    Expect.styles
        [ NameValuePair tc.discreteProperty expectedValue ]
        f.attributes
        tc.subjectGroup
        state
