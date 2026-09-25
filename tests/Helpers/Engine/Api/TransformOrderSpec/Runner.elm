module Helpers.Engine.Api.TransformOrderSpec.Runner exposing
    ( TestCase(..)
    , TestData
    , run
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
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


type alias GeneralTestCase builder =
    { description : String
    , initFuncs : List builder
    , transformOrderFunc : builder
    , expected : String
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


generalRunner : (List builder -> state) -> (String -> state -> List (Html.Attribute msg)) -> GeneralTestCase builder -> Test
generalRunner initFunc attributesFunc tc =
    test tc.description <|
        \_ ->
            initFunc tc.initFuncs
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style "transform" tc.expected ]


attributesQueryFor : (String -> state -> List (Html.Attribute msg)) -> String -> state -> Query.Single msg
attributesQueryFor getAttributes groupName state =
    Html.div (getAttributes groupName state) []
        |> Query.fromHtml
