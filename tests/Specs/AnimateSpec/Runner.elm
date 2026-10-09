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


propertyRunner : EngineFactory animBuilder animState -> PropertyTestCase animBuilder -> Test
propertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                state =
                    Factory.animate factory [] tc.propertyPipeline
            in
            case factory of
                Keyframe f ->
                    Expect.styles tc.expected f.attributes animGroup state

                Transition f ->
                    Expect.styles tc.expected f.attributes animGroup state


multiPropertyRunner : EngineFactory animBuilder animState -> MultiPropertyTestCase animBuilder -> Test
multiPropertyRunner factory tc =
    test tc.description <|
        \_ ->
            let
                state =
                    Factory.animate factory [] <|
                        List.foldl (>>) identity tc.propertyPipeline
            in
            case factory of
                Keyframe f ->
                    Expect.styles tc.expected f.attributes animGroup state

                Transition f ->
                    Expect.styles tc.expected f.attributes animGroup state


multiGroupRunner : EngineFactory animBuilder animState -> MultiGroupTestCase animBuilder -> Test
multiGroupRunner factory tc =
    test tc.description <|
        \_ ->
            Expect.all
                (List.map3
                    (\propertyPipeline group expected ->
                        \_ ->
                            let
                                state =
                                    Factory.animate factory [] <|
                                        List.foldl (>>) identity propertyPipeline
                            in
                            case factory of
                                Keyframe f ->
                                    Expect.styles expected f.attributes group state

                                Transition f ->
                                    Expect.styles expected f.attributes group state
                    )
                    tc.propertyPipelines
                    tc.animGroups
                    tc.expected
                )
                ()
