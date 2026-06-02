module Anim.Property.PerspectiveOrigin exposing
    ( Builder, AnimGroupName
    , initXY, initX, initY
    , initUnit, initUnitX, initUnitY
    , for, build
    , cssUnit, cssUnitX, cssUnitY
    , from, fromXY, fromX, fromY
    , to, toXY, toX, toY
    , set, setXY, setX, setY
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, unclampX, unclampY
    , Bounds, AxisBounds, bounds
    )

{-| Animate the CSS `perspective-origin` property, which controls the vanishing point
for 3D transforms applied to a parent element.

**Default unit**: `%`. Use [`cssUnit`](#cssUnit) to switch to other CSS length units.

**Default value**: `50% 50%` (center of the element)

**Note**: This module is for _animating_ `perspective-origin`, if all you need is to
set a static `perspective-origin` without animation, use the
[View3D.perspectiveOrigin](Anim.Extra.View3D#perspectiveOrigin) function instead, or set the `style`
attribute yourself in your view.


# Types

@docs Builder, AnimGroupName


# Initialize

The default unit for `perspective-origin` is `Percent`. Use
[`initUnit`](#initUnit) (or [`initUnitX`](#initUnitX) /
[`initUnitY`](#initUnitY)) to switch the unit used by subsequent `init*`
calls.

@docs initXY, initX, initY


## Initial Unit

Set the length [Unit](Anim-Unit#Unit) used by subsequent `init*` calls.
Order matters - `initUnit*` only affects `init*` calls that follow it in
the pipeline. Defaults to `Percent`.

    import Anim.Unit exposing (Unit(..))

    init _ =
        ( { animState =
                Engine.init
                    [ PerspectiveOrigin.initUnit Px
                        >> PerspectiveOrigin.initXY "vp" 200 150
                    ]
          }
        , Cmd.none
        )

@docs initUnit, initUnitX, initUnitY


# Build

@docs for, build


# Configure


## Unit

Use [`cssUnit`](#cssUnit) to select the CSS length unit (`Px`, `Percent`, `Vw`,
`Vh`, `Rem`, `Em`) for all `from`, `to`, `toX`, and `toY` calls. Defaults to
percentages.

@docs cssUnit, cssUnitX, cssUnitY


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#start-values)
for details.

@docs from, fromXY, fromX, fromY


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#end-values)
for details.

@docs to, toXY, toX, toY


## Snap

@docs set, setXY, setX, setY


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

Keep perspective-origin values on each axis within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampX, clampY, unclampX, unclampY


## Resize

Set how perspective-origin responds to viewport/container resize and provide
new bounds during `onResize`.

@docs Bounds, AxisBounds, bounds

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
import Anim.Internal.Builder.PerspectiveOrigin as PB
import Anim.Unit as Unit
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for perspective-origin animations.
-}
type alias Builder eng =
    PB.PerspectiveOriginBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial perspective origin on both axes. Uses whichever
[Unit](Anim-Unit#Unit) was most recently selected by [`initUnit`](#initUnit) /
[`initUnitX`](#initUnitX) / [`initUnitY`](#initUnitY) upstream in the pipeline
(defaults to `Percent`).

    import Anim.Engine.* as Engine
    import Anim.Property.PerspectiveOrigin as PerspectiveOrigin

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ PerspectiveOrigin.initXY "animGroupName" 50 50 ] }
        , Cmd.none
        )

-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXY animationKey x y animBuilder =
    animBuilder
        |> for animationKey
        |> PB.applyInitCssUnit
        |> fromXY x y
        |> toXY x y
        |> build


{-| Set the initial X-axis perspective origin. Uses whichever
[Unit](Anim-Unit#Unit) was most recently selected by [`initUnit`](#initUnit) /
[`initUnitX`](#initUnitX) upstream in the pipeline (defaults to `Percent`).
-}
initX : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initX animationKey x animBuilder =
    animBuilder
        |> for animationKey
        |> PB.applyInitCssUnit
        |> fromX x
        |> toX x
        |> build


{-| Set the initial Y-axis perspective origin. Uses whichever
[Unit](Anim-Unit#Unit) was most recently selected by [`initUnit`](#initUnit) /
[`initUnitY`](#initUnitY) upstream in the pipeline (defaults to `Percent`).
-}
initY : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initY animationKey y animBuilder =
    animBuilder
        |> for animationKey
        |> PB.applyInitCssUnit
        |> fromY y
        |> toY y
        |> build


{-| Set the length [Unit](Anim-Unit#Unit) used by every subsequent `init*` call
for `PerspectiveOrigin` values. Defaults to `Percent`.

Order matters - only `init*` calls downstream of this setter in the pipeline
are affected; calls upstream keep their previously selected unit (or `Percent`).
Later per-axis setters ([`initUnitX`](#initUnitX), [`initUnitY`](#initUnitY))
override this setting on the relevant axis.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ PerspectiveOrigin.initUnit Px
            >> PerspectiveOrigin.initXY "vp" 200 150
        ]

-}
initUnit : Unit.Unit -> AnimBuilder eng -> AnimBuilder eng
initUnit =
    IB.setPerspectiveOriginInitCssUnit


{-| Set the X-axis unit used by every subsequent `init*` call for
`PerspectiveOrigin` values. Overrides any unit set by [`initUnit`](#initUnit)
on the X axis.
-}
initUnitX : Unit.Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitX =
    IB.setPerspectiveOriginInitCssUnitX


{-| Set the Y-axis unit used by every subsequent `init*` call for
`PerspectiveOrigin` values. Overrides any unit set by [`initUnit`](#initUnit)
on the Y axis.
-}
initUnitY : Unit.Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitY =
    IB.setPerspectiveOriginInitCssUnitY



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a perspective origin animation `Builder` for the specified animation group.

Use this to start configuring a perspective origin animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    PB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> PerspectiveOrigin.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    PB.build



-- ============================================================
-- UNIT
-- ============================================================


{-| Set the length [Unit](Anim-Unit#Unit) used to render this property's values.

Defaults to `Px`. Setting a relative unit (`Percent`, `Vw`, `Vh`, `Rem`, `Em`)
makes the browser re-evaluate the rendered perspective origin against current
layout, so the animation follows resize automatically.

    import Anim.Unit as Unit

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.toXY 25 75
            >> PerspectiveOrigin.cssUnit Unit.Percent
            >> PerspectiveOrigin.build

This setting takes precedence over any [length](Anim-Engine-WAAPI#cssUnit) set
on the engine, and over the legacy [`px`](#px) / [`percent`](#percent)
switchers (which only choose between pixels and percentages).

`Sub` renders non-`Px` units normally. During `onResize` bounds remapping,
only `Px` perspective-origin axes are remapped; non-`Px` axes are left
unchanged.

-}
cssUnit : Unit.Unit -> Builder eng -> Builder eng
cssUnit =
    PB.cssUnit


{-| Set the length [Unit](Anim-Unit#Unit) used to render the X-axis
perspective-origin value. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitX` setter for the X axis.
-}
cssUnitX : Unit.Unit -> Builder eng -> Builder eng
cssUnitX =
    PB.cssUnitX


{-| Set the length [Unit](Anim-Unit#Unit) used to render the Y-axis
perspective-origin value. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitY` setter for the Y axis.
-}
cssUnitY : Unit.Unit -> Builder eng -> Builder eng
cssUnitY =
    PB.cssUnitY



-- ============================================================
-- FROM
-- ============================================================


{-| Set the uniform starting X and Y values.
-}
from : Float -> Builder eng -> Builder eng
from xy =
    PB.fromXY xy xy


{-| Set the starting X and Y values.
-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    PB.fromXY


{-| Set the starting X value, preserving the current Y value.
-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    PB.fromX


{-| Set the starting Y value, preserving the current X value.
-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    PB.fromY



-- ============================================================
-- TO
-- ============================================================


{-| Set the uniform target X and Y values.
-}
to : Float -> Builder eng -> Builder eng
to xy =
    PB.toXY xy xy


{-| Set the target X and Y values.
-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    PB.toXY


{-| Set the target X value, preserving the current Y value.
-}
toX : Float -> Builder eng -> Builder eng
toX =
    PB.toX


{-| Set the target Y value, preserving the current X value.
-}
toY : Float -> Builder eng -> Builder eng
toY =
    PB.toY



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap the uniform target X and Y values silently, cancelling any
in-flight animation on this property.
-}
set : Float -> Builder eng -> Builder eng
set xy =
    PB.setXY xy xy


{-| Snap the target X and Y values.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    PB.setXY


{-| Snap the target X value, preserving the current Y value.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    PB.setX


{-| Snap the target Y value, preserving the current X value.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    PB.setY



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    PB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    PB.duration


{-| The speed represents how many units per second the perspective origin changes.

For example, an animation from `0` to `200px` with a speed of `100.0` will take 2 seconds to complete.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.speed 100
            >> ... -- continue with animation

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    PB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    PB.easing



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
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    PB.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis perspective-origin within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclampX](#unclampX). If `min > max`, the values are swapped.
The active unit (percent or px) on each value is preserved.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    PB.clampX


{-| Keep the Y axis perspective-origin within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    PB.clampY


{-| Remove the X axis range for this animation group. Does nothing if no range is set.
-}
unclampX : Builder eng -> Builder eng
unclampX =
    PB.unclampX


{-| Remove the Y axis range for this animation group. Does nothing if no range is set.
-}
unclampY : Builder eng -> Builder eng
unclampY =
    PB.unclampY



-- ============================================================
-- RESIZE
-- ============================================================


{-| A numeric range with `min` and `max` boundaries.
-}
type alias Bounds =
    { min : Float, max : Float }


{-| Per-axis resize ranges. `Nothing` leaves an axis untouched.
`z` is ignored for this property.

    { x = Just { min = 0, max = 100 }
    , y = Nothing
    , z = Nothing
    }

-}
type alias AxisBounds =
    { x : Maybe Bounds
    , y : Maybe Bounds
    , z : Maybe Bounds
    }


{-| Perspective-origin's contribution to a resize bounds directive for the
named anim group.

Compose inside an engine's `onResize` callback.

Leave an axis as `Nothing` to ignore it. `z` is ignored for this property.
Only callable from inside an `onResize` callback - the `withBounds`
capability on the builder type is what gates it.

-}
bounds : AnimGroupName -> AxisBounds -> AnimBuilder { eng | withBounds : () } -> AnimBuilder { eng | withBounds : () }
bounds name ranges =
    PB.for name >> PB.bounds ranges >> PB.build
