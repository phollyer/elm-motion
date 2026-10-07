module Specs.TransformOrderSpec.Runner exposing (run)

import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Helpers.AnimGroups exposing (animGroup)
import Html
import Specs.Shared exposing (attributesQueryFor)
import Specs.TransformOrderSpec.TestData exposing (AnimateTestCase, InitTestCase, TestCase(..), TestData)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


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
    describe tc.description <|
        [ test "with transform order first" <|
            \_ ->
                let
                    f =
                        Factory.create factory
                in
                f.init (f.transformOrder tc.transformOrder :: tc.initFuncs)
                    |> attributesQueryFor attributesFunc animGroup
                    |> Query.has
                        [ Selector.style "transform" tc.expected ]
        , test "with transform order in the middle" <|
            \_ ->
                let
                    f =
                        Factory.create factory

                    middle =
                        List.length tc.initFuncs // 2

                    initFuncs =
                        List.take middle tc.initFuncs ++ (f.transformOrder tc.transformOrder :: List.drop middle tc.initFuncs)
                in
                f.init initFuncs
                    |> attributesQueryFor attributesFunc animGroup
                    |> Query.has
                        [ Selector.style "transform" tc.expected ]
        , test "with transform order last" <|
            \_ ->
                let
                    f =
                        Factory.create factory
                in
                f.init (tc.initFuncs ++ [ f.transformOrder tc.transformOrder ])
                    |> attributesQueryFor attributesFunc animGroup
                    |> Query.has
                        [ Selector.style "transform" tc.expected ]
        ]


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
