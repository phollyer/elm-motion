module Anim.Property.Skew exposing
    ( Builder, AnimGroupName
    , initXY, initX, initY
    , for, build
    , fromXY, fromX, fromY
    , toXY, toX, toY
    , setXY, setX, setY
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, unclampX, unclampY
    )

{-| Skew elements along the X and Y axes.

**Default**: 0 degrees for both axes

When no start value is configured for any axis, the default will be used.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXY, initX, initY


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#start-values)
for details.

@docs fromXY, fromX, fromY


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#end-values)
for details.

@docs toXY, toX, toY


## Snap

@docs setXY, setX, setY


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

Keep skew values on each axis within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampX, clampY, unclampX, unclampY

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Skew as SB
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for skew animations.
-}
type alias Builder eng =
    SB.SkewBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Turn the `AnimBuilder` into a skew animation `Builder` for the specified animation group.

Use this to start configuring a skew animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Skew.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    SB.for


{-| Set the initial X and Y skew.

    import Anim.Engine.* as Engine
    import Anim.Property.Skew as Skew

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Skew.initXY "animGroupName" 12 6 ] }
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


{-| Set the initial X skew.

    import Anim.Engine.* as Engine
    import Anim.Property.Skew as Skew

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Skew.initX "animGroupName" 12 ] }
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


{-| Set the initial Y skew.

    import Anim.Engine.* as Engine
    import Anim.Property.Skew as Skew

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Skew.initY "animGroupName" 8 ] }
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



-- ============================================================
-- BUILD
-- ============================================================


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Skew.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Skew.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    SB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X and Y skew (degrees).
-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    SB.fromXY


{-| Set the starting X skew (degrees).
-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    SB.fromX


{-| Set the starting Y skew (degrees).
-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    SB.fromY



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X and Y skew (degrees).
-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    SB.toXY


{-| Set the target X skew (degrees).
-}
toX : Float -> Builder eng -> Builder eng
toX =
    SB.toX


{-| Set the target Y skew (degrees).
-}
toY : Float -> Builder eng -> Builder eng
toY =
    SB.toY



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap skew to specified angles silently, cancelling any in-flight
animation on this property.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    SB.setXY


{-| Snap the target X value, preserving the current Y value.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    SB.setX


{-| Snap the target Y value, preserving the current X value.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    SB.setY



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many degrees the skew changes per second.

For example, a skew animation from `0` to `30` degrees with a speed of `15.0` will take 2 seconds to complete.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 30 0
            >> Skew.speed 15.0
            >> ... -- continue with animation

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    SB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    SB.duration


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    SB.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.easing EaseInOut
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
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    SB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis skew within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclampX](#unclampX). If `min > max`, the values are swapped.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    SB.clampX


{-| Keep the Y axis skew within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    SB.clampY


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
