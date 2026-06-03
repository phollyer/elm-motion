module Anim.Engine.Keyframe.AnimateAfterPauseSpec exposing (suite)

{-| Regression test for the row 16 (ControllingAnimations) bug:

    Animate -> Pause -> Animate

leaves the CSS `animation-play-state` style stuck at `paused`, so a
subsequent `Resume` is a no-op (it sees the internal state as
`Running` and bails). Calling `animate` again should produce a fresh
animation that is unambiguously running.

-}

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Expect
import Html
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


animGroup : String
animGroup =
    "bouncingBall"


toMsg : Keyframe.AnimMsg -> ()
toMsg _ =
    ()


initial : Keyframe.AnimState
initial =
    Keyframe.init [ Translate.initY animGroup 0 >> Translate.cssUnit Cqh ]


dropBall : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
dropBall =
    Translate.for animGroup
        >> Translate.fromY 0
        >> Translate.toY 88
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


renderedStyle : Keyframe.AnimState -> Query.Single ()
renderedStyle state =
    Html.div (Keyframe.attributes animGroup state) []
        |> Query.fromHtml


suite : Test
suite =
    describe "Keyframe animate always replays"
        [ test "animate after pause re-emits animation-play-state: running" <|
            \_ ->
                let
                    afterAnimate =
                        Keyframe.animate initial dropBall

                    ( afterPause, _ ) =
                        Keyframe.pause animGroup toMsg afterAnimate

                    afterAnimateAgain =
                        Keyframe.animate afterPause dropBall
                in
                afterAnimateAgain
                    |> renderedStyle
                    |> Query.has [ Selector.style "animation-play-state" "running" ]
        , test "animate after pause generates a new keyframes name" <|
            \_ ->
                let
                    afterAnimate =
                        Keyframe.animate initial dropBall

                    ( afterPause, _ ) =
                        Keyframe.pause animGroup toMsg afterAnimate

                    afterAnimateAgain =
                        Keyframe.animate afterPause dropBall
                in
                Expect.notEqual
                    (Keyframe.maybeString animGroup afterAnimate)
                    (Keyframe.maybeString animGroup afterAnimateAgain)
        , test "animate while already running regenerates keyframes" <|
            \_ ->
                let
                    afterFirstAnimate =
                        Keyframe.animate initial dropBall

                    afterSecondAnimate =
                        Keyframe.animate afterFirstAnimate dropBall
                in
                Expect.notEqual
                    (Keyframe.maybeString animGroup afterFirstAnimate)
                    (Keyframe.maybeString animGroup afterSecondAnimate)
        ]
