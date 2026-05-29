module Anim.Engine.Sub.ResumeAfterResetSpec exposing (suite)

{-| Regression test for the Resume-after-Reset bug.

After a one-shot animation has either completed or been reset,
`Sub.resume` should be a no-op (matching the Keyframe and WAAPI engine
contract: resume only re-activates an explicitly Paused animation).

Previously, `resume` unconditionally set play state to Running and
re-enabled subscriptions, so clicking Resume after Reset would
re-trigger the animation from the start.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


initialState : Sub.AnimState
initialState =
    Sub.init [ Translate.initXY groupName 0 0 ]


moveX : Float -> Sub.EngineBuilder -> Sub.EngineBuilder
moveX target =
    Translate.for groupName
        >> Translate.toX target
        >> Translate.duration 1000
        >> Translate.easing Linear
        >> Translate.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


suite : Test
suite =
    describe "Sub resume gating"
        [ test "resume on a Reset animation does not re-arm the animation" <|
            \_ ->
                let
                    after =
                        initialState
                            |> (\s -> Sub.animate s (moveX 500))
                            |> step 1000
                            |> Sub.reset groupName
                            |> Sub.resume groupName
                in
                Sub.isRunning groupName after
                    |> Expect.equal (Just False)
        , test "resume on a Complete animation does not re-arm the animation" <|
            \_ ->
                let
                    after =
                        initialState
                            |> (\s -> Sub.animate s (moveX 500))
                            |> step 1000
                            |> Sub.resume groupName
                in
                Sub.isRunning groupName after
                    |> Expect.equal (Just False)
        , test "resume on a Paused animation re-arms it (positive control)" <|
            \_ ->
                let
                    after =
                        initialState
                            |> (\s -> Sub.animate s (moveX 500))
                            |> step 300
                            |> Sub.pause groupName
                            |> Sub.resume groupName
                in
                Sub.isRunning groupName after
                    |> Expect.equal (Just True)
        ]
