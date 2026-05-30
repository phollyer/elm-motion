module Scroll.Engine.CmdSpec exposing (suite)

{-| Tests for the public `Scroll.Engine.Cmd` engine surface.

The engine itself returns an opaque `Cmd msg` value that cannot be
inspected in pure Elm. These tests therefore focus on:

  - The public setters (`delay`, `duration`, `speed`, `easing`) being
    correct aliases for the internal `Scroll.Internal.ScrollBuilder`
    setters. We pipe a `ScrollBuilder` through each public setter and
    read the value back via the internal getters.
  - The `scroll` trigger having the documented signature
    `msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg`. The test
    binds the result to a variable of that type — a regression that
    changed the signature would fail to compile.
  - `scroll` not crashing when given an empty builder. The actual
    `Cmd` cannot be inspected, but the construction path must succeed
    without an exception.

-}

import Expect
import Motion.Easing exposing (Easing(..))
import Scroll.Builder as Scroll
import Scroll.Engine.Cmd as Cmd
import Scroll.Internal.ScrollBuilder as SB
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Scroll.Engine.Cmd"
        [ setterAliasTests
        , triggerTypeTests
        ]



-- ============================================================
-- SETTER ALIASES
-- ============================================================


setterAliasTests : Test
setterAliasTests =
    describe "public setters delegate to Scroll.Internal.ScrollBuilder"
        [ test "Cmd.delay sets the global delay" <|
            \_ ->
                SB.init
                    |> Cmd.delay 250
                    |> SB.getDelayWithDefault
                    |> Expect.equal 250
        , test "Cmd.duration sets the timing to Duration" <|
            \_ ->
                SB.init
                    |> Cmd.duration 1000
                    |> SB.getTimeSpecWithDefault
                    |> Expect.equal (Duration 1000)
        , test "Cmd.speed sets the timing to Speed" <|
            \_ ->
                SB.init
                    |> Cmd.speed 200
                    |> SB.getTimeSpecWithDefault
                    |> Expect.equal (Speed 200)
        , test "Cmd.easing sets the global easing" <|
            \_ ->
                SB.init
                    |> Cmd.easing BounceOut
                    |> SB.getEasingWithDefault
                    |> Expect.equal BounceOut
        , test "later setter wins (duration overrides speed)" <|
            \_ ->
                SB.init
                    |> Cmd.speed 500
                    |> Cmd.duration 750
                    |> SB.getTimeSpecWithDefault
                    |> Expect.equal (Duration 750)
        , test "later setter wins (easing replaces easing)" <|
            \_ ->
                SB.init
                    |> Cmd.easing Linear
                    |> Cmd.easing QuintOut
                    |> SB.getEasingWithDefault
                    |> Expect.equal QuintOut
        ]



-- ============================================================
-- TRIGGER TYPE
-- ============================================================


triggerTypeTests : Test
triggerTypeTests =
    describe "Cmd.scroll signature and basic dispatch"
        [ test "Cmd.scroll typechecks as msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg" <|
            \_ ->
                let
                    typed : msg -> (Scroll.ScrollBuilder -> Scroll.ScrollBuilder) -> Cmd msg
                    typed =
                        Cmd.scroll
                in
                typed |> always Expect.pass
        , test "Cmd.scroll with no targets does not crash" <|
            \_ ->
                let
                    cmd : Cmd ()
                    cmd =
                        Cmd.scroll () identity
                in
                cmd |> always Expect.pass
        , test "Cmd.scroll with a configured target does not crash" <|
            \_ ->
                let
                    cmd : Cmd ()
                    cmd =
                        Cmd.scroll ()
                            (Cmd.delay 100
                                >> Cmd.duration 500
                                >> Cmd.easing QuintOut
                                >> Scroll.forDocument
                                >> Scroll.toTop
                                >> Scroll.build
                            )
                in
                cmd |> always Expect.pass
        ]
