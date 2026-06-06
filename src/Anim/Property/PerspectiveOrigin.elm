module Anim.Property.PerspectiveOrigin exposing
    ( Builder, AnimGroupName
    , initXY, initX, initY
    , for, build
    , from, fromXY, fromX, fromY
    , to, toXY, toX, toY
    , by, byXY, byX, byY
    , delay, duration, speed
    , easing
    , spring
    , cssUnit, cssUnitX, cssUnitY
    , Bounds, AxisBounds, bounds
    , clampX, clampY
    , unclampX, unclampY
    , set, setXY, setX, setY
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
[`cssUnit`](#cssUnit) (or [`cssUnitX`](#cssUnitX) /
[`cssUnitY`](#cssUnitY)) to switch the unit used by `init*` calls earlier in
the pipeline.

@docs initXY, initX, initY


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs from, fromXY, fromX, fromY


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


### Absolute

@docs to, toXY, toX, toY


### Relative

Move by a delta instead of to a fixed perspective origin. The end value is
`current + delta` for each axis, where `current` is the configured start value
or the default when no start value has been set on that axis.

@docs by, byXY, byX, byY


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


## CSS Units

Set the length [Unit](Anim-Unit#Unit) used by `init*` calls earlier in the
pipeline. Order matters - `cssUnit*` only affects `init*` calls that appear
before it in the pipeline. Defaults to `Percent`.

    import Anim.Unit exposing (Unit(..))

    init _ =
        ( { animState =
                Engine.init
                    [ PerspectiveOrigin.initXY "vp" 200 150
                        >> PerspectiveOrigin.cssUnit Px
                    ]
          }
        , Cmd.none
        )

@docs cssUnit, cssUnitX, cssUnitY


## Responsive Animations

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.


### Bounds

Set how perspective-origin responds to viewport/container resize and provide
new bounds during `onResize`.

@docs Bounds, AxisBounds, bounds


## Clamping

Keep perspective-origin values on each axis within a range you choose.

Values outside the range are clamped to the nearest boundary.

Similar to `bounds`, but without proportional remapping.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    motion : PerspectiveOrigin.Builder { eng | withTiming : () } -> PerspectiveOrigin.Builder { eng | withTiming : () }
    motion =
        PerspectiveOrigin.duration 600
            >> PerspectiveOrigin.easing Easing.easeOutCubic

    update msg model =
        case msg of
            GotCard (Ok { element }) ->
                let
                    w =
                        element.width

                    h =
                        element.height

                    ( animState, cmd ) =
                        WAAPI.retarget model.animState <|
                            PerspectiveOrigin.for animGroupName
                                >> PerspectiveOrigin.clampX 0 w
                                >> PerspectiveOrigin.clampY 0 h
                                >> PerspectiveOrigin.build
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clampX, clampY


### Unclamp

@docs unclampX, unclampY


## Snap

Snap to a specific perspective origin, cancelling any in-flight animation on this property.

@docs set, setXY, setX, setY

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
import Anim.Internal.Builder.CssUnitStore as CssUnitStore
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
[Unit](Anim-Unit#Unit) was most recently selected by [`cssUnit`](#cssUnit) /
[`cssUnitX`](#cssUnitX) / [`cssUnitY`](#cssUnitY) upstream in the pipeline
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
        |> fromXY x y
        |> toXY x y
        |> build
        |> IB.registerPerspectiveOriginInitAxes [ CssUnitStore.perspectiveOriginX, CssUnitStore.perspectiveOriginY ]


{-| Set the initial X-axis perspective origin. Uses whichever
[Unit](Anim-Unit#Unit) was most recently selected by [`cssUnit`](#cssUnit) /
[`cssUnitX`](#cssUnitX) upstream in the pipeline (defaults to `Percent`).
-}
initX : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initX animationKey x animBuilder =
    animBuilder
        |> for animationKey
        |> fromX x
        |> toX x
        |> build
        |> IB.registerPerspectiveOriginInitAxes [ CssUnitStore.perspectiveOriginX ]


{-| Set the initial Y-axis perspective origin. Uses whichever
[Unit](Anim-Unit#Unit) was most recently selected by [`cssUnit`](#cssUnit) /
[`cssUnitY`](#cssUnitY) upstream in the pipeline (defaults to `Percent`).
-}
initY : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initY animationKey y animBuilder =
    animBuilder
        |> for animationKey
        |> fromY y
        |> toY y
        |> build
        |> IB.registerPerspectiveOriginInitAxes [ CssUnitStore.perspectiveOriginY ]


{-| Set the length [Unit](Anim-Unit#Unit) used by `init*` calls earlier in the
pipeline for `PerspectiveOrigin` values. Defaults to `Percent`.

Order matters - only `init*` calls upstream of this setter in the pipeline are
affected; calls later in the pipeline keep their previously selected unit (or
`Percent`). Later per-axis setters ([`cssUnitX`](#cssUnitX),
[`cssUnitY`](#cssUnitY)) override this setting on the relevant axis.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ PerspectiveOrigin.initXY "vp" 200 150
            >> PerspectiveOrigin.cssUnit Px
        ]

-}
cssUnit : Unit.Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnit =
    IB.setPerspectiveOriginInitCssUnit


{-| Set the X-axis unit used by `init*` calls earlier in the pipeline for
`PerspectiveOrigin` values. Overrides any unit set by [`cssUnit`](#cssUnit)
on the X axis.
-}
cssUnitX : Unit.Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitX =
    IB.setPerspectiveOriginInitCssUnitX


{-| Set the Y-axis unit used by `init*` calls earlier in the pipeline for
`PerspectiveOrigin` values. Overrides any unit set by [`cssUnit`](#cssUnit)
on the Y axis.
-}
cssUnitY : Unit.Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitY =
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


{-| Snap to a uniform X and Y value silently, cancelling any
in-flight animation on this property.
-}
set : Float -> Builder eng -> Builder eng
set xy =
    PB.setXY xy xy


{-| Snap target X and Y values.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    PB.setXY


{-| Snap target X value, preserving the current Y value.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    PB.setX


{-| Snap target Y value, preserving the current X value.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    PB.setY



-- ============================================================
-- BY
-- ============================================================


{-| Move by a delta on both axes.
-}
by : Float -> Builder eng -> Builder eng
by =
    PB.by


{-| Move by a delta on the X and Y axes.
-}
byXY : Float -> Float -> Builder eng -> Builder eng
byXY =
    PB.byXY


{-| Move by a delta on the X axis. Y is unaffected.
-}
byX : Float -> Builder eng -> Builder eng
byX =
    PB.byX


{-| Move by a delta on the Y axis. X is unaffected.
-}
byY : Float -> Builder eng -> Builder eng
byY =
    PB.byY



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    PB.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    PB.duration


{-| The speed represents how many units per second the perspective origin changes.

For example, an animation from `0` to `200px` with a speed of `100.0`
will take 2 seconds to complete.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    PB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    PerspectiveOrigin.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    PB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    PerspectiveOrigin.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    PB.spring



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



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis perspective-origin within `[min, max]` for this animation group.

The range stays in effect for future animations
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
