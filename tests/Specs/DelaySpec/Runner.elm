module Specs.DelaySpec.Runner exposing (..)

import Factories.Engines.Factory as Factory exposing (Factory(..))
import Factories.Engines.Keyframe as KeyframeFactory
import Helpers.AnimGroups exposing (animGroup)
import Html
import Specs.Shared exposing (NameValuePair, attributesQueryFor)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TestCase animBuilder
    = PropertyTest (PropertyTestCase animBuilder)
    | EngineTest (EngineTestCase animBuilder)


type alias PropertyTestCase animBuilder =
    { description : String
    , animateFuncs : animBuilder -> animBuilder
    , transitionExpected : NameValuePair
    , keyframeExpected : String
    }


type alias EngineTestCase animBuilder =
    { description : String
    , delayMs : Int
    , animateFuncs : animBuilder -> animBuilder
    , transitionExpected : NameValuePair
    , keyframeExpected : String
    }


run :
    Factory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> List (TestData animBuilder)
    -> List Test
run factory attributesFunc =
    List.map (runTestData factory attributesFunc)


runTestData :
    Factory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> TestData animBuilder
    -> Test
runTestData factory attributesFunc td =
    describe td.description <|
        List.map (runTestCase factory attributesFunc) td.testCases


runTestCase :
    Factory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> TestCase animBuilder
    -> Test
runTestCase factory attributesFunc testCase =
    case testCase of
        PropertyTest tc ->
            propertyRunner factory attributesFunc tc

        EngineTest tc ->
            engineRunner factory attributesFunc tc


propertyRunner : Factory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> PropertyTestCase animBuilder -> Test
propertyRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.animateFactory factory

                state =
                    f.init []
                        |> (\initialState ->
                                f.animate initialState <|
                                    f.for animGroup
                                        >> tc.animateFuncs
                           )
            in
            case factory of
                Keyframe f_ ->
                    let
                        animationString =
                            state
                                |> KeyframeFactory.createAnimation f_.keyframesString animGroup
                                |> KeyframeFactory.withDuration tc.keyframeExpected
                                |> KeyframeFactory.animationToString
                    in
                    state
                        |> attributesQueryFor attributesFunc animGroup
                        |> Query.has [ Selector.style "animation" animationString ]

                Transition _ ->
                    state
                        |> attributesQueryFor attributesFunc animGroup
                        |> Query.has
                            [ Selector.style tc.transitionExpected.name tc.transitionExpected.value ]


engineRunner : Factory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> EngineTestCase animBuilder -> Test
engineRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.delayFactory factory

                state =
                    f.init []
                        |> (\initialState ->
                                f.animate initialState <|
                                    f.for animGroup
                                        >> f.delay tc.delayMs
                                        >> tc.animateFuncs
                           )
            in
            case factory of
                Keyframe f_ ->
                    let
                        animationString =
                            state
                                |> KeyframeFactory.createAnimation f_.keyframesString animGroup
                                |> KeyframeFactory.withDuration tc.keyframeExpected
                                |> KeyframeFactory.animationToString
                    in
                    state
                        |> attributesQueryFor attributesFunc animGroup
                        |> Query.has [ Selector.style "animation" animationString ]

                Transition _ ->
                    state
                        |> attributesQueryFor attributesFunc animGroup
                        |> Query.has
                            [ Selector.style tc.transitionExpected.name tc.transitionExpected.value ]
