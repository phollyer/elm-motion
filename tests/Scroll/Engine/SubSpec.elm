module Scroll.Engine.SubSpec exposing (suite)

{-| Public-surface tests for `Scroll.Engine.Sub`.

The engine's behaviour lives in `Scroll.Internal.Engine.Sub` (covered by
`Scroll.Internal.Engine.TestSub`). This suite targets the logic the
public module adds on top, which the internal tests do not exercise:

  - `containerToId` / `containerFromId` - the `Container` <-> id mapping
    threaded through every control and query, including the `Document`
    special case.
  - `fromInternalEvent` - the internal-to-public `ScrollEvent` mapping
    for each variant surfaced synchronously through `update`.

Internal messages are constructed and fed through the public `update`,
whose `ScrollMsg` / `ScrollState` are transparent aliases of the
internal types.

-}

import Expect
import Scroll.Engine.Sub as Sub
import Scroll.Internal.Engine.Sub as Internal
import Scroll.Internal.ScrollBuilder as SB
import Scroll.Internal.Shared.ScrollTarget as ScrollTarget
import Test exposing (Test, describe, test)


containerId : String
containerId =
    "test-container"


targetY : Float
targetY =
    1000


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


{-| Start a scroll for the given container id through the public update,
bypassing the real DOM query that would normally produce the message.
-}
startScrollFor : String -> Sub.ScrollState
startScrollFor cid =
    let
        target =
            ScrollTarget.for cid
                |> ScrollTarget.toXY 0 targetY

        builder =
            SB.init
                |> SB.for cid
                |> SB.toXY 0 targetY
                |> SB.duration 1000
                |> SB.build

        ( state, _, _ ) =
            Sub.update identity
                (Internal.DomQueriesCompleted "1" target builder domResult)
                Sub.init
    in
    state


startScroll : Sub.ScrollState
startScroll =
    startScrollFor containerId


{-| Advance a freshly started scroll by one frame and return the emitted
public events. The first frame flushes the queued `Started` event and
completes the (zero) start delay, so it also emits a `Progress`.
-}
firstFrameEvents : Sub.ScrollState -> List Sub.ScrollEvent
firstFrameEvents state =
    let
        ( _, events, _ ) =
            Sub.update identity (Internal.ScrollFrame 500) state
    in
    events


{-| Run the scroll to completion (one delay-completing frame, then one
frame long enough to reach progress 1.0) and return the final events.
-}
completingFrameEvents : Sub.ScrollState -> List Sub.ScrollEvent
completingFrameEvents state =
    let
        ( afterDelay, _, _ ) =
            Sub.update identity (Internal.ScrollFrame 500) state

        ( _, events, _ ) =
            Sub.update identity (Internal.ScrollFrame 2000) afterDelay
    in
    events


{-| Extract the progress value of the first `Progress` event whose
container matches, or `Nothing` if no such event was emitted.
-}
progressFor : Sub.Container -> List Sub.ScrollEvent -> Maybe Float
progressFor container =
    List.filterMap
        (\event ->
            case event of
                Sub.Progress eventContainer _ progress ->
                    if eventContainer == container then
                        Just progress

                    else
                        Nothing

                _ ->
                    Nothing
        )
        >> List.head



suite : Test
suite =
    describe "Scroll.Engine.Sub (public surface)"
        [ containerMappingTests
        , eventMappingTests
        , controlTests
        ]



-- ============================================================
-- CONTAINER <-> ID MAPPING (containerToId)
-- ============================================================


containerMappingTests : Test
containerMappingTests =
    describe "Container id mapping in queries"
        [ test "isRunning maps a named Container to the engine id" <|
            \_ ->
                startScroll
                    |> Sub.isRunning (Sub.Container containerId)
                    |> Expect.equal (Just True)
        , test "isRunning maps Document to the \"document\" id" <|
            \_ ->
                startScrollFor "document"
                    |> Sub.isRunning Sub.Document
                    |> Expect.equal (Just True)
        , test "getPosition returns the start position for a named Container" <|
            \_ ->
                startScroll
                    |> Sub.getPosition (Sub.Container containerId)
                    |> Expect.equal (Just { x = 0, y = 0 })
        , test "getPositionX / getPositionY resolve the Container id" <|
            \_ ->
                ( Sub.getPositionX (Sub.Container containerId) startScroll
                , Sub.getPositionY (Sub.Container containerId) startScroll
                )
                    |> Expect.equal ( Just 0, Just 0 )
        , test "getPosition resolves the Document id" <|
            \_ ->
                startScrollFor "document"
                    |> Sub.getPosition Sub.Document
                    |> Expect.equal (Just { x = 0, y = 0 })
        , test "anyRunning is Just True while a scroll is registered" <|
            \_ ->
                startScroll
                    |> Sub.anyRunning
                    |> Expect.equal (Just True)
        , test "anyRunning is Nothing with no scrolls" <|
            \_ ->
                Sub.init
                    |> Sub.anyRunning
                    |> Expect.equal Nothing
        ]



-- ============================================================
-- INTERNAL -> PUBLIC EVENT MAPPING (fromInternalEvent)
-- ============================================================


eventMappingTests : Test
eventMappingTests =
    describe "fromInternalEvent maps engine events to the public type"
        [ test "surfaces Started for a named Container" <|
            \_ ->
                firstFrameEvents startScroll
                    |> List.member (Sub.Started (Sub.Container containerId))
                    |> Expect.equal True
        , test "maps the \"document\" id to Document in Started" <|
            \_ ->
                firstFrameEvents (startScrollFor "document")
                    |> List.member (Sub.Started Sub.Document)
                    |> Expect.equal True
        , test "surfaces Progress with the container mapped and progress in [0,1]" <|
            \_ ->
                firstFrameEvents startScroll
                    |> progressFor (Sub.Container containerId)
                    |> Maybe.map (\p -> p >= 0 && p <= 1)
                    |> Expect.equal (Just True)
        , test "surfaces Ended when the scroll completes" <|
            \_ ->
                completingFrameEvents startScroll
                    |> List.member (Sub.Ended (Sub.Container containerId))
                    |> Expect.equal True
        , test "emits no events for the initial empty state" <|
            \_ ->
                let
                    ( _, events, _ ) =
                        Sub.update identity (Internal.ScrollFrame 500) Sub.init
                in
                events
                    |> Expect.equal []
        ]



-- ============================================================
-- CONTROLS (containerToId through stop/pause/resume/reset/restart)
-- ============================================================


controlTests : Test
controlTests =
    describe "controls resolve the Container id"
        [ test "stop jumps a named Container to its target" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop (Sub.Container containerId) identity startScroll
                in
                stopped
                    |> Sub.getPosition (Sub.Container containerId)
                    |> Expect.equal (Just { x = 0, y = targetY })
        , test "stop marks the Container as no longer running" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop (Sub.Container containerId) identity startScroll
                in
                stopped
                    |> Sub.isRunning (Sub.Container containerId)
                    |> Expect.equal (Just False)
        , test "stop resolves the Document id" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop Sub.Document identity (startScrollFor "document")
                in
                stopped
                    |> Sub.getPosition Sub.Document
                    |> Expect.equal (Just { x = 0, y = targetY })
        , test "pause marks the Container as no longer running" <|
            \_ ->
                startScroll
                    |> Sub.pause (Sub.Container containerId)
                    |> Sub.isRunning (Sub.Container containerId)
                    |> Expect.equal (Just False)
        , test "resume returns a paused Container to running" <|
            \_ ->
                startScroll
                    |> Sub.pause (Sub.Container containerId)
                    |> Sub.resume (Sub.Container containerId)
                    |> Sub.isRunning (Sub.Container containerId)
                    |> Expect.equal (Just True)
        , test "reset returns a stopped Container to the start" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop (Sub.Container containerId) identity startScroll

                    ( afterReset, _ ) =
                        Sub.reset (Sub.Container containerId) identity stopped
                in
                afterReset
                    |> Sub.getPosition (Sub.Container containerId)
                    |> Expect.equal (Just { x = 0, y = 0 })
        , test "restart re-runs a stopped Container" <|
            \_ ->
                let
                    ( stopped, _ ) =
                        Sub.stop (Sub.Container containerId) identity startScroll

                    ( afterRestart, _ ) =
                        Sub.restart (Sub.Container containerId) identity stopped
                in
                afterRestart
                    |> Sub.isRunning (Sub.Container containerId)
                    |> Expect.equal (Just True)
        ]
