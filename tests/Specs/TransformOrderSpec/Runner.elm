module Specs.TransformOrderSpec.Runner exposing (run)

import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Helpers.AnimGroups exposing (animGroup)
import Html
import Specs.Shared exposing (attributesQueryFor)
import Specs.TransformOrderSpec.TestData exposing (AnimateTestCase, InitTestCase, TestCase(..), TestData)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector



{- Currently this documents existing behaviour, writes the default transform
   order on initialisation - which is wrong.

   It should test actually setting the Transform Order at initialization. This functionality
   does not yet exist.
-}
-- TODO: Implement tests for setting the Transform Order at initialization.


run :
    EngineFactory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> List (TestData animBuilder)
    -> List Test
run factory attributesFunc =
    List.map (runTestData factory attributesFunc)


runTestData :
    EngineFactory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> TestData animBuilder
    -> Test
runTestData factory attributesFunc td =
    describe td.description <|
        List.map (runTestCase factory attributesFunc) td.testCases


runTestCase :
    EngineFactory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> TestCase animBuilder
    -> Test
runTestCase factory attributesFunc testCase =
    case testCase of
        InitTest tc ->
            initRunner factory attributesFunc tc

        AnimateTest tc ->
            animateRunner factory attributesFunc tc


initRunner : EngineFactory animBuilder state -> (String -> state -> List (Html.Attribute msg)) -> InitTestCase animBuilder -> Test
initRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory
            in
            f.init tc.initFuncs
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style "transform" tc.expected ]


animateRunner :
    EngineFactory animBuilder state
    -> (String -> state -> List (Html.Attribute msg))
    -> AnimateTestCase animBuilder
    -> Test
animateRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory
            in
            f.init []
                |> (\state ->
                        f.animate state <|
                            f.for animGroup
                                >> f.transformOrder tc.transformOrder
                                >> tc.animateFuncs
                   )
                |> attributesQueryFor attributesFunc animGroup
                |> Query.has
                    [ Selector.style "transform" tc.expected ]
