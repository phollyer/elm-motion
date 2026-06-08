module Anim.Property.Rotate exposing
    ( Builder, AnimGroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , begin, end
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, clampZ
    , unclampX, unclampY, unclampZ
    , set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ
    )

{-| Rotate elements around the X, Y, and Z axes.

**Default**: 0 degrees for all axes

When no start value is configured for any axis, the default will be used for that axis.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs begin, end


# Configure


## Start Value

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


### Absolute

@docs toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


### Relative

Move by a delta instead of to a fixed rotation. The end
value is `current + delta` where `current` is the live animated rotation.

Only available on the Sub and WAAPI engines. Using these with any other engine results in a type error.

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


## Clamping

Keep rotate values on each axis within a range you choose.

Values outside the range are clamped to the nearest boundary.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    update msg model =
        case msg of
            KnobTurned angle ->
                let
                    ( animState, cmd ) =
                        WAAPI.animate model.animState <|
                            Rotate.begin
                                >> Rotate.clampZ -90 90
                                >> Rotate.end
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clampX, clampY, clampZ


### Unclamp

@docs unclampX, unclampY, unclampZ


## Snap

Snap to a specific rotation, cancelling any in-flight animation on this property.

@docs set, setXYZ, setXY, setXZ, setX, setYZ, setY, setZ

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
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
        |> RB.for animationKey
        |> fromXYZ x y z
        |> toXYZ x y z
        |> RB.build


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
        |> RB.for animationKey
        |> fromXY x y
        |> toXY x y
        |> RB.build


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
        |> RB.for animationKey
        |> fromXZ x z
        |> toXZ x z
        |> RB.build


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
        |> RB.for animationKey
        |> fromX x
        |> toX x
        |> RB.build


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
        |> RB.for animationKey
        |> fromYZ y z
        |> toYZ y z
        |> RB.build


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
        |> RB.for animationKey
        |> fromY y
        |> toY y
        |> RB.build


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
        |> RB.for animationKey
        |> fromZ z
        |> toZ z
        |> RB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a rotate animation `Builder` for the specified animation group.

Use this to start configuring a rotate animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.begin
            >> ... -- Configure and build the animation

-}
begin : AnimBuilder eng -> Builder eng
begin animBuilder =
    case IB.getCurrentAnimGroupName animBuilder of
        Just animGroupName ->
            RB.for animGroupName animBuilder

        Nothing ->
            RB.for "" animBuilder


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.begin
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Rotate.end
            >> ... -- continue with animation

-}
end : Builder eng -> AnimBuilder eng
end =
    RB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X, Y, and Z rotations (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.begin
            >> Rotate.fromXYZ 45 90 180
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
fromXYZ =
    RB.fromXYZ


{-| Set the starting X and Y rotations (degrees). Z is left unchanged (or 0 if not set).
-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    RB.fromXY


{-| Set the starting X and Z rotations (degrees). Y is left unchanged (or 0 if not set).
-}
fromXZ : Float -> Float -> Builder eng -> Builder eng
fromXZ =
    RB.fromXZ


{-| Set the starting X rotation (degrees). Y and Z are left unchanged (or 0 if not set).
-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    RB.fromX


{-| Set the starting Y and Z rotations (degrees). X is left unchanged (or 0 if not set).
-}
fromYZ : Float -> Float -> Builder eng -> Builder eng
fromYZ =
    RB.fromYZ


{-| Set the starting Y rotation (degrees). X and Z are left unchanged (or 0 if not set).
-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    RB.fromY


{-| Set the starting Z rotation (degrees). X and Y are left unchanged (or 0 if not set).
-}
fromZ : Float -> Builder eng -> Builder eng
fromZ =
    RB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X, Y, and Z rotations (degrees).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Rotate.begin
            >> Rotate.toXYZ 45 90 180
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
toXYZ =
    RB.toXYZ


{-| Set the target X and Y rotations (degrees). Z is left unchanged (or 0 if not set).
-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    RB.toXY


{-| Set the target X and Z rotations (degrees). Y is left unchanged (or 0 if not set).
-}
toXZ : Float -> Float -> Builder eng -> Builder eng
toXZ =
    RB.toXZ


{-| Set the target X rotation (degrees). Y and Z are left unchanged (or 0 if not set).
-}
toX : Float -> Builder eng -> Builder eng
toX =
    RB.toX


{-| Set the target Y and Z rotations (degrees). X is left unchanged (or 0 if not set).
-}
toYZ : Float -> Float -> Builder eng -> Builder eng
toYZ =
    RB.toYZ


{-| Set the target Y rotation (degrees). X and Z are left unchanged (or 0 if not set).
-}
toY : Float -> Builder eng -> Builder eng
toY =
    RB.toY


{-| Set the target Z rotation (degrees). X and Y are left unchanged (or 0 if not set).
-}
toZ : Float -> Builder eng -> Builder eng
toZ =
    RB.toZ



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap to a uniform rotation on all three axes silently, cancelling
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
-- BY
-- ============================================================


{-| Move by a delta on the X, Y, and Z axes.
-}
byXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
byXYZ =
    RB.byXYZ


{-| Move by a delta on the X and Y axes. Z is unaffected.
-}
byXY : Float -> Float -> Builder eng -> Builder eng
byXY =
    RB.byXY


{-| Move by a delta on the X and Z axes. Y is unaffected.
-}
byXZ : Float -> Float -> Builder eng -> Builder eng
byXZ =
    RB.byXZ


{-| Move by a delta on the X axis. Y and Z are unaffected.
-}
byX : Float -> Builder eng -> Builder eng
byX =
    RB.byX


{-| Move by a delta on the Y and Z axes. X is unaffected.
-}
byYZ : Float -> Float -> Builder eng -> Builder eng
byYZ =
    RB.byYZ


{-| Move by a delta on the Y axis. X and Z are unaffected.
-}
byY : Float -> Builder eng -> Builder eng
byY =
    RB.byY


{-| Move by a delta on the Z axis. X and Y are unaffected.
-}
byZ : Float -> Builder eng -> Builder eng
byZ =
    RB.byZ



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    RB.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    RB.duration


{-| The speed represents how many degrees the element rotates per second.

For example, a rotation animation from `0°` to `180°` with a speed of `90.0`
will take 2 seconds to complete.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    RB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    Rotate.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    RB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Rotate.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    RB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis rotation within `min` and `max` values. If `min > max` the values are flipped.
-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    RB.clampX


{-| Keep the Y axis rotation within `min` and `max` values. If `min > max` the values are flipped.
-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    RB.clampY


{-| Keep the Z axis rotation within `min` and `max` values. If `min > max` the values are flipped.
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
