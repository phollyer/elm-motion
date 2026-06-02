module Anim.Property.Rotate exposing
    ( Builder, AnimGroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, clampZ, unclampX, unclampY, unclampZ
    )

{-| Rotate elements around the X, Y, and Z axes.

**Default**: 0 degrees for all axes

When no start value is configured for any axis, the default will be used for that axis.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#start-values)
for details.

@docs fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#end-values)
for details.

@docs toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Snap

@docs set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ


## Timing

📖 See [Animation Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/)
for details.

@docs delay, duration, speed


## Easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/)
for details.

@docs easing


## Spring

📖 See [Spring](https://phollyer.github.io/elm-motion/animation/concepts/spring/)
for details.

@docs spring


## Clamping

Keep rotate values on each axis within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampX, clampY, clampZ, unclampX, unclampY, unclampZ

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Rotate as RB
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for rotate animations.
-}
type alias Builder eng =
    RB.RotateBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial X, Y, and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initXYZ "animGroupName" 45 30 60 ] }
        , Cmd.none
        )

-}
initXYZ : AnimGroupName -> Float -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXYZ animationKey x y z animBuilder =
    animBuilder
        |> for animationKey
        |> fromXYZ x y z
        |> toXYZ x y z
        |> build


{-| Set the initial X and Y rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initXY "animGroupName" 45 30 ] }
        , Cmd.none
        )

-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXY animationKey x y animBuilder =
    animBuilder
        |> for animationKey
        |> fromXY x y
        |> toXY x y
        |> build


{-| Set the initial X and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initXZ "animGroupName" 45 60 ] }
        , Cmd.none
        )

-}
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXZ animationKey x z animBuilder =
    animBuilder
        |> for animationKey
        |> fromXZ x z
        |> toXZ x z
        |> build


{-| Set the initial X rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initX "animGroupName" 45 ] }
        , Cmd.none
        )

-}
initX : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initX animationKey x animBuilder =
    animBuilder
        |> for animationKey
        |> fromX x
        |> toX x
        |> build


{-| Set the initial Y and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initYZ "animGroupName" 30 60 ] }
        , Cmd.none
        )

-}
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initYZ animationKey y z animBuilder =
    animBuilder
        |> for animationKey
        |> fromYZ y z
        |> toYZ y z
        |> build


{-| Set the initial Y rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initY "animGroupName" 30 ] }
        , Cmd.none
        )

-}
initY : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initY animationKey y animBuilder =
    animBuilder
        |> for animationKey
        |> fromY y
        |> toY y
        |> build


{-| Set the initial Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Rotate.initZ "animGroupName" 60 ] }
        , Cmd.none
        )

-}
initZ : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initZ animationKey z animBuilder =
    animBuilder
        |> for animationKey
        |> fromZ z
        |> toZ z
        |> build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a rotate animation `Builder` for the specified animation group.

Use this to start configuring a rotate animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    RB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Rotate.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    RB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X, Y, and Z rotations (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromXYZ 45 90 180
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
fromXYZ =
    RB.fromXYZ


{-| Set the starting X and Y rotations (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromXY 45 90
            >> ... -- continue with animation

The Z rotation remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    RB.fromXY


{-| Set the starting X and Z rotations (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromXZ 45 180
            >> ... -- continue with animation

The Y rotation remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder eng -> Builder eng
fromXZ =
    RB.fromXZ


{-| Set the starting X-axis rotation (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromX 45
            >> ... -- continue with animation

The Y and Z rotations remain unchanged, or zero if not set.

-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    RB.fromX


{-| Set the starting Y and Z rotations (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromYZ 90 180
            >> ... -- continue with animation

The X rotation remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder eng -> Builder eng
fromYZ =
    RB.fromYZ


{-| Set the starting Y-axis rotation (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromY 90
            >> ... -- continue with animation

The X and Z rotations remain unchanged, or zero if not set.

-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    RB.fromY


{-| Set the starting Z-axis rotation (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromZ 180
            >> ... -- continue with animation

The X and Y rotations remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder eng -> Builder eng
fromZ =
    RB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X, Y, and Z rotations for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toXYZ 45 90 180
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
toXYZ =
    RB.toXYZ


{-| Set the target X and Y rotations for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toXY 45 90
            >> ... -- continue with animation

-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    RB.toXY


{-| Set the target X and Z rotations for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toXZ 45 180
            >> ... -- continue with animation

-}
toXZ : Float -> Float -> Builder eng -> Builder eng
toXZ =
    RB.toXZ


{-| Set the target X-axis rotation for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toX 45
            >> ... -- continue with animation

The Y and Z rotations remain unchanged, or zero if not set.

-}
toX : Float -> Builder eng -> Builder eng
toX =
    RB.toX


{-| Set the target Y and Z rotations for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toYZ 90 180
            >> ... -- continue with animation

-}
toYZ : Float -> Float -> Builder eng -> Builder eng
toYZ =
    RB.toYZ


{-| Set the target Y-axis rotation for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toY 90
            >> ... -- continue with animation

The X and Z rotations remain unchanged, or zero if not set.

-}
toY : Float -> Builder eng -> Builder eng
toY =
    RB.toY


{-| Set the target Z-axis rotation for the current animation group (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> ... -- continue with animation

The X and Y rotations remain unchanged, or zero if not set.

-}
toZ : Float -> Builder eng -> Builder eng
toZ =
    RB.toZ



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap the uniform target rotation angles silently, cancelling
any in-flight animation on this property.
-}
set : Float -> Builder eng -> Builder eng
set xyz =
    RB.setXYZ xyz xyz xyz


{-| Snap target X, Y and Z angles.
-}
setXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
setXYZ =
    RB.setXYZ


{-| Snap target X and Y angles, preserving the current Z angle.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    RB.setXY


{-| Snap target X and Z angles, preserving the current Y angle.
-}
setXZ : Float -> Float -> Builder eng -> Builder eng
setXZ =
    RB.setXZ


{-| Snap target X angle, preserving the current Y and Z angles.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    RB.setX


{-| Snap target Y and Z angles, preserving the current X angle.
-}
setYZ : Float -> Float -> Builder eng -> Builder eng
setYZ =
    RB.setYZ


{-| Snap target Y angle, preserving the current X and Z angles.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    RB.setY


{-| Snap target Z angle, preserving the current X and Y angles.
-}
setZ : Float -> Builder eng -> Builder eng
setZ =
    RB.setZ



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many degrees the element rotates per second.

For example, lets take a rotation animation from `0°` to `180°`.
A speed of `90.0` means the element will rotate 90 degrees per second, so our animation will take 2 seconds to complete (0° -> 90° in 1 second, then 90° -> 180° in the next second).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.speed 90
            >> ... -- continue with animation

Similarly, a speed of `180.0` would complete the same animation in 1 second, and a speed of `45.0` would take 4 seconds.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    RB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    RB.duration


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    RB.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    RB.easing



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
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    RB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis rotation within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclampX](#unclampX). If `min > max`, the values are swapped.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    RB.clampX


{-| Keep the Y axis rotation within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    RB.clampY


{-| Keep the Z axis rotation within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampZ : Float -> Float -> Builder eng -> Builder eng
clampZ =
    RB.clampZ


{-| Remove the X axis range for this animation group. Does nothing if no range is set.
-}
unclampX : Builder eng -> Builder eng
unclampX =
    RB.unclampX


{-| Remove the Y axis range for this animation group. Does nothing if no range is set.
-}
unclampY : Builder eng -> Builder eng
unclampY =
    RB.unclampY


{-| Remove the Z axis range for this animation group. Does nothing if no range is set.
-}
unclampZ : Builder eng -> Builder eng
unclampZ =
    RB.unclampZ
