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
            generalRunner factory attributesFunc tc

        MultiPropertyTest tc ->
            multiPropertyRunner factory attributesFunc tc

        MultiGroupTest tc ->
            multiGroupRunner factory attributesFunc tc


generalRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> PropertyTestCase animBuilder -> Test
generalRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            Expect.initialStyles factory animGroup attributesFunc { initFuncs = tc.initFuncs, expected = tc.expected }


multiPropertyRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> MultiPropertyTestCase animBuilder -> Test
multiPropertyRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            Expect.initialStyles factory animGroup attributesFunc tc


multiGroupRunner : EngineFactory animBuilder animState -> (String -> animState -> List (Html.Attribute msg)) -> MultiGroupTestCase animBuilder -> Test
multiGroupRunner factory attributesFunc tc =
    test tc.description <|
        \_ ->
            Expect.all
                (List.map3
                    (\init group expected ->
                        \_ ->
                            Expect.initialStyles factory group attributesFunc { initFuncs = init, expected = expected }
                    )
                    tc.initFuncs
                    tc.animGroups
                    tc.expected
                )
                ()
