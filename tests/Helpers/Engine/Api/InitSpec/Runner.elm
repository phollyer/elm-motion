module Helpers.Engine.Api.InitSpec.Runner exposing
    ( NameValuePair
    , TestCase(..)
    , TestData
    , run
    )

import Expect
import Helpers.AnimGroups exposing (animGroup)
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type alias TestData builder =
    { description : String
    , testCases : List (TestCase builder)
    }


type TestCase builder
    = GeneralTest (GeneralTestCase builder)
    | SizeTest (SizeTestCase builder)
    | MultiPropertyTest (MultiPropertyTestCase builder)
    | MultiGroupTest (MultiGroupTestCase builder)


type alias GeneralTestCase builder =
    { description : String
    , initFuncs : builder
    , expected : NameValuePair
    }


type alias SizeTestCase builder =
    { description : String
    , initFuncs : builder
    , expectedHeight : Maybe String
    , expectedWidth : Maybe String
    , willChange : String
    }


type alias MultiPropertyTestCase builder =
    { description : String
    , initFuncs : List builder
    , expected : List NameValuePair
    , willChange : String
    }


type alias MultiGroupTestCase builder =
    { description : String
    , animGroups : List String
    , initFuncs : List (List builder)
    , expected : List (List NameValuePair)
    , willChange : List String
    }


type alias NameValuePair =
    { name : String
    , value : String
    }


run : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> List (TestData builder) -> List Test
run initFunc attributesFunc =
    List.map (runTestData initFunc attributesFunc)


runTestData : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> TestData builder -> Test
runTestData initFunc attributesFunc td =
    describe td.description <|
        List.map (runTestCase initFunc attributesFunc) td.testCases


runTestCase :
    (List builder -> state)
    -> (String -> state -> List (Html.Attribute msg))
    -> TestCase builder
    -> Test
runTestCase initFunc attributesFunc testCase =
    case testCase of
        GeneralTest tc ->
            generalRunner initFunc attributesFunc tc

        SizeTest tc ->
            sizeRunner initFunc attributesFunc tc

        MultiPropertyTest tc ->
            multiPropertyRunner initFunc attributesFunc tc

        MultiGroupTest tc ->
            multiGroupRunner initFunc attributesFunc tc


generalRunner : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> GeneralTestCase builder -> Test
generalRunner initFunc attributesFunc tc =
    test tc.description <|
        \_ ->
            initFunc [ tc.initFuncs ]
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style tc.expected.name tc.expected.value
                    , Selector.style "will-change" tc.expected.name
                    ]


multiGroupRunner : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> MultiGroupTestCase builder -> Test
multiGroupRunner initFunc attributesFunc tc =
    test tc.description <|
        \_ ->
            Expect.all
                (List.map4
                    (\init group expected willChange ->
                        \_ ->
                            initFunc init
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


multiPropertyRunner : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> MultiPropertyTestCase builder -> Test
multiPropertyRunner initFunc attributesFunc tc =
    test tc.description <|
        \_ ->
            initFunc tc.initFuncs
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    (Selector.style "will-change" tc.willChange
                        :: List.map
                            (\nvp ->
                                Selector.style nvp.name nvp.value
                            )
                            tc.expected
                    )


sizeRunner : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> SizeTestCase builder -> Test
sizeRunner initFunc attributesFunc tc =
    test tc.description <|
        \_ ->
            initFunc [ tc.initFuncs ]
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


attributesQueryFor : (String -> state -> List (Html.Attribute msg)) -> String -> state -> Query.Single msg
attributesQueryFor getAttributes groupName state =
    Html.div (getAttributes groupName state) []
        |> Query.fromHtml
