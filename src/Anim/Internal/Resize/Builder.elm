module Anim.Internal.Resize.Builder exposing
    ( AxisBounds
    , AxisResult
    , Bounds
    , applyAxis
    , isEmpty
    )

-- ============================================================
-- TYPES
-- ============================================================


type alias Bounds =
    { min : Float, max : Float }


type alias AxisBounds =
    { x : Maybe Bounds
    , y : Maybe Bounds
    , z : Maybe Bounds
    }


type alias AxisResult =
    { start : Float
    , end : Float
    , current : Float
    }



-- ============================================================
-- QUERY
-- ============================================================


{-| A resize directive with no populated axes is treated as a no-op by engines.
-}
isEmpty : AxisBounds -> Bool
isEmpty bounds_ =
    bounds_.x == Nothing && bounds_.y == Nothing && bounds_.z == Nothing



-- ============================================================
-- BUILD
-- ============================================================


{-| Compute new per-axis start / end / current under proportional resize.

`maybeNewBounds = Nothing` leaves the axis untouched.

`maybePrevBounds` is the bounds last applied to this axis (i.e. the viewport
range that `currentV` is currently positioned within). When `Just`, the
current value is proportionally remapped from the previous viewport range
into the new viewport range. When `Nothing` (first resize for this axis,
no prior bounds recorded) the leg endpoints `startV..endV` are used as a
fallback reference range - correct when the user's animation endpoints
align with the original viewport extents.

Using the previous bounds (rather than the current leg endpoints) is what
preserves visual position across **successive** resizes during a single
in-flight one-shot leg: a leg-derived `oldRange` would compress the
proportional remap once the leg has been replayed inside a smaller viewport.

The result is **canonical leg geometry**: `start = legStart`, `end = legEnd`,
`current = newCurrent`. Engines never receive a pre-rebased leg from this
function. Every engine sees the same shape for looping and one-shot
animations, so a single resize (orientation flip) and successive resizes
(drag) drive identical code paths downstream.

-}
applyAxis :
    Maybe Bounds
    -> Maybe Bounds
    -> Float
    -> Float
    -> Float
    -> AxisResult
applyAxis maybePrevBounds maybeNewBounds startV endV currentV =
    case maybeNewBounds of
        Nothing ->
            { start = startV, end = endV, current = currentV }

        Just b ->
            if startV == endV then
                let
                    clamped =
                        clamp b.min b.max currentV
                in
                { start = clamped, end = clamped, current = clamped }

            else
                let
                    forward =
                        startV <= endV

                    ( legStart, legEnd ) =
                        if forward then
                            ( b.min, b.max )

                        else
                            ( b.max, b.min )

                    ( oldMin, oldRange ) =
                        case maybePrevBounds of
                            Just pb ->
                                ( pb.min, pb.max - pb.min )

                            Nothing ->
                                ( min startV endV
                                , abs (endV - startV)
                                )

                    newRange =
                        b.max - b.min

                    newCurrent =
                        if oldRange == 0 then
                            clamp b.min b.max currentV

                        else
                            b.min + ((currentV - oldMin) / oldRange) * newRange
                in
                { start = legStart
                , end = legEnd
                , current = newCurrent
                }
