module Specs.TransformOrderSpec.Runner exposing (run)

import Expectations.Expect as Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.Shared exposing (attributesQueryFor)
import Specs.TransformOrderSpec.TestData exposing (AnimateTestCase, InitTestCase, TestCase(..), TestData)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


run :
    EngineFactory animBuilder state
    -> List (TestData animBuilder)
    -> List Test
run factory =
    List.map (runTestData factory)


runTestData :
    EngineFactory animBuilder state
    -> TestData animBuilder
    -> Test
runTestData factory td =
    describe td.description <|
        List.map (runTestCase factory) td.testCases


runTestCase :
    EngineFactory animBuilder state
    -> TestCase animBuilder
    -> Test
runTestCase factory testCase =
    case testCase of
        InitTest tc ->
            initRunner factory tc

        AnimateTest tc ->
            animateRunner factory tc


initRunner : EngineFactory animBuilder state -> InitTestCase animBuilder -> Test
initRunner factory tc =
    describe tc.description <|
        [ test "with transform order first" <|
            \_ ->
                let
                    f =
                        Factory.create factory

                    state =
                        f.init (f.transformOrder tc.transformOrder :: tc.initFuncs)
                in
                case factory of
                    Factory.Keyframe f_ ->
                        Expect.attributes animGroup f_.attributes tc state

                    Factory.Transition f_ ->
                        Expect.attributes animGroup f_.attributes tc state
        , test "with transform order in the middle" <|
            \_ ->
                let
                    f =
                        Factory.create factory

                    middle =
                        List.length tc.initFuncs // 2

                    initFuncs =
                        List.take middle tc.initFuncs ++ (f.transformOrder tc.transformOrder :: List.drop middle tc.initFuncs)

                    state =
                        f.init initFuncs
                in
                case factory of
                    Factory.Keyframe f_ ->
                        Expect.attributes animGroup f_.attributes tc state

                    Factory.Transition f_ ->
                        Expect.attributes animGroup f_.attributes tc state
        , test "with transform order last" <|
            \_ ->
                let
                    f =
                        Factory.create factory
                in
                let
                    state =
                        f.init (tc.initFuncs ++ [ f.transformOrder tc.transformOrder ])
                in
                case factory of
                    Factory.Keyframe f_ ->
                        Expect.attributes animGroup f_.attributes tc state

                    Factory.Transition f_ ->
                        Expect.attributes animGroup f_.attributes tc state
        ]


animateRunner :
    EngineFactory animBuilder state
    -> AnimateTestCase animBuilder
    -> Test
animateRunner factory tc =
    test tc.description <|
        \_ ->
            let
                f =
                    Factory.create factory

                state =
                    f.animate (f.init []) <|
                        f.for animGroup
                            >> f.transformOrder tc.transformOrder
                            >> tc.animateFuncs
            in
            case factory of
                Factory.Keyframe f_ ->
                    Expect.attributes animGroup f_.attributes tc state

                Factory.Transition f_ ->
                    Expect.attributes animGroup f_.attributes tc state
