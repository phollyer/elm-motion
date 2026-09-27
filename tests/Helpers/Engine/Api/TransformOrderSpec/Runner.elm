module Helpers.Engine.Api.TransformOrderSpec.Runner exposing
    ( TestCase(..)
    , TestData
    , run
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Engines.Factory exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TestCase animBuilder
    = InitTest (InitTestCase animBuilder)
    | AnimateTest (AnimateTestCase animBuilder)



{- Currently this documents existing behaviour, writes the default transform
   order on initialisation - which is wrong.

   It should test actually setting the Transform Order at initialization. This functionality
   does not yet exist.
-}
-- TODO: Implement tests for setting the Transform Order at initialization.


type alias InitTestCase animBuilder =
    { description : String
    , initFuncs : List (animBuilder -> animBuilder)
    , expected : String
    }


type alias AnimateTestCase animBuilder =
    { description : String
    , animateFuncs : List (animBuilder -> animBuilder)
    , transformOrderFunc : animBuilder -> animBuilder
    , expected : String
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
        InitTest tc ->
            initRunner factory attributesFunc tc

        AnimateTest tc ->
            animateRunner factory attributesFunc tc


initRunner : Factory animBuilder state -> (String -> state -> List (Html.Attribute msg)) -> InitTestCase animBuilder -> Test
initRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            factory.init tc.initFuncs
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style "transform" tc.expected ]


animateRunner :
    Factory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> AnimateTestCase animBuilder
    -> Test
animateRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            factory.init []
                |> (\state ->
                        factory.animate state <|
                            factory.for animGroup
                                >> tc.transformOrderFunc
                                >> List.foldl (>>) identity tc.animateFuncs
                   )
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style "transform" tc.expected ]


attributesQueryFor : (String -> state -> List (Html.Attribute msg)) -> String -> state -> Query.Single msg
attributesQueryFor getAttributes groupName state =
    Html.div (getAttributes groupName state) []
        |> Query.fromHtml
