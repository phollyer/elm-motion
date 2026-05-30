module Anim.Internal.Builder.AlternateTest exposing (suite)

{-| Regression tests for `Builder.alternate` auto-bumping `iterations` to `2`
when `iterations` is currently `Once` (the default).

This behavior is shared by every engine that re-exports `Builder.alternate`:
`Keyframe.alternate`, `Sub.alternate`, `WAAPI.alternate`,
`ScrollTimeline.alternate`, and `ViewTimeline.alternate`.

-}

import Anim.Internal.Builder as Builder
import Expect
import Test exposing (Test, describe, test)


animBuilder : Builder.AnimBuilder { withIterations : (), withAlternate : (), withLoopForever : () }
animBuilder =
    Builder.init []


suite : Test
suite =
    describe "Builder.alternate"
        [ test "auto-bumps iterations to Times 2 when iterations is Once" <|
            \_ ->
                animBuilder
                    |> Builder.alternate
                    |> Builder.getIterations
                    |> Expect.equal (Builder.Times 2)
        , test "sets animationDirection to Alternate" <|
            \_ ->
                animBuilder
                    |> Builder.alternate
                    |> Builder.getAnimationDirection
                    |> Expect.equal Builder.Alternate
        , test "preserves an explicit iterations count set before alternate" <|
            \_ ->
                animBuilder
                    |> Builder.iterations 5
                    |> Builder.alternate
                    |> Builder.getIterations
                    |> Expect.equal (Builder.Times 5)
        , test "preserves loopForever when alternate is called after" <|
            \_ ->
                animBuilder
                    |> Builder.loopForever
                    |> Builder.alternate
                    |> Builder.getIterations
                    |> Expect.equal Builder.Infinite
        , test "preserves loopForever when alternate is called before" <|
            \_ ->
                animBuilder
                    |> Builder.alternate
                    |> Builder.loopForever
                    |> Builder.getIterations
                    |> Expect.equal Builder.Infinite
        , test "does not override an explicit iterations count set after alternate" <|
            \_ ->
                animBuilder
                    |> Builder.alternate
                    |> Builder.iterations 7
                    |> Builder.getIterations
                    |> Expect.equal (Builder.Times 7)
        ]
