module Anim.Resize exposing
    ( Builder
    , AxisBounds, Bounds, bounds
    )

{-| This module provides a way to set new bounds for
an animation when a resize event occurs. Use the [bounds](#bounds) function
in conjunction with an Engine's `onResize` function and the Engine will apply
the new bounds on the next animation frame.


# When to use `Resize.bounds`

`Resize.bounds` is the explicit, pixel-keyed escape hatch for animations whose
endpoints are computed from layout dimensions in `Px`. Before reaching for it,
consider whether a relative [`Anim.Unit`](Anim-Unit) (`Percent`, `Vw`, `Vh`,
`Rem`, `Em`) on the animated property would let the browser handle resize for
you:

  - **CSS Transition, Keyframe, WAAPI, ScrollTimeline, ViewTimeline** —
    rendered values follow the unit. Setting `Translate.cssUnit Unit.Vw` (or
    the engine-level [`cssUnit`](Anim-Engine-WAAPI#cssUnit)) makes the browser
    re-evaluate values against the current viewport on every frame; no
    `onResize` plumbing is needed.
      - **Sub** — `Translate`, `Size`, and `PerspectiveOrigin` preserve relative
        units in render output. During `Sub.onResize`, numeric remaps are applied
        only to `Px` axes for resize-aware properties (`Translate`,
        `PerspectiveOrigin`); non-`Px` axes are left unchanged so CSS units can
        track layout natively. `Size` is currently not remapped by
        `Resize.bounds` in Sub.
  - **WAAPI** — supports both. Use relative units when endpoints scale with
    layout, and `Resize.bounds` when endpoints are derived from `Px`
    measurements (e.g. `containerWidth - boxWidth`).

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
