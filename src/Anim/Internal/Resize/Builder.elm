module Anim.Internal.Resize.Builder exposing
    ( AxisBounds, Bounds, AxisResult
    , isEmpty, applyAxis
    )

{-| Math + types used by the engine resize pipeline.

This module no longer carries an accumulator: bounds directives are now
expressed through the regular `AnimBuilder` pipeline (a `RemapToBounds`
[`AnimationMode`](Anim-Internal-Builder#AnimationMode) attached to
specific property entries) and extracted by
[`partitionForResize`](Anim-Internal-Builder#partitionForResize). What
remains here is the per-axis math (`applyAxis`) and the shared
[`Bounds`](#Bounds) / [`AxisBounds`](#AxisBounds) record shapes used
throughout the engine internals.

-}


type alias AxisBounds =
    { min : Float, max : Float }


type alias Bounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    , z : Maybe AxisBounds
    }


type alias AxisResult =
    { start : Float
    , end : Float
    , current : Float
    }


{-| A resize directive with no populated axes is treated as a no-op by engines.
-}
isEmpty : Bounds -> Bool
isEmpty bounds_ =
    bounds_.x == Nothing && bounds_.y == Nothing && bounds_.z == Nothing


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
    Maybe AxisBounds
    -> Maybe AxisBounds
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
