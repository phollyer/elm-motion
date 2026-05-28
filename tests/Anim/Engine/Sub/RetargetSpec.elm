module Anim.Engine.Sub.RetargetSpec exposing (suite)

{-| End-to-end tests for `Sub.retarget`.

`Sub.retarget` snaps the named anim groups to the targets in the build with
no animation. For each touched property the in-flight animation is stopped
and replaced with the snapped target; properties not mentioned in the build
keep running with their existing state. `Translate` retargets per-axis: only
the touched axes snap, untouched axes continue along the existing easing
curve toward their existing end value.

Builder timing fields (`duration`, `delay`, `easing`, `spring`) are accepted
but ignored.

A `Cancelled` event is emitted for every group that was `Running` and is
touched by the build. No `Started` event is emitted.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)



-- ============================================================
-- HELPERS
-- ============================================================


initState : Sub.AnimState
initState =
    Sub.init
        [ Translate.initXY "a" 0 0
        , Translate.initXY "b" 0 0
        , Opacity.init "a" 1
        ]


startTranslate : String -> Float -> Sub.AnimState -> Sub.AnimState
startTranslate groupName target state =
    Sub.animate state <|
        (Translate.for groupName
            >> Translate.toX target
            >> Translate.duration 1000
            >> Translate.easing EaseInOut
            >> Translate.build
        )


snapTranslate : String -> Float -> Sub.AnimState -> Sub.AnimState
snapTranslate groupName target state =
    Sub.retarget state <|
        (Translate.for groupName
            >> Translate.toX target
            >> Translate.build
        )


snapTranslateY : String -> Float -> Sub.AnimState -> Sub.AnimState
snapTranslateY groupName target state =
    Sub.retarget state <|
        (Translate.for groupName
            >> Translate.toY target
            >> Translate.build
        )


drainEvents : Sub.AnimState -> ( Sub.AnimState, List Sub.AnimEvent )
drainEvents state =
    Sub.update (Internal.AnimationFrame 0) state



-- ============================================================
-- SUITE
-- ============================================================


suite : Test
suite =
    describe "Anim.Engine.Sub retarget"
        [ snapSemantics
        , scoping
        , timingIgnored
        , eventEmission
        ]



-- ============================================================
-- SNAP SEMANTICS
-- ============================================================


snapSemantics : Test
snapSemantics =
    describe "retarget snaps to the new target"
        [ test "current value equals the new target immediately after retarget on a running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "end value equals the new target after retarget on a running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget leaves the group not-running" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just False)
        , test "retarget marks the group complete" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.isComplete "a"
                    |> Expect.equal (Just True)
        , test "retarget on an idle group also snaps to the target" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget on an idle group leaves the group not-running" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just False)
        , test "a subsequent animate begins from the snapped target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> startTranslate "a" 600
                    |> Sub.getTranslateStart "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        ]



-- ============================================================
-- SCOPING
-- ============================================================


scoping : Test
scoping =
    describe "retarget is scoped to the groups in the build"
        [ test "retarget on group b leaves group a's running animation intact" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just True)
        , test "retarget on group b leaves group a's end value at its animation target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 500)
        , test "retarget on group b snaps only group b" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> Sub.getTranslateCurrent "b"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget leaves untouched properties on the same group still running" <|
            \_ ->
                let
                    startOpacity state =
                        Sub.animate state <|
                            (Opacity.for "a"
                                >> Opacity.to 0
                                >> Opacity.duration 1000
                                >> Opacity.build
                            )
                in
                initState
                    |> startTranslate "a" 500
                    |> startOpacity
                    |> snapTranslate "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just True)
        , test "retarget on Y leaves the in-flight X axis still animating" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just True)
        , test "retarget on Y pins Y on the running translate animation to the new target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .y
                    |> Expect.equal (Just 250)
        , test "retarget on Y leaves the in-flight X end value untouched" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 500)
        , test "retarget on Y sets the translate end Y value to the new target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .y
                    |> Expect.equal (Just 250)
        ]



-- ============================================================
-- TIMING IGNORED
-- ============================================================


timingIgnored : Test
timingIgnored =
    describe "builder timing fields are accepted but ignored"
        [ test "duration set in retarget builder does not delay the snap" <|
            \_ ->
                let
                    snapWithLongDuration =
                        Sub.retarget
                            (startTranslate "a" 500 initState)
                            (Translate.for "a"
                                >> Translate.toX 250
                                >> Translate.duration 10000
                                >> Translate.build
                            )
                in
                snapWithLongDuration
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "delay set in retarget builder does not defer the snap" <|
            \_ ->
                let
                    snapWithDelay =
                        Sub.retarget
                            (startTranslate "a" 500 initState)
                            (Translate.for "a"
                                >> Translate.toX 250
                                >> Translate.delay 5000
                                >> Translate.build
                            )
                in
                snapWithDelay
                    |> Sub.isComplete "a"
                    |> Expect.equal (Just True)
        ]



-- ============================================================
-- EVENT EMISSION
-- ============================================================


eventEmission : Test
eventEmission =
    describe "retarget event emission"
        [ test "emits Cancelled for a previously-Running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> drainEvents
                    |> Tuple.first
                    |> snapTranslate "a" 250
                    |> drainEvents
                    |> Tuple.second
                    |> List.filter
                        (\ev ->
                            case ev of
                                Sub.Cancelled name _ ->
                                    name == "a"

                                _ ->
                                    False
                        )
                    |> List.length
                    |> Expect.equal 1
        , test "does not emit Started for the retargeted group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> drainEvents
                    |> Tuple.first
                    |> snapTranslate "a" 250
                    |> drainEvents
                    |> Tuple.second
                    |> List.filter
                        (\ev ->
                            case ev of
                                Sub.Started _ ->
                                    True

                                _ ->
                                    False
                        )
                    |> Expect.equal []
        , test "does not emit Cancelled for an idle retargeted group" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> drainEvents
                    |> Tuple.second
                    |> List.filter
                        (\ev ->
                            case ev of
                                Sub.Cancelled _ _ ->
                                    True

                                _ ->
                                    False
                        )
                    |> Expect.equal []
        ]
