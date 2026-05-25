module Anim.Internal.Engine.Shared.PlayState exposing
    ( PlayState(..)
    , isActive
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , toCssString
    )

-- ============================================================
-- TYPES
-- ============================================================


type PlayState
    = NotStarted
    | Running
    | Paused
    | Reset
    | Complete
    | Cancelled



-- ============================================================
-- QUERY
-- ============================================================


isActive : PlayState -> Bool
isActive state =
    case state of
        Running ->
            True

        Paused ->
            True

        _ ->
            False


isCancelled : PlayState -> Bool
isCancelled state =
    state == Cancelled


isComplete : PlayState -> Bool
isComplete state =
    state == Complete


isPaused : PlayState -> Bool
isPaused state =
    state == Paused


isRunning : PlayState -> Bool
isRunning state =
    state == Running



-- ============================================================
-- VIEW
-- ============================================================


toCssString : PlayState -> String
toCssString state =
    case state of
        Running ->
            "running"

        Paused ->
            "paused"

        _ ->
            ""
