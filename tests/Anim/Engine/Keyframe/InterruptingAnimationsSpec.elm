module Anim.Engine.Keyframe.InterruptingAnimationsSpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (..)


animGroup : String
animGroup =
    "box"


moveBoxX : Float -> Keyframe.EngineBuilder -> Keyframe.EngineBuilder
moveBoxX x =
    Translate.for animGroup
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


initBuilder : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
initBuilder =
    Translate.initUnitX Cqw
        >> Translate.initUnitY Cqh
        >> Translate.initXY animGroup 0 0


suite : Test
suite =
    describe "Keyframe interrupting Translate animations (issue: jumps to end)"
        [ test "first animate emits a non-empty @keyframes rule" <|
            \_ ->
                let
                    state =
                        Keyframe.animate
                            (Keyframe.init [ initBuilder ])
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
                            (Keyframe.init [ initBuilder ])
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
                            (Keyframe.init [ initBuilder ])
                            (moveBoxX 88)

                    css =
                        Keyframe.maybeString animGroup state
                            |> Maybe.withDefault ""
                in
                css
                    |> String.contains "translate3d(88cqw, 0cqh, 0px)"
                    |> Expect.equal True
        , test "after a Translate(Cqw) animation, a subsequent non-Translate animation preserves the cqw unit in the translate baseline" <|
            \_ ->
                let
                    afterMove =
                        Keyframe.animate
                            (Keyframe.init [ initBuilder ])
                            (moveBoxX 88)

                    afterColor =
                        Keyframe.animate afterMove <|
                            (CustomColor.for animGroup CustomColor.BackgroundColor
                                >> CustomColor.to (Color.rgb 255 0 0)
                                >> CustomColor.duration 500
                                >> CustomColor.build
                            )

                    css =
                        Keyframe.maybeString animGroup afterColor
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "translate3d(88cqw"
                            |> Expect.equal True
                            |> Expect.onFail ("Expected baseline transform to keep cqw unit; got:\n" ++ css)
                    , \_ ->
                        css
                            |> String.contains "translate3d(88px"
                            |> Expect.equal False
                            |> Expect.onFail ("Baseline regressed to px unit; got:\n" ++ css)
                    ]
                    ()
        ]
