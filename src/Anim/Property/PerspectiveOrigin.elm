module Anim.Property.PerspectiveOrigin exposing
    ( Builder, AnimGroupName
    , initXY, initX, initY
    , initUnit, initUnitX, initUnitY
    , for, build
    , cssUnit, cssUnitX, cssUnitY
    , from, fromXY, fromX, fromY
    , to, toXY, toX, toY
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, unclampX, unclampY
    , bounds, position
    )

{-| Animate the CSS `perspective-origin` property, which controls the vanishing point
for 3D transforms applied to a parent element.

**Default unit**: `%`. Use [`cssUnit`](#cssUnit) to switch to other CSS length units.

**Default value**: `50% 50%` (center of the element)

    import Easing exposing (Easing(..))


    -- Percentages (default)
    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 100
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.easing EaseInOut
            >> PerspectiveOrigin.build

    -- Pixels
    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.cssUnit Unit.Px
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.easing EaseInOut
            >> PerspectiveOrigin.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


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

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs from, fromXY, fromX, fromY


## End Value

@docs to, toXY, toX, toY


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring


## Bounds

Keep perspective-origin values on each axis within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampX, clampY, unclampX, unclampY


## Resize

Set how perspective-origin responds to viewport/container resize and provide
new bounds during `onResize`.

@docs bounds, position

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
import Anim.Internal.Builder.PerspectiveOrigin as PB
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Resize as Resize
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
type alias Builder mode =
    PB.PerspectiveOriginBuilder mode



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
initXY : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initX : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initY : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initUnit : Unit.Unit -> AnimBuilder mode -> AnimBuilder mode
initUnit =
    IB.setPerspectiveOriginInitCssUnit


{-| Set the X-axis unit used by every subsequent `init*` call for
`PerspectiveOrigin` values. Overrides any unit set by [`initUnit`](#initUnit)
on the X axis.
-}
initUnitX : Unit.Unit -> AnimBuilder mode -> AnimBuilder mode
initUnitX =
    IB.setPerspectiveOriginInitCssUnitX


{-| Set the Y-axis unit used by every subsequent `init*` call for
`PerspectiveOrigin` values. Overrides any unit set by [`initUnit`](#initUnit)
on the Y axis.
-}
initUnitY : Unit.Unit -> AnimBuilder mode -> AnimBuilder mode
initUnitY =
    IB.setPerspectiveOriginInitCssUnitY



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a perspective origin animation `Builder` for the specified animation group.

Use this to start configuring a perspective origin animation.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder mode -> Builder mode
for =
    PB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> PerspectiveOrigin.build
            >> ... -- continue with animation

-}
build : Builder mode -> AnimBuilder mode
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

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.toXY 25 75
            >> PerspectiveOrigin.cssUnit Unit.Percent
            >> PerspectiveOrigin.build

This setting takes precedence over any [length](Anim-Engine-WAAPI#cssUnit) set
on the engine, and over the legacy [`px`](#px) / [`percent`](#percent)
switchers (which only choose between pixels and percentages).

The `Sub` engine currently only supports `Px`; setting a non-`Px` unit on a
perspective-origin targeted at `Sub` reports an error and falls back to `Px`.

-}
cssUnit : Unit.Unit -> Builder mode -> Builder mode
cssUnit =
    PB.cssUnit


{-| Set the length [Unit](Anim-Unit#Unit) used to render the X-axis
perspective-origin value. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitX` setter for the X axis.
-}
cssUnitX : Unit.Unit -> Builder mode -> Builder mode
cssUnitX =
    PB.cssUnitX


{-| Set the length [Unit](Anim-Unit#Unit) used to render the Y-axis
perspective-origin value. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitY` setter for the Y axis.
-}
cssUnitY : Unit.Unit -> Builder mode -> Builder mode
cssUnitY =
    PB.cssUnitY



-- ============================================================
-- FROM
-- ============================================================


{-| Set the uniform starting X and Y values.
-}
from : Float -> Builder mode -> Builder mode
from xy =
    PB.fromXY xy xy


{-| Set the starting X and Y values.
-}
fromXY : Float -> Float -> Builder mode -> Builder mode
fromXY =
    PB.fromXY


{-| Set the starting X value, preserving the current Y value.
-}
fromX : Float -> Builder mode -> Builder mode
fromX =
    PB.fromX


{-| Set the starting Y value, preserving the current X value.
-}
fromY : Float -> Builder mode -> Builder mode
fromY =
    PB.fromY



-- ============================================================
-- TO
-- ============================================================


{-| Set the uniform target X and Y values.
-}
to : Float -> Builder mode -> Builder mode
to xy =
    PB.toXY xy xy


{-| Set the target X and Y values.
-}
toXY : Float -> Float -> Builder mode -> Builder mode
toXY =
    PB.toXY


{-| Set the target X value, preserving the current Y value.
-}
toX : Float -> Builder mode -> Builder mode
toX =
    PB.toX


{-| Set the target Y value, preserving the current X value.
-}
toY : Float -> Builder mode -> Builder mode
toY =
    PB.toY



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder mode -> Builder mode
delay =
    PB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder mode -> Builder mode
duration =
    PB.duration


{-| The speed represents how many units per second the perspective origin changes.

For example, an animation from `0` to `200px` with a speed of `100.0` will take 2 seconds to complete.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.speed 100
            >> ... -- continue with animation

-}
speed : Float -> Builder mode -> Builder mode
speed =
    PB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder mode -> Builder mode
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

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.spring Spring.wobbly

-}
spring : Spring -> Builder mode -> Builder mode
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
clampX : Float -> Float -> Builder mode -> Builder mode
clampX =
    PB.clampX


{-| Keep the Y axis perspective-origin within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour.

-}
clampY : Float -> Float -> Builder mode -> Builder mode
clampY =
    PB.clampY


{-| Remove the X axis range for this animation group. Does nothing if no range is set.
-}
unclampX : Builder mode -> Builder mode
unclampX =
    PB.unclampX


{-| Remove the Y axis range for this animation group. Does nothing if no range is set.
-}
unclampY : Builder mode -> Builder mode
unclampY =
    PB.unclampY



-- ============================================================
-- RESIZE
-- ============================================================


{-| Perspective-origin's contribution to a resize bounds directive for the
named anim group.

Pass this to `WAAPI.onResize` or `Sub.onResize`.

Leave an axis as `Nothing` to ignore it. `z` is ignored for this property.

-}
bounds : AnimGroupName -> Resize.Bounds -> Resize.Builder -> Resize.Builder
bounds =
    ResizeBuilder.setPerspectiveOrigin


{-| One-shot position update for an anim group's perspective-origin during resize.

Use `position` when an axis is **not** animating (`start == end`) but its
correct screen position depends on layout - for example, a perspective
camera that sits at the right edge of an area needs `x = newWidth` after
a portrait → landscape resize.

    WAAPI.onResize model.animState <|
        PerspectiveOrigin.bounds "camera"
            { x = Nothing
            , y = Just { min = 0, max = newHeight }
            , z = Nothing
            }
            >> PerspectiveOrigin.position "camera"
                { x = Just newWidth
                , y = Nothing
                }

Each axis is `Just newPos` to move that axis instantly, or `Nothing` to leave it
untouched. On a static axis the update sets `start`, `end`, and `current`
to `newPos`. On an animating axis (`start /= end`) the update is ignored,
because the next interpolation frame would overwrite a current-only
change. Use [`bounds`](#bounds) (with its proportional remap) to retarget
animating axes.

Z is ignored for this property.

-}
position : AnimGroupName -> { x : Maybe Float, y : Maybe Float } -> Resize.Builder -> Resize.Builder
position name pos =
    ResizeBuilder.setPerspectiveOriginPosition name
        { x = pos.x, y = pos.y, z = Nothing }
