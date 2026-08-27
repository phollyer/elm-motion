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
    Keyframe.for animGroup
        >> Translate.begin
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.end


moveBoxXWithUnit : Unit -> Float -> Keyframe.EngineBuilder -> Keyframe.EngineBuilder
moveBoxXWithUnit unit x =
    Keyframe.cssUnitX unit
        >> Keyframe.for animGroup
        >> Translate.begin
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.end


initBuilder : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
initBuilder =
    Translate.initXY animGroup 0 0
        >> Translate.initCssUnitX Cqw
        >> Translate.initCssUnitY Cqh


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
                            (Keyframe.for animGroup
                                >> CustomColor.begin CustomColor.BackgroundColor
                                >> CustomColor.to (Color.rgb 255 0 0)
                                >> CustomColor.duration 500
                                >> CustomColor.end
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
        , test "mid-stream second animate switches to the new unit immediately" <|
            \_ ->
                let
                    phase1 =
                        Keyframe.animate
                            (Keyframe.init [ initBuilder ])
                            (moveBoxX 88)

                    phase2 =
                        Keyframe.animate phase1 (moveBoxXWithUnit Vw 12)

                    css =
                        Keyframe.maybeString animGroup phase2
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "translate3d(88vw"
                            |> Expect.equal True
                            |> Expect.onFail ("Expected interruption baseline to adopt new unit immediately; got:\n" ++ css)
                    , \_ ->
                        css
                            |> String.contains "translate3d(12vw"
                            |> Expect.equal True
                            |> Expect.onFail ("Expected second phase target to use new unit; got:\n" ++ css)
                    , \_ ->
                        css
                            |> String.contains "translate3d(88cqw"
                            |> Expect.equal False
                            |> Expect.onFail ("Expected old unit to be replaced in second phase keyframes; got:\n" ++ css)
                    ]
                    ()
        , test "idle second animate still applies the new unit and plays forward" <|
            \_ ->
                let
                    phase1 =
                        Keyframe.animate
                            (Keyframe.init [ initBuilder ])
                            (moveBoxX 88)

                    stopped =
                        Keyframe.stop animGroup phase1

                    phase2 =
                        Keyframe.animate stopped (moveBoxXWithUnit Vw 20)

                    css =
                        Keyframe.maybeString animGroup phase2
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "@keyframes"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "translate3d(88vw"
                            |> Expect.equal True
                            |> Expect.onFail ("Expected phase2 start to use new unit from idle baseline; got:\n" ++ css)
                    , \_ ->
                        css
                            |> String.contains "translate3d(20vw"
                            |> Expect.equal True
                            |> Expect.onFail ("Expected phase2 end to use new unit; got:\n" ++ css)
                    ]
                    ()
        ]
