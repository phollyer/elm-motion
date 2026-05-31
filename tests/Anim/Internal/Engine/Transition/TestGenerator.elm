module Anim.Internal.Engine.Transition.TestGenerator exposing (suite)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles
import Anim.Internal.Engine.Transition.AnimGroup as TransitionAnimGroup
import Anim.Internal.Engine.Transition.Generator as Generator
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Unit as InternalUnit
import Dict
import Expect
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


translateConfig : Builder.PropertyConfig
translateConfig =
    Builder.TranslateConfig
        { start = Just (Translate.fromTriple ( 0, 0, 0 ))
        , end = Translate.fromTriple ( 100, 0, 0 )
        , distance = 100
        , timing = Just (Duration 1000)
        , easing = Nothing
        , spring = Nothing
        , delay = Nothing
        , cssUnit = InternalUnit.emptyCssUnitAxes
        , mode = Builder.Animate
        }


suite : Test
suite =
    describe "Anim.Internal.Engine.Transition.Generator"
        [ initTests
        , generateAnimationTests
        , snapModeTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "init with no properties creates AnimGroup with transition styles" <|
            \_ ->
                Generator.init False Dict.empty Dict.empty []
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        , test "init with translate produces animation with non-empty styles" <|
            \_ ->
                Generator.init False Dict.empty Dict.empty [ translateConfig ]
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        , test "init preserves discrete entry properties" <|
            \_ ->
                let
                    entry =
                        Dict.fromList [ ( "visibility", "visible" ) ]
                in
                Generator.init False entry Dict.empty [ translateConfig ]
                    |> (\animGroup ->
                            TransitionAnimGroup.getDiscreteEntry animGroup
                                |> Dict.get "visibility"
                                |> Expect.equal (Just "visible")
                       )
        ]


generateAnimationTests : Test
generateAnimationTests =
    describe "generateAnimation"
        [ test "generated animation has non-empty styles" <|
            \_ ->
                let
                    processedProps =
                        Builder.processProperties Builder.initDefaults [ translateConfig ]
                in
                Generator.generateAnimation False Dict.empty Dict.empty processedProps
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        ]


snapTranslateConfig : Builder.PropertyConfig
snapTranslateConfig =
    Builder.TranslateConfig
        { start = Just (Translate.fromTriple ( 0, 0, 0 ))
        , end = Translate.fromTriple ( 100, 0, 0 )
        , distance = 100
        , timing = Just (Duration 1000)
        , easing = Nothing
        , spring = Nothing
        , delay = Nothing
        , cssUnit = InternalUnit.emptyCssUnitAxes
        , mode = Builder.Snap
        }


opacityConfig : Builder.AnimationMode -> Builder.PropertyConfig
opacityConfig mode =
    Builder.OpacityConfig
        { start = Nothing
        , end = Opacity.fromFloat 0
        , distance = 1
        , timing = Just (Duration 1000)
        , easing = Nothing
        , spring = Nothing
        , delay = Nothing
        , cssUnit = InternalUnit.emptyCssUnitAxes
        , mode = mode
        }


snapModeTests : Test
snapModeTests =
    describe "Snap mode"
        [ test "Snap property is excluded from transition string" <|
            \_ ->
                let
                    processed =
                        Builder.processProperties Builder.initDefaults [ snapTranslateConfig ]
                in
                Generator.generate False Dict.empty Dict.empty processed
                    |> Expect.equal "none"
        , test "Animate alongside Snap: only Animate appears" <|
            \_ ->
                let
                    processed =
                        Builder.processProperties Builder.initDefaults
                            [ opacityConfig Builder.Animate
                            , snapTranslateConfig
                            ]
                in
                Generator.generate False Dict.empty Dict.empty processed
                    |> (\s ->
                            Expect.all
                                [ \str -> Expect.equal True (String.contains "opacity" str)
                                , \str -> Expect.equal False (String.contains "translate" str)
                                , \str -> Expect.equal False (String.contains "transform" str)
                                ]
                                s
                       )
        , test "Snap property still gets end value in styles" <|
            \_ ->
                let
                    processed =
                        Builder.processProperties Builder.initDefaults [ snapTranslateConfig ]
                in
                Generator.generateAnimation False Dict.empty Dict.empty processed
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        ]
