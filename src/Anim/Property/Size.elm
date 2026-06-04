module Anim.Property.Size exposing
    ( Builder, AnimGroupName
    , init, initHW, initW, initH
    , for, build
    , fromHW, fromH, fromW, from
    , toHW, toH, toW
    , byHW, byH, byW
    , delay, duration, speed
    , easing
    , spring
    , cssUnit, cssUnitW, cssUnitH
    , Bounds, AxisBounds, bounds
    , clampWidth, clampHeight, unclampWidth, unclampHeight
    , set, setHW, setH, setW
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


# Build

@docs for, build


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs fromHW, fromH, fromW, from


## End Value (Absolute)

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.

@docs toHW, toH, toW


## End Value (Relative)

Move by a delta on width and height instead of to a fixed size. The end value
is `current + delta` for each axis, where `current` is the configured start
size or the default when no start value has been set on that axis.

@docs byHW, byH, byW

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


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

Set the CSS length unit(s) used by `init*` calls earlier in the
pipeline. Order matters - `cssUnit*` only affects `init*` calls that
appear before it in the pipeline. Defaults to `Px`.

    import Anim.Unit exposing (Unit(..))

    init _ =
        ( { animState =
                Engine.init
                    [ Size.initHW "btn" 8 25
                        >> Size.cssUnitW Cqw
                        >> Size.cssUnitH Cqh
                    ]
          }
        , Cmd.none
        )

@docs cssUnit, cssUnitW, cssUnitH


## Responsive Animations

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.


### Bounds

Proportionally remap an in-flight size animation onto new width / height
ranges from inside an engine's `onResize` callback.

@docs Bounds, AxisBounds, bounds


## Clamping

Keep width and height within a range you choose.

Values outside the range are clamped to the nearest boundary.

Similar to `bounds`, but without proportional remapping.

@docs clampWidth, clampHeight, unclampWidth, unclampHeight


## Snap

Snap to a specific size, cancelling any in-flight animation on this property.

@docs set, setHW, setH, setW

-}

import Anim.Internal.Builder as IB exposing (AnimBuilder)
import Anim.Internal.Builder.CssUnitStore as CssUnitStore
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
        |> fromHW value value
        |> SB.toHW value value
        |> SB.build
        |> IB.registerSizeInitAxes [ CssUnitStore.sizeWidth, CssUnitStore.sizeHeight ]


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
        |> fromHW h w
        |> SB.toHW h w
        |> SB.build
        |> IB.registerSizeInitAxes [ CssUnitStore.sizeWidth, CssUnitStore.sizeHeight ]


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
        |> fromW w
        |> SB.toW w
        |> SB.build
        |> IB.registerSizeInitAxes [ CssUnitStore.sizeWidth ]


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
        |> fromH h
        |> SB.toH h
        |> SB.build
        |> IB.registerSizeInitAxes [ CssUnitStore.sizeHeight ]



-- Initial Unit


{-| Set the length [Unit](Anim-Unit#Unit) used by `init*` calls earlier in the
pipeline for `Size` values. Defaults to `Px`.

Order matters - only `init*` calls upstream of this setter in the pipeline are
affected; calls later in the pipeline keep their previously selected unit (or
`Px`). Later per-axis setters ([`cssUnitW`](#cssUnitW),
[`cssUnitH`](#cssUnitH)) override this setting on the relevant axis.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ Size.initHW "btn" 8 25
            >> Size.cssUnit Cqmin
        ]

-}
cssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnit =
    IB.setSizeInitCssUnit


{-| Set the width-axis unit used by `init*` calls earlier in the pipeline for
`Size` values. Overrides any unit set by [`cssUnit`](#cssUnit) on the width
axis.
-}
cssUnitW : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitW =
    IB.setSizeInitCssUnitWidth


{-| Set the height-axis unit used by `init*` calls earlier in the pipeline for
`Size` values. Overrides any unit set by [`cssUnit`](#cssUnit) on the height
axis.
-}
cssUnitH : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitH =
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


{-| Set the starting height. Width is left unchanged (or 0 if not set).
-}
fromH : Float -> Builder eng -> Builder eng
fromH =
    SB.fromH


{-| Set the starting width. Height is left unchanged (or 0 if not set).
-}
fromW : Float -> Builder eng -> Builder eng
fromW =
    SB.fromW


{-| Set both starting width and height to the same value.

This is equivalent to calling `fromHW value value`.

-}
from : Float -> Builder eng -> Builder eng
from value =
    SB.fromHW value value



-- ============================================================
-- TO
-- ============================================================


{-| Set the target height and width.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> ... -- continue with animation

-}
toHW : Float -> Float -> Builder eng -> Builder eng
toHW =
    SB.toHW


{-| Set the target height. Width is left unchanged (or 0 if not set).
-}
toH : Float -> Builder eng -> Builder eng
toH =
    SB.toH


{-| Set the target width. Height is left unchanged (or 0 if not set).
-}
toW : Float -> Builder eng -> Builder eng
toW =
    SB.toW



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap to a uniform width and height silently, cancelling any
in-flight animation on this property.
-}
set : Float -> Builder eng -> Builder eng
set hw =
    SB.setHW hw hw


{-| Snap target height and width values.
-}
setHW : Float -> Float -> Builder eng -> Builder eng
setHW =
    SB.setHW


{-| Snap target height, preserving the current width.
-}
setH : Float -> Builder eng -> Builder eng
setH =
    SB.setH


{-| Snap target width, preserving the current height.
-}
setW : Float -> Builder eng -> Builder eng
setW =
    SB.setW



-- ============================================================
-- BY
-- ============================================================


{-| Move by a delta on height and width.
-}
byHW : Float -> Float -> Builder eng -> Builder eng
byHW =
    SB.byHW


{-| Move by a delta on height. Width is unaffected.
-}
byH : Float -> Builder eng -> Builder eng
byH =
    SB.byH


{-| Move by a delta on width. Height is unaffected.
-}
byW : Float -> Builder eng -> Builder eng
byW =
    SB.byW



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


{-| The speed represents how many units the element's size changes per second.

For example, a size animation from `(100, 100)` to `(200, 200)` with a speed
of `50.0` will take 2 seconds to complete.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    SB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    Size.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    SB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Size.spring Spring.wobbly

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
-- BOUNDS
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
