module Specs.InitSpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (..)
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
            test tc.description <|
                \_ ->
                    runExpectations factory tc.initFuncs animGroup tc.expected tc.notExpected

        MultiPropertyTest tc ->
            test tc.description <|
                \_ ->
                    runExpectations factory tc.initFuncs animGroup tc.expected tc.notExpected

        MultiGroupTest tc ->
            test tc.description <|
                \_ ->
                    Expect.all
                        (List.map4
                            (\init group expected notExpected ->
                                \_ ->
                                    runExpectations factory init group expected notExpected
                            )
                            tc.initFuncs
                            tc.animGroups
                            tc.expected
                            tc.notExpected
                        )
                        ()


runExpectations : EngineFactory animBuilder animState -> List (animBuilder -> animBuilder) -> String -> List NameValuePair -> List String -> Expect.Expectation
runExpectations factory initFuncs animGroupName expected notExpected =
    let
        f =
            Factory.create factory
    in
    f.init initFuncs
        |> (\state ->
                case factory of
                    Keyframe f_ ->
                        Expect.all
                            [ \s ->
                                Expect.styles expected f_.attributes animGroupName s
                            , \s ->
                                Expect.willChange expected f_.attributes animGroupName s
                            , \s ->
                                Expect.stylesNotPresent notExpected f_.styleDeclarations animGroupName s
                            ]
                            state

                    Transition f_ ->
                        Expect.all
                            [ \s ->
                                Expect.styles expected f_.attributes animGroupName s
                            , \s ->
                                Expect.willChange expected f_.attributes animGroupName s
                            , \s ->
                                Expect.stylesNotPresent notExpected f_.styleDeclarations animGroupName s
                            ]
                            state
           )
