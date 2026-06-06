module Anim.Property.Scale exposing
    ( Builder, AnimGroupName
    , init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    , spring
    , Bounds, AxisBounds, bounds
    , clampX, clampY, clampZ
    , unclampX, unclampY, unclampZ
    , set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ
    )

{-| Scale elements along the X, Y, and Z axes.

**Default**: 1.0 (original size) for all axes

When no start value is configured, the default will be used.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


### Absolute

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


### Relative

Move by a delta on one or more axes instead of to a fixed scale. The end value
is `current + delta` for each axis, where `current` is the configured start
scale or the default when no start value has been set on that axis.

@docs byXYZ, byXY, byXZ, byX, byYZ, byY, byZ


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


## Responsive Animations

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.


### Bounds

Keep scale values within a range you choose. Values outside the range are clamped
to the nearest boundary. An animation that is within the bounds, either mid-flight or
paused, will be remapped proportionally inside the bounds.

@docs Bounds, AxisBounds, bounds


## Clamping

Keep scale values on each axis within a range you choose.

Values outside the range are clamped to the nearest boundary.

Similar to `bounds`, but without proportional remapping.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    motion : Scale.Builder { eng | withTiming : () } -> Scale.Builder { eng | withTiming : () }
    motion =
        Scale.duration 600
            >> Scale.easing Easing.easeOutCubic

    update msg model =
        case msg of
            ZoomChanged factor ->
                let
                    ( animState, cmd ) =
                        WAAPI.retarget model.animState <|
                            Scale.for animGroupName
                                >> Scale.clampX 0.5 2.0
                                >> Scale.clampY 0.5 2.0
                                >> Scale.toXY factor factor
                                >> Scale.build
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clampX, clampY, clampZ


### Unclamp

@docs unclampX, unclampY, unclampZ


## Snap

Snap to a specific scale, cancelling any in-flight animation on this property.

@docs set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Scale as SB
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


{-| Set the starting X and Y scale. Z is left unchanged (or 1.0 if not set).
-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    SB.fromXY


{-| Set the starting X and Z scale. Y is left unchanged (or 1.0 if not set).
-}
fromXZ : Float -> Float -> Builder eng -> Builder eng
fromXZ =
    SB.fromXZ


{-| Set the starting X scale. Y and Z are left unchanged (or 1.0 if not set).
-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    SB.fromX


{-| Set the starting Y and Z scale. X is left unchanged (or 1.0 if not set).
-}
fromYZ : Float -> Float -> Builder eng -> Builder eng
fromYZ =
    SB.fromYZ


{-| Set the starting Y scale. X and Z are left unchanged (or 1.0 if not set).
-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    SB.fromY


{-| Set the starting Z scale. X and Y are left unchanged (or 1.0 if not set).
-}
fromZ : Float -> Builder eng -> Builder eng
fromZ =
    SB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target scale (uniform across all axes).

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


{-| Set the target X, Y, and Z scale.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXYZ 1.5 2.0 0.8
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
toXYZ =
    SB.toXYZ


{-| Set the target X and Y scale. Z is left unchanged (or 1.0 if not set).
-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    SB.toXY


{-| Set the target X and Z scale. Y is left unchanged (or 1.0 if not set).
-}
toXZ : Float -> Float -> Builder eng -> Builder eng
toXZ =
    SB.toXZ


{-| Set the target X scale. Y and Z are left unchanged (or 1.0 if not set).
-}
toX : Float -> Builder eng -> Builder eng
toX =
    SB.toX


{-| Set the target Y and Z scale. X is left unchanged (or 1.0 if not set).
-}
toYZ : Float -> Float -> Builder eng -> Builder eng
toYZ =
    SB.toYZ


{-| Set the target Y scale. X and Z are left unchanged (or 1.0 if not set).
-}
toY : Float -> Builder eng -> Builder eng
toY =
    SB.toY


{-| Set the target Z scale. X and Y are left unchanged (or 1.0 if not set).
-}
toZ : Float -> Builder eng -> Builder eng
toZ =
    SB.toZ



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap to a uniform scale on all three axes silently, cancelling
any in-flight animation on this property.
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
-- BY
-- ============================================================


{-| Move by a delta on the X, Y, and Z axes.
-}
byXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
byXYZ =
    SB.byXYZ


{-| Move by a delta on the X and Y axes. Z is unaffected.
-}
byXY : Float -> Float -> Builder eng -> Builder eng
byXY =
    SB.byXY


{-| Move by a delta on the X and Z axes. Y is unaffected.
-}
byXZ : Float -> Float -> Builder eng -> Builder eng
byXZ =
    SB.byXZ


{-| Move by a delta on the X axis. Y and Z are unaffected.
-}
byX : Float -> Builder eng -> Builder eng
byX =
    SB.byX


{-| Move by a delta on the Y and Z axes. X is unaffected.
-}
byYZ : Float -> Float -> Builder eng -> Builder eng
byYZ =
    SB.byYZ


{-| Move by a delta on the Y axis. X and Z are unaffected.
-}
byY : Float -> Builder eng -> Builder eng
byY =
    SB.byY


{-| Move by a delta on the Z axis. X and Y are unaffected.
-}
byZ : Float -> Builder eng -> Builder eng
byZ =
    SB.byZ



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    SB.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    SB.duration


{-| The speed represents how much the scale factor changes per second.

For example, a scale animation from `1.0` to `5.0` with a speed of `2.0`
will take 2 seconds to complete.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    SB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    Scale.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    SB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Scale.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    SB.spring



-- ============================================================
-- RESIZE
-- ============================================================


{-| A numeric range with `min` and `max` boundaries.
-}
type alias Bounds =
    { min : Float, max : Float }


{-| Per-axis resize ranges. `Nothing` leaves an axis untouched.

    { x = Just { min = 1, max = 2 }
    , y = Nothing
    , z = Nothing
    }

-}
type alias AxisBounds =
    { x : Maybe Bounds
    , y : Maybe Bounds
    , z : Maybe Bounds
    }


{-| Scale's contribution to a resize bounds directive for the named anim group.
Compose inside an engine's `onResize` callback:

    WAAPI.onResize model.animState <|
        Scale.bounds "cube"
            { x = Just { min = 1, max = newWidth / cubeSize }
            , y = Just { min = 1, max = newHeight / cubeSize }
            , z = Nothing
            }

You can set the bounds for multiple anim groups in one call by composing more entries.

Leave an axis as `Nothing` to ignore it. Bounds are scale multipliers,
not pixels. Only callable from inside an `onResize` callback - the
`withBounds` capability on the builder type is what gates it.

-}
bounds : AnimGroupName -> AxisBounds -> AnimBuilder { eng | withBounds : () } -> AnimBuilder { eng | withBounds : () }
bounds name ranges =
    SB.for name >> SB.bounds ranges >> SB.build



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis scale within `[min, max]` for this animation group.

The range stays in effect for future animations
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
