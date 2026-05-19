module Anim.Resize exposing
    ( Builder
    , policy, Policy
    , proportional, clamp, retarget
    , AxisBounds, Bounds, bounds
    )

{-| This module provides resize policies and builders to configure how animations
should respond to changes in window size.

The Engines and their animations know nothing about the outside world, or your layout intentions,
so they can't automatically respond to layout changes. Standard CSS media queries or JavaScript
can't help here because the world of the animation is controlled by the Engine. Therefore, this module
provides a way to declare a resize [Policy](#policy) for an animation, and then feed new [Bounds](#bounds)
into the Engine when a resize event occurs.

The Engine applies the declared [Policy](#policy) to the new [Bounds](#bounds) and adjusts the animation
accordingly on the next animation frame after resize. Swapping the policy mid-animation also takes
effect immediately against the most recent known bounds, so you can change strategy on the fly
without waiting for another resize event.

You can declare different policies for different animation groups, change them at any time or override them
on a per-property basis, giving you fine-grained control over how each animation responds to resize.

Use with the [WAAPI](Anim.Engine.WAAPI) or [Sub](Anim.Engine.Sub) Engines
to make animations responsive to layout changes.

Setup has two very simple steps:

1.  Declare a [Policy](#policy) in your Engine's `init` function.

        Sub.init <|
            [ Resize.policy "box" Resize.proportional
            ... -- other init configs
            ]

2.  After a resize event, pass the new bounds to the engine.

```
    OnResize width height ->
        let
            bounds =
                { x = Just { min = 0, max = toFloat width }
                , y = Just { min = 0, max = toFloat height }
                , z = Nothing
                }
        in
        ({ model | animState =
            Sub.onResize model.animState <|
                Resize.bounds "box" bounds
        }
        , Cmd.none
        )
```

The animation will respect the new bounds and the rules of the declared policy on the next animation frame after resize.


# Builder

@docs Builder


# Policy

A `Policy` expresses how an animation should respond when its [Bounds](#bounds) change.
Use one of the three presets to set the Policy once in your Engine's `init`
function, or call `Resize.policy` in any `AnimBuilder` pipeline to swap policy
on the fly. After the first resize event, in-place swaps take effect immediately
against the most recent known bounds. Before any resize has fired there are no
bounds to apply against, so the animation continues exactly as authored and the
new policy is used on the next resize.

@docs policy, Policy


## Presets

@docs proportional, clamp, retarget


# Bounds

@docs AxisBounds, Bounds, bounds

-}

import Anim.Builder as AnimBuilder
import Anim.Internal.Builder as Builder
import Anim.Internal.Resize.Builder as Internal


{-| Opaque builder type consumed by [WAAPI.onResize](Anim.Engine.WAAPI#responsive-animations) or [Sub.onResize](Anim.Engine.Sub).

This builder stores resize policies so the Engine can apply them when handling a resize event.

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


{-| Set a group-wide resize policy for an animation group.

    Sub.init <|
        [ Resize.policy "box" Resize.proportional
        ... -- other init configs
        ]

This can be orverridden on a per-property basis.

Resolution order:

1.  Per-property policy
2.  Group-wide policy
3.  Library default `Resize.proportional`

-}
policy : Internal.AnimGroupName -> Policy -> AnimBuilder.AnimBuilder mode -> AnimBuilder.AnimBuilder mode
policy =
    Builder.policy


{-| A resize policy describing how an animation should respond when its
bounds change. Build one with [`proportional`](#proportional),
[`clamp`](#clamp), or [`retarget`](#retarget).
-}
type alias Policy =
    Internal.Policy


{-| Preserve normalised progress: the range tracks the new bounds, the
current value is proportionally remapped, and the time cursor is preserved.

Best for looping or ping-pong motion where rhythm should continue smoothly
as the container changes size.

-}
proportional : Policy
proportional =
    Internal.proportionalPolicy


{-| Keep the configured start and end values, clamping them into the new
bounds.

Best when bounds are a safety limit rather than the track itself. The
authored start/end are remembered across resizes: shrinking clips them into
the new bounds, and widening restores them up to the authored extremes
(never past).

-}
clamp : Policy
clamp =
    Internal.clampPolicy


{-| Use the new bounds as the range, keep the current value in place, then
solve timing from that current value.

Best for motion that should continue toward the resized boundary while
minimising visual jumps at the moment of resize.

-}
retarget : Policy
retarget =
    Internal.retargetPolicy
