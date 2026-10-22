module Specs.DiscretePropertiesSpec.DiscreteEntrySpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Html
import Html.Attributes
import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData exposing (AnimateTestCase, InitTestCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)
import Specs.Shared.TimingProfile as TimingProfile
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


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
                    [ f.discreteEntry tc.discreteProperty tc.discreteValue
                    , f.seedInit animGroup
                    ]

                state =
                    Factory.animate factory animGroup initFuncs <|
                        TimingProfile.apply factory tc.timing <|
                            f.seedAnimation animGroup
            in
            case factory of
                Keyframe f_ ->
                    let
                        expected =
                            [ NameValuePair tc.discreteProperty tc.discreteValue ]
                    in
                    Expect.styles expected f_.attributes animGroup state

                Transition f_ ->
                    let
                        expected =
                            [ NameValuePair tc.discreteProperty tc.discreteValue ]
                    in
                    Expect.styles expected f_.attributes animGroup state


animateRunner : EngineFactory animBuilder animState -> AnimateTestCase -> Test
animateRunner factory tc =
    test (tc.description ++ TimingProfile.suffix tc.timing) <|
        \_ ->
            let
                f =
                    Factory.create factory

                state =
                    Factory.animate factory animGroup [] <|
                        TimingProfile.apply factory tc.timing <|
                            f.discreteEntry tc.discreteProperty tc.discreteValue
                                >> f.seedAnimation animGroup
            in
            case factory of
                Keyframe f_ ->
                    expectKeyframeDefinesDiscreteEntry tc.timing f_ animGroup tc.discreteProperty tc.discreteValue state

                Transition f_ ->
                    Expect.all
                        [ \_ ->
                            expectTransitionStartingStyleMode f_.attributes animGroup state
                        , \_ ->
                            expectTransitionStartingStyleContainsDiscrete f_.startingStyleNodeFor animGroup tc.discreteProperty tc.discreteValue state
                        , \_ ->
                            expectTransitionStartingStyleHasTransition f_.startingStyleNodeFor animGroup state
                        ]
                        ()


expectKeyframeDefinesDiscreteEntry :
    TimingProfile.TimingProfile
    -> { a | keyframesString : String -> animState -> Maybe String }
    -> String
    -> String
    -> String
    -> animState
    -> Expect.Expectation
expectKeyframeDefinesDiscreteEntry timing f animGroupName discreteProperty discreteValue state =
    case f.keyframesString animGroupName state of
        Nothing ->
            case timing of
                TimingProfile.NoTiming ->
                    Expect.pass

                _ ->
                    Expect.fail "Expected generated keyframes CSS, but none was produced"

        Just keyframesCss ->
            let
                discreteTokenNoSpace =
                    discreteProperty ++ ":" ++ discreteValue

                discreteTokenWithSpace =
                    discreteProperty ++ ": " ++ discreteValue
            in
            if String.contains discreteTokenNoSpace keyframesCss || String.contains discreteTokenWithSpace keyframesCss then
                Expect.pass

            else
                Expect.fail ("Expected keyframes CSS to contain \"" ++ discreteTokenNoSpace ++ "\" but got: " ++ keyframesCss)


expectTransitionStartingStyleMode :
    (String -> animState -> List (Html.Attribute msg))
    -> String
    -> animState
    -> Expect.Expectation
expectTransitionStartingStyleMode attributesFn animGroupName state =
    Html.div (attributesFn animGroupName state) []
        |> Query.fromHtml
        |> Query.has
            [ Selector.attribute (Html.Attributes.attribute "data-anim-group-name" animGroupName) ]


expectTransitionStartingStyleContainsDiscrete :
    (String -> animState -> Html.Html Never)
    -> String
    -> String
    -> String
    -> animState
    -> Expect.Expectation
expectTransitionStartingStyleContainsDiscrete startingStyleNodeFn animGroupName discreteProperty discreteValue state =
    let
        tokenWithSpace =
            discreteProperty ++ ": " ++ discreteValue
    in
    startingStyleNodeFn animGroupName state
        |> Query.fromHtml
        |> Query.has
            [ Selector.tag "style"
            , Selector.text tokenWithSpace
            ]


expectTransitionStartingStyleHasTransition :
    (String -> animState -> Html.Html Never)
    -> String
    -> animState
    -> Expect.Expectation
expectTransitionStartingStyleHasTransition startingStyleNodeFn animGroupName state =
    startingStyleNodeFn animGroupName state
        |> Query.fromHtml
        |> Query.has
            [ Selector.tag "style"
            , Selector.text "transition:"
            ]
