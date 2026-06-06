module Anim.Property.Skew exposing
    ( Builder, AnimGroupName
    , initXY, initX, initY
    , for, build
    , fromXY, fromX, fromY
    , toXY, toX, toY
    , byXY, byX, byY
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY
    , unclampX, unclampY
    , setXY, setX, setY
    )

{-| Skew elements along the X and Y axes.

**Default**: 0 degrees for both axes

When no start value is configured for any axis, the default will be used.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXY, initX, initY


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs fromXY, fromX, fromY


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


### Absolute

@docs toXY, toX, toY


### Relative

Move by a delta instead of to a fixed skew. The end value
is `current + delta` where `current` is the live animated skew.

Only available on the Sub and WAAPI engines. Using these with any other engine results in a type error.

@docs byXY, byX, byY


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

Values outside the range are clamped to the nearest boundary.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    update msg model =
        case msg of
            TiltChanged xDeg yDeg ->
                let
                    ( animState, cmd ) =
                        WAAPI.animate model.animState <|
                            Skew.for animGroupName
                                >> Skew.clampX -30 30
                                >> Skew.clampY -30 30
                                >> Skew.build
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clampX, clampY


### Unclamp

@docs unclampX, unclampY


## Snap

Snap to a specific skew, cancelling any in-flight animation on this property.

@docs setXY, setX, setY

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


{-| Set the starting X skew (degrees). Y is left unchanged (or 0 if not set).
-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    SB.fromX


{-| Set the starting Y skew (degrees). X is left unchanged (or 0 if not set).
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


{-| Set the target X skew (degrees). Y is left unchanged (or 0 if not set).
-}
toX : Float -> Builder eng -> Builder eng
toX =
    SB.toX


{-| Set the target Y skew (degrees). X is left unchanged (or 0 if not set).
-}
toY : Float -> Builder eng -> Builder eng
toY =
    SB.toY



-- ============================================================
-- SNAP
-- ============================================================


{-| Snap target X and Y skew angles.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    SB.setXY


{-| Snap target X angle, preserving the current Y angle.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    SB.setX


{-| Snap target Y angle, preserving the current X angle.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    SB.setY



-- ============================================================
-- BY
-- ============================================================


{-| Move by a delta on the X and Y axes.
-}
byXY : Float -> Float -> Builder eng -> Builder eng
byXY =
    SB.byXY


{-| Move by a delta on the X axis. Y is unaffected.
-}
byX : Float -> Builder eng -> Builder eng
byX =
    SB.byX


{-| Move by a delta on the Y axis. X is unaffected.
-}
byY : Float -> Builder eng -> Builder eng
byY =
    SB.byY



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


{-| The speed represents how many degrees the skew changes per second.

For example, a skew animation from `0` to `30` degrees with a speed of `15.0`
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

    Skew.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    SB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Skew.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    SB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis skew within `min` and `max` values. If `min > max` the values are flipped.
-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    SB.clampX


{-| Keep the Y axis skew within `min` and `max` values. If `min > max` the values are flipped.
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
