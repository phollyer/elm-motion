module Anim.Builder.PlaybackResetSpec exposing (suite)

{-| Regression guard: per-animation playback settings (`iterations` and
`alternate`/direction) must not leak from one `animate` call into the next.

Reproduces the reported bug where a pulse animation configured with
`iterations 5` + `alternate` is followed - once its `Ended` event fires - by
a second animation on the same group that carries no explicit playback. The
second animation was inheriting the first animation's iteration count and
alternating direction.

`WAAPI.animate` threads the builder forward between calls, resetting
per-animation state via `Builder.clearAnimData` before the next `animate`.
These tests model that thread at the `Builder` level, where the fix lives, so
they guard every engine (all engines share `clearAnimData`).

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..), Iterations(..))
import Anim.Property.Translate as Translate
import Expect
import Test exposing (Test, describe, test)



-- ============================================================
-- BUILDERS
-- ============================================================


{-| Intro pulse: iterations + alternate set at global scope (before `for`).
-}
pulse : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
pulse =
    WAAPI.iterations 5
        >> WAAPI.alternate
        >> WAAPI.for "ball"
        >> Translate.begin
        >> Translate.toX 20
        >> Translate.duration 1000
        >> Translate.end


{-| Follow-up squash: no playback settings - should run once, normal direction.
-}
squash : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
squash =
    WAAPI.for "ball"
        >> Translate.begin
        >> Translate.toX 100
        >> Translate.duration 300
        >> Translate.end



-- ============================================================
-- SUITE
-- ============================================================


suite : Test
suite =
    describe "playback settings do not leak across animate calls"
        [ clearAnimDataResets
        , sequentialAnimations
        ]



-- ============================================================
-- clearAnimData
-- ============================================================


clearAnimDataResets : Test
clearAnimDataResets =
    describe "clearAnimData resets global playback to defaults"
        [ test "iterations returns to Once" <|
            \_ ->
                Builder.init [ WAAPI.iterations 5 >> WAAPI.alternate ]
                    |> Builder.clearAnimData
                    |> Builder.getIterations
                    |> Expect.equal Once
        , test "direction returns to Normal" <|
            \_ ->
                Builder.init [ WAAPI.iterations 5 >> WAAPI.alternate ]
                    |> Builder.clearAnimData
                    |> Builder.getAnimationDirection
                    |> Expect.equal Normal
        ]



-- ============================================================
-- SEQUENTIAL ANIMATIONS
-- ============================================================


sequentialAnimations : Test
sequentialAnimations =
    let
        firstProcessed =
            Builder.init [ pulse ]
                |> Builder.process

        secondProcessed =
            Builder.init [ pulse ]
                |> Builder.clearAnimData
                |> squash
                |> Builder.process
    in
    describe "the second animation ignores the first animation's playback"
        [ test "the pulse itself still repeats 5 times" <|
            \_ ->
                firstProcessed.iterations
                    |> Expect.equal (Times 5)
        , test "the pulse itself still alternates" <|
            \_ ->
                firstProcessed.animationDirection
                    |> Expect.equal Alternate
        , test "the squash runs once, not 5 times" <|
            \_ ->
                secondProcessed.iterations
                    |> Expect.equal Once
        , test "the squash uses normal direction, not alternate" <|
            \_ ->
                secondProcessed.animationDirection
                    |> Expect.equal Normal
        ]
