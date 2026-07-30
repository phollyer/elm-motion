module Anim.Engine.Sub.TimingQuerySpec exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Expect
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


{-| A single 1000ms translate on the group.
-}
singleAnim : Sub.EngineBuilder -> Sub.EngineBuilder
singleAnim =
    Sub.for groupName
        >> Translate.begin
        >> Translate.toX 100
        >> Translate.duration 1000
        >> Translate.end


{-| A 200ms delay in front of a 1000ms translate, giving a 1200ms total span.
-}
delayedAnim : Sub.EngineBuilder -> Sub.EngineBuilder
delayedAnim =
    Sub.for groupName
        >> Translate.begin
        >> Translate.toX 100
        >> Translate.delay 200
        >> Translate.duration 1000
        >> Translate.end


{-| Two properties with different durations; the group span is the longest.
-}
mixedAnim : Sub.EngineBuilder -> Sub.EngineBuilder
mixedAnim =
    Sub.for groupName
        >> Translate.begin
        >> Translate.toX 100
        >> Translate.duration 1000
        >> Translate.end
        >> Opacity.begin
        >> Opacity.to 1
        >> Opacity.duration 400
        >> Opacity.end


tick : Float -> Sub.AnimState -> Sub.AnimState
tick deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


start : (Sub.EngineBuilder -> Sub.EngineBuilder) -> Sub.AnimState
start builder =
    Sub.init [ Translate.initXY groupName 0 0 ]
        |> (\s -> Sub.animate s builder)


suite : Test
suite =
    describe "Anim.Engine.Sub timing queries"
        [ describe "getDuration"
            [ test "reports the configured duration for a single property" <|
                \_ ->
                    start singleAnim
                        |> Sub.getDuration groupName
                        |> Expect.equal (Just 1000)
            , test "includes the delay in the total span" <|
                \_ ->
                    start delayedAnim
                        |> Sub.getDuration groupName
                        |> Expect.equal (Just 1200)
            , test "reports the longest property span in a mixed group" <|
                \_ ->
                    start mixedAnim
                        |> Sub.getDuration groupName
                        |> Expect.equal (Just 1000)
            , test "is stable across frames" <|
                \_ ->
                    start singleAnim
                        |> tick 300
                        |> Sub.getDuration groupName
                        |> Expect.equal (Just 1000)
            , test "returns Nothing for an unknown group" <|
                \_ ->
                    start singleAnim
                        |> Sub.getDuration "missing"
                        |> Expect.equal Nothing
            ]
        , describe "getElapsed"
            [ test "is zero before any frame" <|
                \_ ->
                    start singleAnim
                        |> Sub.getElapsed groupName
                        |> Expect.equal (Just 0)
            , test "advances with elapsed frame time" <|
                \_ ->
                    start singleAnim
                        |> tick 300
                        |> Sub.getElapsed groupName
                        |> Expect.equal (Just 300)
            , test "counts delay time before motion begins" <|
                \_ ->
                    start delayedAnim
                        |> tick 100
                        |> Sub.getElapsed groupName
                        |> Expect.equal (Just 100)
            , test "is clamped to the total duration once complete" <|
                \_ ->
                    start singleAnim
                        |> tick 5000
                        |> Sub.getElapsed groupName
                        |> Expect.equal (Just 1000)
            , test "returns Nothing for an unknown group" <|
                \_ ->
                    start singleAnim
                        |> Sub.getElapsed "missing"
                        |> Expect.equal Nothing
            ]
        , describe "getRemaining"
            [ test "equals the full duration before any frame" <|
                \_ ->
                    start singleAnim
                        |> Sub.getRemaining groupName
                        |> Expect.equal (Just 1000)
            , test "equals duration minus elapsed mid-flight" <|
                \_ ->
                    start singleAnim
                        |> tick 300
                        |> Sub.getRemaining groupName
                        |> Expect.equal (Just 700)
            , test "is zero once complete" <|
                \_ ->
                    start singleAnim
                        |> tick 5000
                        |> Sub.getRemaining groupName
                        |> Expect.equal (Just 0)
            , test "returns Nothing for an unknown group" <|
                \_ ->
                    start singleAnim
                        |> Sub.getRemaining "missing"
                        |> Expect.equal Nothing
            ]
        ]
