module Anim.Resize exposing
    ( Builder
    , AxisBounds, Bounds, bounds
    , Position
    )

{-| This module provides resize builders to feed new bounds into an Engine
when a window resize occurs.

The Engines and their animations know nothing about the outside world, or your layout intentions,
so they can't automatically respond to layout changes. Standard CSS media queries or JavaScript
can't help here because the world of the animation is controlled by the Engine. Therefore, this module
provides a way to feed new [Bounds](#bounds) into the Engine when a resize event occurs.

Resize is always proportional - endpoints adopt the new bounds, the current value is
proportionally remapped from the old range into the new range, and the normalised
timing cursor is preserved across the resize.

Use with the [WAAPI](Anim.Engine.WAAPI) or [Sub](Anim.Engine.Sub) Engines
to make animations responsive to layout changes.

After a resize event, pass the new bounds to the engine:

    OnResize width height ->
        let
            newBounds =
                { x = Just { min = 0, max = toFloat width }
                , y = Just { min = 0, max = toFloat height }
                , z = Nothing
                }
        in
        ( { model
            | animState =
                Sub.onResize model.animState <|
                    Resize.bounds "box" newBounds
          }
        , Cmd.none
        )

The animation will respect the new bounds on the next animation frame after resize.


# Builder

@docs Builder


# Bounds

@docs AxisBounds, Bounds, bounds


# Position

@docs Position

-}

import Anim.Internal.Resize.Builder as Internal


{-| Opaque builder type consumed by [WAAPI.onResize](Anim.Engine.WAAPI#responsive-animations) or [Sub.onResize](Anim.Engine.Sub).

This builder stores per-group resize bounds so the Engine can apply them when handling a resize event.

-}
type alias Builder =
    Internal.Builder


{-| Inclusive numeric range for one axis.
-}
type alias AxisBounds =
    { min : Float, max : Float }


{-| Per-axis resize bounds. Leave an axis as `Nothing` to ignore it.

    { x = Just { min = 0, max = newWidth - boxSize }
    , y = Nothing
    , z = Nothing
    }

-}
type alias Bounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    , z : Maybe AxisBounds
    }


{-| Per-axis one-shot position snap for a static axis on resize.

A static axis is one whose `start` equals its `end` (the axis is not
animating). Setting an axis to `Just newPos` snaps that axis to the new
position. Setting an axis to `Nothing` leaves it untouched. Snapping is
ignored on an animating axis (`start /= end`) - use [`Bounds`](#Bounds)
to retarget animating axes instead.

    { x = Just newAreaSize.width
    , y = Nothing
    , z = Nothing
    }

-}
type alias Position =
    { x : Maybe Float
    , y : Maybe Float
    , z : Maybe Float
    }


{-| Set group-wide bounds for an animation group when a resize occurs.

    Sub.onResize model.animState <|
        Resize.bounds "box" <|
            { x = Just { min = 0, max = newWidth - boxWidth }
            , y = Nothing
            , z = Nothing
            }

    Sub.onResize model.animState <|
        Resize.bounds "box" newBoxBounds
            >> Resize.bounds "otherGroup" otherBounds

-}
bounds : Internal.AnimGroupName -> Bounds -> Builder -> Builder
bounds =
    Internal.bounds
