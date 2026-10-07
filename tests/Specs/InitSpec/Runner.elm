module Specs.InitSpec.Runner exposing
    ( TestCase(..)
    , TestData
    , run
    )

import Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
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
    = GeneralTest (GeneralTestCase animBuilder)
    | SizeTest (SizeTestCase animBuilder)
    | MultiPropertyTest (MultiPropertyTestCase animBuilder)
    | MultiGroupTest (MultiGroupTestCase animBuilder)


type alias GeneralTestCase animBuilder =
    { description : String
    , initFuncs : animBuilder -> animBuilder
    , expected : NameValuePair
    }


type alias SizeTestCase animBuilder =
    { description : String
    , initFuncs : animBuilder -> animBuilder
    , expectedHeight : Maybe String
    , expectedWidth : Maybe String
    , willChange : String
    }


type alias MultiPropertyTestCase animBuilder =
    { description : String
    , initFuncs : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    , willChange : String
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , animGroups : List String
    , initFuncs : List (List (animBuilder -> animBuilder))
    , expected : List (List NameValuePair)
    , willChange : List String
    }


run :
    EngineFactory animBuilder animState
    -> (String -> animState -> List (Html.Attribute msg))
    -> List (TestData animBuilder)
    -> List Test
run factory attributesFunc =
    List.map (runTestData factory attributesFunc)


runTestData : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> TestData animBuilder -> Test
runTestData factory attributesFunc td =
    describe td.description <|
        List.map (runTestCase factory attributesFunc) td.testCases


runTestCase :
    EngineFactory animBuilder animState
    -> (String -> animState -> List (Html.Attribute msg))
    -> TestCase animBuilder
    -> Test
runTestCase factory attributesFunc testCase =
    case testCase of
        GeneralTest tc ->
            generalRunner factory attributesFunc tc

        SizeTest tc ->
            sizeRunner factory attributesFunc tc

        MultiPropertyTest tc ->
            multiPropertyRunner factory attributesFunc tc

        MultiGroupTest tc ->
            multiGroupRunner factory attributesFunc tc


generalRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> GeneralTestCase animBuilder -> Test
generalRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory
            in
            f.init [ tc.initFuncs ]
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style tc.expected.name tc.expected.value
                    , Selector.style "will-change" tc.expected.name
                    ]


multiGroupRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> MultiGroupTestCase animBuilder -> Test
multiGroupRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            Expect.all
                (List.map4
                    (\init group expected willChange ->
                        \_ ->
                            let
                                f =
                                    Factory.create factory
                            in
                            f.init init
                                |> attributesQueryFor attributesFunc group
                                |> Query.has
                                    (Selector.style "will-change" willChange
                                        :: List.map
                                            (\nvp ->
                                                Selector.style nvp.name nvp.value
                                            )
                                            expected
                                    )
                    )
                    tc.initFuncs
                    tc.animGroups
                    tc.expected
                    tc.willChange
                )
                ()


multiPropertyRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> MultiPropertyTestCase animBuilder -> Test
multiPropertyRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory
            in
            f.init tc.initFuncs
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    (Selector.style "will-change" tc.willChange
                        :: List.map
                            (\nvp ->
                                Selector.style nvp.name nvp.value
                            )
                            tc.expected
                    )


sizeRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> SizeTestCase animBuilder -> Test
sizeRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory
            in
            f.init [ tc.initFuncs ]
                |> attributesQueryFor attributesFunc animGroup
                |> (\query ->
                        case ( tc.expectedHeight, tc.expectedWidth ) of
                            ( Just height, Just width ) ->
                                Query.has
                                    [ Selector.style "height" height
                                    , Selector.style "width" width
                                    , Selector.style "will-change" tc.willChange
                                    ]
                                    query

                            ( Just height, Nothing ) ->
                                Query.has
                                    [ Selector.style "height" height
                                    , Selector.style "will-change" tc.willChange
                                    ]
                                    query

                            ( Nothing, Just width ) ->
                                Query.has
                                    [ Selector.style "width" width
                                    , Selector.style "will-change" tc.willChange
                                    ]
                                    query

                            ( Nothing, Nothing ) ->
                                Query.has [] query
                   )
