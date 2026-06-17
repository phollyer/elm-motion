module Anim.Property.Opacity exposing
    ( Builder, AnimGroupName
    , init
    , begin, end
    , from
    , to
    , by
    , delay, duration, speed
    , easing
    , spring
    , clamp
    , unclamp
    , set
    )

{-| Animate the opacity of elements.

**Default**: 1.0 (fully opaque)

When no start value is configured, the default will be used.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init


# Build

@docs begin, end


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs from


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


### Absolute

@docs to


### Relative

Move by a delta instead of to a fixed opacity. The end value is
`current + delta` where `current` is the live animated opacity.

Only available on the Sub and WAAPI engines. Using these with any
other engine results in a type error.

@docs by


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

Values outside the range are clamped to the nearest boundary.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    update msg model =
        case msg of
            HoverEnded ->
                let
                    ( animState, cmd ) =
                        WAAPI.animate model.animState <|
                            Opacity.begin
                                >> Opacity.clamp 0.2 1.0
                                >> Opacity.end
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clamp


### Unclamp

@docs unclamp


## Snap

Snap to a specific opacity, cancelling any in-flight animation on this property.

@docs set

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
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
        Opacity.begin
            >> ... -- Configure and build the animation

-}
begin : AnimBuilder eng -> Builder eng
begin animBuilder =
    case IB.getCurrentAnimGroupName animBuilder of
        Just animGroupName ->
            OB.for animGroupName animBuilder

        Nothing ->
            OB.for "" animBuilder


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.begin
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Opacity.end
            >> ... -- continue with animation

-}
end : Builder eng -> AnimBuilder eng
end =
    OB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting opacity.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.begin
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
        Opacity.begin
            >> Opacity.to 0.5
            >> ... -- continue with animation

-}
to : Float -> Builder eng -> Builder eng
to =
    OB.to << O.fromFloat



-- ============================================================
-- BY
-- ============================================================


{-| Move by a delta instead of to a fixed opacity.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.begin
            >> Opacity.by 0.25
            >> ... -- continue with animation

-}
by : Float -> Builder eng -> Builder eng
by =
    OB.by



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    OB.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    OB.duration


{-| The speed represents how much the opacity value changes per second.

Since opacity ranges from 0.0 (transparent) to 1.0 (opaque), a speed of `2.0`
means the opacity will change by 2.0 units per second (e.g., from 0.0 to 1.0
takes 0.5 seconds).

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    OB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Motion.Easing exposing (Easing(..))

    Opacity.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    OB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Opacity.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    OB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep opacity within `min` and `max` values. If `min > max` the values are flipped.
-}
clamp : Float -> Float -> Builder eng -> Builder eng
clamp =
    OB.clamp


{-| Remove the opacity range for this animation group. Does nothing if no range is set.
-}
unclamp : Builder eng -> Builder eng
unclamp =
    OB.unclamp



-- ============================================================
-- SNAP
-- ============================================================


{-| Snap the opacity to a specific value.
-}
set : Float -> Builder eng -> Builder eng
set =
    OB.set << O.fromFloat
