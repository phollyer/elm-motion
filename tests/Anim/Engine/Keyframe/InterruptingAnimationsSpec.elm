module Anim.Engine.Keyframe.InterruptingAnimationsSpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (..)


animGroup : String
animGroup =
    "box"


moveBoxX : Float -> Keyframe.AnimBuilder mode -> Keyframe.AnimBuilder mode
moveBoxX x =
    Translate.for animGroup
        >> Translate.cssUnitX Cqw
        >> Translate.cssUnitY Cqh
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


suite : Test
suite =
    describe "Keyframe interrupting Translate animations (issue: jumps to end)"
        [ test "first animate emits a non-empty @keyframes rule" <|
            \_ ->
                let
                    state =
                        Keyframe.animate
                            (Keyframe.init [ Translate.initXY animGroup 0 0 ])
                            (moveBoxX 88)

                    css =
                        Keyframe.maybeString animGroup state
                            |> Maybe.withDefault ""
                in
                Expect.equal True (String.contains "@keyframes" css)
        , test "first animate keyframes start at translate3d(0,0,0)" <|
            \_ ->
                let
                    state =
                        Keyframe.animate
                            (Keyframe.init [ Translate.initXY animGroup 0 0 ])
                            (moveBoxX 88)

                    css =
                        Keyframe.maybeString animGroup state
                            |> Maybe.withDefault ""
                in
                css
                    |> String.contains "translate3d(0cqw, 0cqh, 0px)"
                    |> Expect.equal True
        , test "first animate keyframes end at translate3d(88cqw, 0cqh, 0px)" <|
            \_ ->
                let
                    state =
                        Keyframe.animate
                            (Keyframe.init [ Translate.initXY animGroup 0 0 ])
                            (moveBoxX 88)

                    css =
                        Keyframe.maybeString animGroup state
                            |> Maybe.withDefault ""
                in
                css
                    |> String.contains "translate3d(88cqw, 0cqh, 0px)"
                    |> Expect.equal True
        ]
