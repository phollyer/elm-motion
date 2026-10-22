module Specs.DiscretePropertiesSpec.DiscreteExitSpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (DiscreteOps, MultiGroupTestCase, MultiPropertyTestCase, PropertyTestCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Test exposing (Test, describe, test)


run : EngineFactory animBuilder animState -> List (TestData animBuilder) -> List Test
run factory =
    List.map (runTestData factory)


runTestData : EngineFactory animBuilder animState -> TestData animBuilder -> Test
runTestData factory td =
    describe td.description <|
        List.map (runTestCase factory) td.testCases


runTestCase : EngineFactory animBuilder animState -> TestCase animBuilder -> Test
runTestCase factory testCase =
    case testCase of
        PropertyTest tc ->
            propertyRunner factory tc

        MultiPropertyTest tc ->
            multiPropertyRunner factory tc

        MultiGroupTest tc ->
            multiGroupRunner factory tc


propertyRunner : EngineFactory animBuilder animState -> PropertyTestCase animBuilder -> Test
propertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                ops : DiscreteOps animBuilder
                ops =
                    { for = f.for
                    , discreteEntry = f.discreteEntry
                    , discreteExit = f.discreteExit
                    }

                state =
                    Factory.build f
                        (List.map (\initFunc -> initFunc ops) tc.initFuncs)
                        (ops.for tc.animGroup >> tc.propertyPipeline ops)
            in
            runExpectations factory tc.animGroup tc.expected tc.notExpected state


multiPropertyRunner : EngineFactory animBuilder animState -> MultiPropertyTestCase animBuilder -> Test
multiPropertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                ops : DiscreteOps animBuilder
                ops =
                    { for = f.for
                    , discreteEntry = f.discreteEntry
                    , discreteExit = f.discreteExit
                    }

                state =
                    Factory.build f
                        (List.map (\initFunc -> initFunc ops) tc.initFuncs)
                        (ops.for tc.animGroup
                            >> List.foldl (\pipeline acc -> acc >> pipeline ops) identity tc.propertyPipelines
                        )
            in
            runExpectations factory tc.animGroup tc.expected tc.notExpected state


multiGroupRunner : EngineFactory animBuilder animState -> MultiGroupTestCase animBuilder -> Test
multiGroupRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                ops : DiscreteOps animBuilder
                ops =
                    { for = f.for
                    , discreteEntry = f.discreteEntry
                    , discreteExit = f.discreteExit
                    }

                state =
                    List.map (\initFunc -> initFunc ops) tc.initFuncs
                        |> f.init
                        |> (\initialState ->
                                List.map2 Tuple.pair tc.animGroups tc.propertyPipelines
                                    |> List.foldl
                                        (\( animGroup, pipelines ) acc ->
                                            f.animate acc <|
                                                ops.for animGroup
                                                    >> List.foldl (\pipeline next -> next >> pipeline ops) identity pipelines
                                        )
                                        initialState
                           )
            in
            Expect.all
                (List.map3
                    (\animGroup expected notExpected ->
                        \_ ->
                            runExpectations factory animGroup expected notExpected state
                    )
                    tc.animGroups
                    tc.expected
                    tc.notExpected
                )
                ()


runExpectations : EngineFactory animBuilder animState -> String -> List NameValuePair -> List String -> animState -> Expect.Expectation
runExpectations factory animGroup expected notExpected state =
    case factory of
        Keyframe f ->
            Expect.all
                [ \_ ->
                    Expect.styles expected f.attributes animGroup state
                , \_ ->
                    Expect.stylesNotPresent notExpected f.styleDeclarations animGroup state
                ]
                ()

        Transition f ->
            Expect.all
                [ \_ ->
                    Expect.styles expected f.attributes animGroup state
                , \_ ->
                    Expect.stylesNotPresent notExpected f.styleDeclarations animGroup state
                ]
                ()
