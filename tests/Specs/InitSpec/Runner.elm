module Specs.InitSpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory exposing (EngineFactory(..))
import Helpers.AnimGroups exposing (animGroup)
import Html
import Specs.InitSpec.TestData exposing (..)
import Test exposing (Test, describe, test)


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
        PropertyTest tc ->
            generalRunner factory tc attributesFunc

        MultiPropertyTest tc ->
            multiPropertyRunner factory tc attributesFunc

        MultiGroupTest tc ->
            multiGroupRunner factory tc attributesFunc


generalRunner : EngineFactory animBuilder animState -> PropertyTestCase animBuilder -> (String -> animState -> List (Html.Attribute msg)) -> Test
generalRunner factory tc attributesFunc =
    test tc.description <|
        \_ ->
            Expect.initialStyles factory { initFuncs = tc.initFuncs, expected = tc.expected } attributesFunc animGroup


multiPropertyRunner : EngineFactory animBuilder animState -> MultiPropertyTestCase animBuilder -> (String -> animState -> List (Html.Attribute msg)) -> Test
multiPropertyRunner factory tc attributesFunc =
    test tc.description <|
        \_ ->
            Expect.initialStyles factory tc attributesFunc animGroup


multiGroupRunner : EngineFactory animBuilder animState -> MultiGroupTestCase animBuilder -> (String -> animState -> List (Html.Attribute msg)) -> Test
multiGroupRunner factory tc attributesFunc =
    test tc.description <|
        \_ ->
            Expect.all
                (List.map3
                    (\init group expected ->
                        \_ ->
                            Expect.initialStyles factory { initFuncs = init, expected = expected } attributesFunc group
                    )
                    tc.initFuncs
                    tc.animGroups
                    tc.expected
                )
                ()
