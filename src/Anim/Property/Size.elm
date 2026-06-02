module Anim.Property.Size exposing
    ( Builder, AnimGroupName
    , init, initHW, initW, initH
    , initUnit, initUnitW, initUnitH
    , for, build
    , fromHW, fromH, fromW, from
    , toHW, toH, toW
    , set, setHW, setH, setW
    , delay, duration, speed
    , easing
    , spring
    , cssUnit, cssUnitWidth, cssUnitHeight
    , Bounds, AxisBounds, bounds
    , clampWidth, clampHeight, unclampWidth, unclampHeight
    )

{-| Animate the width and height of elements.

**Default**: 0 for width and height

When no start value is configured, the default will be used.

If height or width is not defined in the animation configuration, it will remain unchanged,
or 0 if not set.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init, initHW, initW, initH


## Initial Unit

Set the length [Unit](Anim-Unit#Unit) used by subsequent `init*` calls.
Order matters - `initUnit*` only affects `init*` calls that follow it in
the pipeline. Defaults to `Px`.

    import Anim.Unit exposing (Unit(..))

    init _ =
        ( { animState =
                Engine.init
                    [ Size.initUnitW Cqw
                        >> Size.initUnitH Cqh
                        >> Size.initHW "btn" 8 25
                    ]
          }
        , Cmd.none
        )

@docs initUnit, initUnitW, initUnitH


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#start-values)
for details.

@docs fromHW, fromH, fromW, from


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#end-values)
for details.

@docs toHW, toH, toW


## Snap

@docs set, setHW, setH, setW


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


## Unit

@docs cssUnit, cssUnitWidth, cssUnitHeight


## Resize

Proportionally remap an in-flight size animation onto new width / height
ranges from inside an engine's `onResize` callback.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs Bounds, AxisBounds, bounds


## Clamping

Keep width and height within a range you choose.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampWidth, clampHeight, unclampWidth, unclampHeight

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
import Anim.Internal.Builder.Size as SB
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for size animations.
-}
type alias Builder eng =
    SB.SizeBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial size.

Use this to initialize the size in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Size.init "animGroupName" 100 ] }
        , Cmd.none
        )

This is equivalent to calling `initHW 100 100`.

-}
init : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
init animationKey value animBuilder =
    animBuilder
        |> SB.for animationKey
        |> SB.applyInitCssUnit
        |> fromHW value value
        |> SB.toHW value value
        |> SB.build


{-| Set the initial width and height.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Size.initHW "animGroupName" 200 100 ] }
        , Cmd.none
        )

-}
initHW : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initHW animationKey h w animBuilder =
    animBuilder
        |> SB.for animationKey
        |> SB.applyInitCssUnit
        |> fromHW h w
        |> SB.toHW h w
        |> SB.build


{-| Set the initial width.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Size.initW "animGroupName" 200 ] }
        , Cmd.none
        )

-}
initW : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initW animationKey w animBuilder =
    animBuilder
        |> SB.for animationKey
        |> SB.applyInitCssUnit
        |> fromW w
        |> SB.toW w
        |> SB.build


{-| Set the initial height.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Size.initH "animGroupName" 150 ] }
        , Cmd.none
        )

-}
initH : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initH animationKey h animBuilder =
    animBuilder
        |> SB.for animationKey
        |> SB.applyInitCssUnit
        |> fromH h
        |> SB.toH h
        |> SB.build



-- Initial Unit


{-| Set the length [Unit](Anim-Unit#Unit) used by every subsequent `init*` call
for `Size` values. Defaults to `Px`.

Order matters - only `init*` calls downstream of this setter in the pipeline
are affected; calls upstream keep their previously selected unit (or `Px`).
Later per-axis setters ([`initUnitW`](#initUnitW),
[`initUnitH`](#initUnitH)) override this setting on the relevant axis.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ Size.initUnit Cqmin
            >> Size.initHW "btn" 8 25
        ]

-}
initUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnit =
    IB.setSizeInitCssUnit


{-| Set the width-axis unit used by every subsequent `init*` call for `Size`
values. Overrides any unit set by [`initUnit`](#initUnit) on the width axis.
-}
initUnitW : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitW =
    IB.setSizeInitCssUnitWidth


{-| Set the height-axis unit used by every subsequent `init*` call for `Size`
values. Overrides any unit set by [`initUnit`](#initUnit) on the height axis.
-}
initUnitH : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitH =
    IB.setSizeInitCssUnitHeight



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a size animation `Builder` for the specified animation group.

Use this to start configuring a size animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    SB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Size.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    SB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting height and width.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.fromHW 200 100
            >> ... -- continue with animation

-}
fromHW : Float -> Float -> Builder eng -> Builder eng
fromHW =
    SB.fromHW


{-| Set the starting height, keeping the current width.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.fromH 150
            >> ... -- continue with animation

The width remains unchanged, or 0 if not set.

-}
fromH : Float -> Builder eng -> Builder eng
fromH =
    SB.fromH


{-| Set the starting width, keeping the current height.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.fromW 250
            >> ... -- continue with animation

The height remains unchanged, or 0 if not set.

-}
fromW : Float -> Builder eng -> Builder eng
fromW =
    SB.fromW


{-| Set the starting width and height to the same value.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.from 100
            >> ... -- continue with animation

This is equivalent to calling `fromHW 100 100`.

-}
from : Float -> Builder eng -> Builder eng
from value =
    SB.fromHW value value



-- ============================================================
-- TO
-- ============================================================


{-| Set the target height and width for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> ... -- continue with animation

-}
toHW : Float -> Float -> Builder eng -> Builder eng
toHW =
    SB.toHW


{-| Set the target height for the current animation group, keeping the current target width.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toH 150
            >> ... -- continue with animation

The width remains unchanged, or 0 if not set.

-}
toH : Float -> Builder eng -> Builder eng
toH =
    SB.toH


{-| Set the target width for the current animation group, keeping the current target height.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toW 250
            >> ... -- continue with animation

The height remains unchanged, or 0 if not set.

-}
toW : Float -> Builder eng -> Builder eng
toW =
    SB.toW



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap the uniform target height and width values silently,
cancelling any in-flight animation on this property.
-}
set : Float -> Builder eng -> Builder eng
set hw =
    SB.setHW hw hw


{-| Snap the target height and width values.
-}
setHW : Float -> Float -> Builder eng -> Builder eng
setHW =
    SB.setHW


{-| Snap the target height, preserving the current width.
-}
setH : Float -> Builder eng -> Builder eng
setH =
    SB.setH


{-| Snap the target width, preserving the current height.
-}
setW : Float -> Builder eng -> Builder eng
setW =
    SB.setW



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    SB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    SB.duration


{-| The speed represents how many pixels the element's size changes per second.

For example, lets take a size animation from `(100, 100)` to `(200, 200)` assuming `Px` for the CSS Unit.
A speed of `50.0` means the size will change by 50 pixels per second, so our animation will take 2 seconds to complete.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 200
            >> Size.speed 50
            >> ... -- continue with animation

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    SB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.easing EaseInOut
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
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    SB.spring



-- ============================================================
-- UNIT
-- ============================================================


{-| Set the length [Unit](Anim-Unit#Unit) used to render width and height for
this property.

Defaults to `Px`. Setting a relative unit (`Percent`, `Vw`, `Vh`, `Rem`, `Em`)
makes the browser re-evaluate the rendered size against current layout, so the
animation follows resize automatically.

    import Anim.Unit as Unit

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 50 80
            >> Size.cssUnit Unit.Percent
            >> Size.build

This setting takes precedence over any [length](Anim-Engine-WAAPI#cssUnit) set
on the engine.

`Sub` renders non-`Px` units normally. During `onResize` bounds remapping,
only `Px` size axes are remapped; non-`Px` axes are left unchanged.

-}
cssUnit : Unit -> Builder eng -> Builder eng
cssUnit =
    SB.cssUnit


{-| Set the length [Unit](Anim-Unit#Unit) used to render the `width` value for
this property. Overrides any unit set by [`cssUnit`](#cssUnit) or by the
engine's `cssUnit`/`cssUnitWidth` setter for the width axis.
-}
cssUnitWidth : Unit -> Builder eng -> Builder eng
cssUnitWidth =
    SB.cssUnitWidth


{-| Set the length [Unit](Anim-Unit#Unit) used to render the `height` value
for this property. Overrides any unit set by [`cssUnit`](#cssUnit) or by the
engine's `cssUnit`/`cssUnitHeight` setter for the height axis.
-}
cssUnitHeight : Unit -> Builder eng -> Builder eng
cssUnitHeight =
    SB.cssUnitHeight



-- ============================================================
-- RESIZE
-- ============================================================


{-| A numeric range with `min` and `max` boundaries.
-}
type alias Bounds =
    { min : Float, max : Float }


{-| Per-axis resize ranges. `Nothing` leaves an axis untouched.

    { width = Just { min = 0, max = 400 }
    , height = Nothing
    }

-}
type alias AxisBounds =
    { width : Maybe Bounds
    , height : Maybe Bounds
    }


{-| Apply new size bounds for an anim group during resize.

Pass this inside an engine's `onResize` builder:

    Sub.onResize model.animState <|
        Size.bounds "box"
            { width = Just { min = 0, max = newWidth }
            , height = Just { min = 0, max = newHeight }
            }

You can resize multiple anim groups in one call:

    Sub.onResize model.animState <|
        Size.bounds "box" boxBounds
            >> Size.bounds "card" cardBounds

Leave an axis as `Nothing` to ignore it. The engine proportionally remaps
the in-flight animation onto the new range and pins its endpoints to it.

Only callable from inside an engine's `onResize` callback - the `withBounds`
capability on the builder type is what gates it.

-}
bounds : AnimGroupName -> AxisBounds -> AnimBuilder { eng | withBounds : () } -> AnimBuilder { eng | withBounds : () }
bounds name ranges =
    SB.for name >> SB.bounds (toBuilderRanges ranges) >> SB.build


toBuilderRanges : AxisBounds -> IB.AxisBounds
toBuilderRanges ranges =
    { x = ranges.width
    , y = ranges.height
    , z = Nothing
    }



-- ============================================================
-- CLAMPING
-- ============================================================


{-| Keep width within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclampWidth](#unclampWidth). If `min > max`, the values are swapped.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clampWidth : Float -> Float -> Builder eng -> Builder eng
clampWidth =
    SB.clampWidth


{-| Keep height within `[min, max]` for this animation group.

See [clampWidth](#clampWidth) for behaviour.

-}
clampHeight : Float -> Float -> Builder eng -> Builder eng
clampHeight =
    SB.clampHeight


{-| Remove the width range for this animation group. Does nothing if no range is set.
-}
unclampWidth : Builder eng -> Builder eng
unclampWidth =
    SB.unclampWidth


{-| Remove the height range for this animation group. Does nothing if no range is set.
-}
unclampHeight : Builder eng -> Builder eng
unclampHeight =
    SB.unclampHeight
