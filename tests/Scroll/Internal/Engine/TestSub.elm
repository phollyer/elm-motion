module Scroll.Internal.Engine.TestSub exposing (suite)

import Expect
import Scroll.Internal.Engine.Sub as Sub
import Scroll.Internal.ScrollBuilder as SB
import Scroll.Internal.Shared.ScrollTarget as ScrollTarget
import Test exposing (..)


containerId : String
containerId =
    "test-container"


targetY : Float
targetY =
    1000


buildScroll : SB.ScrollBuilder
buildScroll =
    SB.init
        |> SB.for containerId
        |> SB.toXY 0 targetY
        |> SB.duration 1000
        |> SB.build


scrollTarget : ScrollTarget.ScrollTarget
scrollTarget =
    ScrollTarget.for containerId
        |> ScrollTarget.toXY 0 targetY


domResult :
    { viewport :
        { scene : { width : Float, height : Float }
        , viewport : { x : Float, y : Float, width : Float, height : Float }
        }
    , containerElement : Maybe a
    , targetElement : Maybe b
    }
domResult =
    { viewport =
        { scene = { width = 1000, height = 5000 }
        , viewport = { x = 0, y = 0, width = 1000, height = 800 }
        }
    , containerElement = Nothing
    , targetElement = Nothing
    }


{-| Start a scroll by feeding `DomQueriesCompleted` directly into `update`,
bypassing the real DOM query that would normally produce that message.
-}
startScroll : Sub.ScrollState
startScroll =
    let
        ( state, _, _ ) =
            Sub.update identity
                identity
                (Sub.DomQueriesCompleted "1" scrollTarget buildScroll domResult)
                Sub.init
    in
    state


suite : Test
suite =
    describe "Scroll.Internal.Engine.Sub"
        [ setupTests
        , stopTests
        , resetTests
        , restartTests
        , pauseResumeTests
        , controlChainingTests
        ]


setupTests : Test
setupTests =
    describe "DomQueriesCompleted"
        [ test "registers the scroll so it is running" <|
            \_ ->
                startScroll
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just True)
        , test "records the start position from the viewport" <|
            \_ ->
                startScroll
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = 0 })
        ]


stopTests : Test
stopTests =
    describe "stop"
        [ test "jumps the position to the target" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop containerId identity startScroll
                in
                stopped
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = targetY })
        , test "marks the scroll as no longer running" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop containerId identity startScroll
                in
                stopped
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just False)
        , test "keeps the scroll in state so reset can find it" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop containerId identity startScroll

                    ( afterReset, _ ) =
                        Sub.reset containerId identity stopped
                in
                afterReset
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = 0 })
        , test "keeps the scroll in state so restart can find it" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop containerId identity startScroll

                    ( afterRestart, _ ) =
                        Sub.restart containerId identity stopped
                in
                afterRestart
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just True)
        ]


resetTests : Test
resetTests =
    describe "reset"
        [ test "jumps the position back to the start" <|
            \_ ->
                let
                    ( afterReset, _ ) =
                        Sub.reset containerId identity startScroll
                in
                afterReset
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = 0 })
        , test "leaves the scroll paused" <|
            \_ ->
                let
                    ( afterReset, _ ) =
                        Sub.reset containerId identity startScroll
                in
                afterReset
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just False)
        ]


restartTests : Test
restartTests =
    describe "restart"
        [ test "jumps the position back to the start" <|
            \_ ->
                let
                    ( afterRestart, _ ) =
                        Sub.restart containerId identity startScroll
                in
                afterRestart
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = 0 })
        , test "leaves the scroll running" <|
            \_ ->
                let
                    ( afterRestart, _ ) =
                        Sub.restart containerId identity startScroll
                in
                afterRestart
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just True)
        ]


pauseResumeTests : Test
pauseResumeTests =
    describe "pause / resume"
        [ test "pause marks the scroll as not running" <|
            \_ ->
                startScroll
                    |> Sub.pause containerId
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just False)
        , test "resume marks a paused scroll as running again" <|
            \_ ->
                startScroll
                    |> Sub.pause containerId
                    |> Sub.resume containerId
                    |> Sub.isRunning containerId
                    |> Expect.equal (Just True)
        , test "pause does not change the position" <|
            \_ ->
                startScroll
                    |> Sub.pause containerId
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = 0 })
        ]


controlChainingTests : Test
controlChainingTests =
    describe "stop then control chains (regression for dropped-entry bug)"
        [ test "stop -> reset -> restart leaves the scroll running from start" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop containerId identity startScroll

                    ( afterReset, _ ) =
                        Sub.reset containerId identity stopped

                    ( afterRestart, _ ) =
                        Sub.restart containerId identity afterReset
                in
                Expect.all
                    [ \state -> Sub.isRunning containerId state |> Expect.equal (Just True)
                    , \state -> Sub.getScrollPosition containerId state |> Expect.equal (Just { x = 0, y = 0 })
                    ]
                    afterRestart
        , test "stop -> stop is idempotent" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop containerId identity startScroll

                    ( stoppedAgain, _ ) =
                        Sub.stop containerId identity stopped
                in
                stoppedAgain
                    |> Sub.getScrollPosition containerId
                    |> Expect.equal (Just { x = 0, y = targetY })
        ]
