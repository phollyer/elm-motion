module Specs.AnimateSpec.Runner exposing (run)

import Expect
import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.AnimateSpec.TestData exposing (..)
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

        Animate2Test tc ->
            animate2Runner factory tc


propertyRunner : EngineFactory animBuilder animState -> PropertyTestCase animBuilder -> Test
propertyRunner factory tc =
    test (tc.description ++ timingSuffix tc.timing) <|
        \_ ->
            let
                state =
                    Factory.animate factory animGroup [] <|
                        applyTiming factory tc.timing tc.propertyPipeline
            in
            case factory of
                Keyframe f ->
                    Expect.all
                        [ \_ ->
                            Expect.styles tc.expected f.attributes animGroup state
                        , \_ ->
                            Expect.stylesNotPresent tc.notExpected f.styleDeclarations animGroup state
                        ]
                        ()

                Transition f ->
                    Expect.all
                        [ \_ ->
                            Expect.styles tc.expected f.attributes animGroup state
                        , \_ ->
                            Expect.stylesNotPresent tc.notExpected f.styleDeclarations animGroup state
                        ]
                        ()


multiPropertyRunner : EngineFactory animBuilder animState -> MultiPropertyTestCase animBuilder -> Test
multiPropertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                state =
                    Factory.animate factory animGroup [] <|
                        List.foldl (>>) identity tc.propertyPipeline
            in
            case factory of
                Keyframe f ->
                    Expect.all
                        [ \_ ->
                            Expect.styles tc.expected f.attributes animGroup state
                        , \_ ->
                            Expect.stylesNotPresent tc.notExpected f.styleDeclarations animGroup state
                        ]
                        ()

                Transition f ->
                    Expect.all
                        [ \_ ->
                            Expect.styles tc.expected f.attributes animGroup state
                        , \_ ->
                            Expect.stylesNotPresent tc.notExpected f.styleDeclarations animGroup state
                        ]
                        ()


multiGroupRunner : EngineFactory animBuilder animState -> MultiGroupTestCase animBuilder -> Test
multiGroupRunner factory tc =
    test tc.description <|
        \_ ->
            Expect.all
                (List.map4
                    (\propertyPipeline group expected notExpected ->
                        \_ ->
                            let
                                state =
                                    Factory.animate factory group [] <|
                                        List.foldl (>>) identity propertyPipeline
                            in
                            case factory of
                                Keyframe f ->
                                    Expect.all
                                        [ \_ ->
                                            Expect.styles expected f.attributes group state
                                        , \_ ->
                                            Expect.stylesNotPresent notExpected f.styleDeclarations group state
                                        ]
                                        ()

                                Transition f ->
                                    Expect.all
                                        [ \_ ->
                                            Expect.styles expected f.attributes group state
                                        , \_ ->
                                            Expect.stylesNotPresent notExpected f.styleDeclarations group state
                                        ]
                                        ()
                    )
                    tc.propertyPipelines
                    tc.animGroups
                    tc.expected
                    tc.notExpected
                )
                ()


animate2Runner : EngineFactory animBuilder animState -> Animate2TestCase animBuilder -> Test
animate2Runner factory tc =
    test (tc.description ++ timingSuffix tc.timing) <|
        \_ ->
            let
                state =
                    Factory.animate2 factory animGroup [] (applyTiming factory tc.timing tc.propertyPipeline1) (applyTiming factory tc.timing tc.propertyPipeline2)
            in
            case factory of
                Keyframe f ->
                    Expect.all
                        [ \_ ->
                            Expect.styles tc.expected f.attributes animGroup state
                        , \_ ->
                            Expect.stylesNotPresent tc.notExpected f.styleDeclarations animGroup state
                        ]
                        ()

                Transition f ->
                    Expect.all
                        [ \_ ->
                            Expect.styles tc.expected f.attributes animGroup state
                        , \_ ->
                            Expect.stylesNotPresent tc.notExpected f.styleDeclarations animGroup state
                        ]
                        ()


timingSuffix : TimingProfile -> String
timingSuffix timing =
    case timing of
        NoTiming ->
            ""

        DelayMs delayMs ->
            " [delay " ++ String.fromInt delayMs ++ "ms]"


applyTiming : EngineFactory animBuilder animState -> TimingProfile -> (animBuilder -> animBuilder) -> (animBuilder -> animBuilder)
applyTiming factory timing pipeline =
    let
        f =
            Factory.create factory
    in
    case timing of
        NoTiming ->
            pipeline

        DelayMs delayMs ->
            f.delay delayMs
                >> pipeline
