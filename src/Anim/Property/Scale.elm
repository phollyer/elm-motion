module Anim.Property.Scale exposing
    ( Builder, AnimGroupName
    , init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, clampZ, unclampX, unclampY, unclampZ
    , bounds
    )

{-| Scale elements along the X, Y, and Z axes.

**Default**: 1.0 (original size) for all axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, the default will be used.

Any axis that is not defined in the animation configuration will remain unchanged,
or 1.0 if not set.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXY 1.5 1.5
            >> Scale.duration 1000
            >> Scale.easing EaseInOut
            >> Scale.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Snap

@docs set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring


## Bounds

Keep scale values on each axis within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampX, clampY, clampZ, unclampX, unclampY, unclampZ


## Resize

@docs bounds

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Scale as SB
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Resize as Resize
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for scale animations.
-}
type alias Builder eng =
    SB.ScaleBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial scale.

Use this to initialize the scale in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.init "animGroupName" 1.5 ] }
        , Cmd.none
        )

This is equivalent to calling `initXYZ 1.5 1.5 1.5`.

-}
init : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
init animationKey value animBuilder =
    animBuilder
        |> SB.for animationKey
        |> from value
        |> to value
        |> SB.build


{-| Set the initial X, Y, and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initXYZ "animGroupName" 1.5 1.2 1.0 ] }
        , Cmd.none
        )

-}
initXYZ : AnimGroupName -> Float -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXYZ animationKey x y z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromXYZ x y z
        |> SB.toXYZ x y z
        |> SB.build


{-| Set the initial X and Y scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initXY "animGroupName" 1.5 1.2 ] }
        , Cmd.none
        )

-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXY animationKey x y animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromXY x y
        |> SB.toXY x y
        |> SB.build


{-| Set the initial X and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initXZ "animGroupName" 1.5 1.0 ] }
        , Cmd.none
        )

-}
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXZ animationKey x z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromXZ x z
        |> SB.toXZ x z
        |> SB.build


{-| Set the initial X scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initX "animGroupName" 1.5 ] }
        , Cmd.none
        )

-}
initX : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initX animationKey x animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromX x
        |> SB.toX x
        |> SB.build


{-| Set the initial Y and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initYZ "animGroupName" 1.2 1.0 ] }
        , Cmd.none
        )

-}
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initYZ animationKey y z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromYZ y z
        |> SB.toYZ y z
        |> SB.build


{-| Set the initial Y scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initY "animGroupName" 1.2 ] }
        , Cmd.none
        )

-}
initY : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initY animationKey y animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromY y
        |> SB.toY y
        |> SB.build


{-| Set the initial Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Scale.initZ "animGroupName" 1.0 ] }
        , Cmd.none
        )

-}
initZ : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initZ animationKey z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromZ z
        |> SB.toZ z
        |> SB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a scale animation `Builder` for the specified animation group.

Use this to start configuring a scale animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    SB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Scale.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    SB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting scale (uniform across all axes).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.from 0.8
            >> ... -- continue with animation

This is equivalent to `Scale.fromXYZ 0.8 0.8 0.8`.

-}
from : Float -> Builder eng -> Builder eng
from uniformScale =
    SB.fromXYZ uniformScale uniformScale uniformScale


{-| Set the starting X, Y, and Z scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromXYZ 0.8 1.2 0.9
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
fromXYZ =
    SB.fromXYZ


{-| Set the starting X and Y scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromXY 0.8 1.2
            >> ... -- continue with animation

The Z scale remains unchanged, or 1.0 if not set.

-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    SB.fromXY


{-| Set the starting X and Z scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromXZ 0.8 0.9
            >> ... -- continue with animation

The Y scale remains unchanged, or 1.0 if not set.

-}
fromXZ : Float -> Float -> Builder eng -> Builder eng
fromXZ =
    SB.fromXZ


{-| Set the starting X-axis scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromX 0.8
            >> ... -- continue with animation

The Y and Z scales remain unchanged, or 1.0 if not set.

-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    SB.fromX


{-| Set the starting Y and Z scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromYZ 1.2 0.9
            >> ... -- continue with animation

The X scale remains unchanged, or 1.0 if not set.

-}
fromYZ : Float -> Float -> Builder eng -> Builder eng
fromYZ =
    SB.fromYZ


{-| Set the starting Y-axis scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromY 1.2
            >> ... -- continue with animation

The X and Z scales remain unchanged, or 1.0 if not set.

-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    SB.fromY


{-| Set the starting Z-axis scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromZ 1.1
            >> ... -- continue with animation

The X and Y scales remain unchanged, or 1.0 if not set.

-}
fromZ : Float -> Builder eng -> Builder eng
fromZ =
    SB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target scale for the current animation group (uniform across all axes).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> ... -- continue with animation

This is equivalent to `toXYZ 1.5 1.5 1.5`.

-}
to : Float -> Builder eng -> Builder eng
to targetScale =
    SB.toXYZ targetScale targetScale targetScale


{-| Set the target X, Y, and Z scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXYZ 1.5 2.0 0.8
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
toXYZ =
    SB.toXYZ


{-| Set the target X and Y scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXY 1.5 2.0
            >> ... -- continue with animation

The Z scale remains unchanged, or 1.0 if not set.

-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    SB.toXY


{-| Set the target X and Z scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXZ 1.5 0.8
            >> ... -- continue with animation

The Y scale remains unchanged, or 1.0 if not set.

-}
toXZ : Float -> Float -> Builder eng -> Builder eng
toXZ =
    SB.toXZ


{-| Set the target X-axis scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toX 2.0
            >> ... -- continue with animation

The Y and Z scales remain unchanged, or 1.0 if not set.

-}
toX : Float -> Builder eng -> Builder eng
toX =
    SB.toX


{-| Set the target Y and Z scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toYZ 1.5 0.8
            >> ... -- continue with animation

The X scale remains unchanged, or 1.0 if not set.

-}
toYZ : Float -> Float -> Builder eng -> Builder eng
toYZ =
    SB.toYZ


{-| Set the target Y-axis scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toY 1.5
            >> ... -- continue with animation

The X and Z scales remain unchanged, or 1.0 if not set.

-}
toY : Float -> Builder eng -> Builder eng
toY =
    SB.toY


{-| Set the target Z-axis scale for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toZ 0.8
            >> ... -- continue with animation

The X and Y scales remain unchanged, or 1.0 if not set.

-}
toZ : Float -> Builder eng -> Builder eng
toZ =
    SB.toZ



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap the uniform target scale silently, cancelling any
in-flight animation on this property.
-}
set : Float -> Builder eng -> Builder eng
set xyz =
    SB.setXYZ xyz xyz xyz


{-| Snap target X, Y and Z scales.
-}
setXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
setXYZ =
    SB.setXYZ


{-| Snap target X and Y scales, preserving the current Z scale.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    SB.setXY


{-| Snap target X and Z scales, preserving the current Y scale.
-}
setXZ : Float -> Float -> Builder eng -> Builder eng
setXZ =
    SB.setXZ


{-| Snap target X scale, preserving the current Y and Z scales.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    SB.setX


{-| Snap target Y and Z scales, preserving the current X scale.
-}
setYZ : Float -> Float -> Builder eng -> Builder eng
setYZ =
    SB.setYZ


{-| Snap target Y scale, preserving the current X and Z scales.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    SB.setY


{-| Snap target Z scale, preserving the current X and Y scales.
-}
setZ : Float -> Builder eng -> Builder eng
setZ =
    SB.setZ



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    SB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    SB.duration


{-| The speed represents how much the scale factor changes per second.

For example, lets take a scale animation from `1.0` to `5.0`.
A speed of `2.0` means the scale will change by 2.0 units per second, so our animation will take 2 seconds to complete (1.0 -> 3.0 in 1 second, then 3.0 -> 5.0 in the next second).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXYZ 5.0 5.0 5.0
            >> Scale.speed 2.0
            >> ... -- continue with animation

Similarly, a speed of `4.0` would complete the same animation in 1 second, and a speed of `1.0` would take 4 seconds.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    SB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    SB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring instead of an easing curve.

Spring-driven motion has _emergent_ duration: the motion ends when
the value has settled at the target. Any `duration` or `speed` set on
this property is ignored when a spring is used. `delay` is honoured.

Setting `spring` clears any previously-set `easing` on this property,
and vice versa — they are mutually exclusive.

    import Motion.Spring as Spring

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    SB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis scale within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclampX](#unclampX). If `min > max`, the values are swapped.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    SB.clampX


{-| Keep the Y axis scale within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    SB.clampY


{-| Keep the Z axis scale within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampZ : Float -> Float -> Builder eng -> Builder eng
clampZ =
    SB.clampZ


{-| Remove the X axis range for this animation group. Does nothing if no range is set.
-}
unclampX : Builder eng -> Builder eng
unclampX =
    SB.unclampX


{-| Remove the Y axis range for this animation group. Does nothing if no range is set.
-}
unclampY : Builder eng -> Builder eng
unclampY =
    SB.unclampY


{-| Remove the Z axis range for this animation group. Does nothing if no range is set.
-}
unclampZ : Builder eng -> Builder eng
unclampZ =
    SB.unclampZ



-- ============================================================
-- RESIZE
-- ============================================================


{-| Scale's contribution to a resize bounds directive for the named anim group.
Compose into the builder passed to an engine's `onResize`:

    WAAPI.onResize model.animState <|
        Scale.bounds "cube"
            { x = Just { min = 1, max = newWidth / cubeSize }
            , y = Just { min = 1, max = newHeight / cubeSize }
            , z = Nothing
            }

You can resize multiple anim groups in one call by composing more entries.

Leave an axis as `Nothing` to ignore it. Bounds are scale multipliers,
not pixels.

-}
bounds : AnimGroupName -> Resize.Bounds -> Resize.Builder -> Resize.Builder
bounds =
    ResizeBuilder.setScale
