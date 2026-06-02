module Anim.Property.Opacity exposing
    ( Builder, AnimGroupName
    , init
    , for, build
    , from
    , to
    , set
    , delay, duration, speed
    , easing
    , spring
    , clamp, unclamp
    )

{-| Animate the opacity of elements.

**Default**: 1.0 (fully opaque)

When no start value is configured, the default will be used.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#start-values)
for details.

@docs from


## End Value

@docs to


## Snap

@docs set


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

Keep opacity within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clamp, unclamp

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Opacity as OB
import Anim.Internal.Property.Opacity as O
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for opacity animations.
-}
type alias Builder eng =
    OB.OpacityBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial opacity.

Use this to initialize the opacity in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Opacity as Opacity

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Opacity.init "animGroupName" 0.5 ] }
        , Cmd.none
        )

-}
init : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
init animationKey value animBuilder =
    animBuilder
        |> OB.for animationKey
        |> OB.from (O.fromFloat value)
        |> OB.to (O.fromFloat value)
        |> OB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into an opacity animation `Builder` for the specified animation group.

Use this to start configuring an opacity animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    OB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Opacity.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    OB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting opacity.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.from 1.0
            >> ... -- continue with animation

-}
from : Float -> Builder eng -> Builder eng
from =
    OB.from << O.fromFloat



-- ============================================================
-- TO
-- ============================================================


{-| Set the target opacity for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> ... -- continue with animation

-}
to : Float -> Builder eng -> Builder eng
to =
    OB.to << O.fromFloat



-- ============================================================
-- SET
-- ============================================================


{-| Snap the opacity to a value silently, cancelling any in-flight
animation on this property.

Use this when a layout change or external event invalidates the
current animation and you want the property to jump to a new value
without interpolation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.set 0
            >> Opacity.build

-}
set : Float -> Builder eng -> Builder eng
set =
    OB.set << O.fromFloat



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (opacity units per second).

The speed represents how much the opacity value changes per second. Since opacity
ranges from 0.0 (transparent) to 1.0 (opaque), a speed of `2.0` means the opacity
will change by 2.0 units per second (e.g., from 0.0 to 1.0 takes 0.5 seconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.0
            >> Opacity.speed 1.0
            >> ... -- continue with animation

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    OB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    OB.duration


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    OB.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    OB.easing



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
        Opacity.for "animGroupName"
            >> Opacity.to 1.0
            >> Opacity.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    OB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep opacity within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclamp](#unclamp). If `min > max`, the values are swapped.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clamp : Float -> Float -> Builder eng -> Builder eng
clamp =
    OB.clamp


{-| Remove the opacity range for this animation group. Does nothing if no range is set.
-}
unclamp : Builder eng -> Builder eng
unclamp =
    OB.unclamp
