module Anim.Property.Size exposing
    ( Builder, AnimGroupName
    , init, initHW, initW, initH
    , begin, end
    , fromHW, fromH, fromW, from
    , toHW, toH, toW
    , byHW, byH, byW
    , delay, duration, speed
    , easing
    , spring
    , initCssUnit, initCssUnitW, initCssUnitH
    , cssUnit, cssUnitW, cssUnitH
    , Bounds, AxisBounds, bounds
    , clampWidth, clampHeight
    , unclampWidth, unclampHeight
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

@docs begin, end


# Configure


## Start Value

When not set, the default will be used.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs fromHW, fromH, fromW, from


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.


### Absolute

@docs toHW, toH, toW


### Relative

Move by a delta on width and height instead of to a fixed size. The end value
is `current + delta` where `current` is the live animated size.

Only available on the Sub and WAAPI engines. Using these with any other engine results in a type error.

@docs byHW, byH, byW


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

Set the CSS length unit(s) used in size animations.

@docs initCssUnit, initCssUnitW, initCssUnitH

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

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    update msg model =
        case msg of
            GotContainer (Ok { element }) ->
                let
                    w =
                        element.width

                    h =
                        element.height

                    ( animState, cmd ) =
                        WAAPI.retarget model.animState <|
                            Size.begin
                                >> Size.clampWidth 0 w
                                >> Size.clampHeight 0 h
                                >> Size.end
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clampWidth, clampHeight


### Unclamp

@docs unclampWidth, unclampHeight


## Snap

Snap to a specific size, cancelling any in-flight animation on this property.

@docs set, setHW, setH, setW

-}

import Anim.Internal.Builder as InternalBuilder exposing (AnimBuilder)
import Anim.Internal.Builder.CssUnitStore as CssUnitStore
import Anim.Internal.Builder.Size as SizeBuilder exposing (SizeBuilder)
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
    SizeBuilder eng



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
init animationKey value =
    SizeBuilder.for animationKey
        >> fromHW value value
        >> SizeBuilder.toHW value value
        >> SizeBuilder.build
        >> InternalBuilder.registerSizeInitAxes [ CssUnitStore.sizeWidth, CssUnitStore.sizeHeight ]


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
initHW animationKey h w =
    SizeBuilder.for animationKey
        >> fromHW h w
        >> SizeBuilder.toHW h w
        >> SizeBuilder.build
        >> InternalBuilder.registerSizeInitAxes [ CssUnitStore.sizeWidth, CssUnitStore.sizeHeight ]


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
initW animationKey w =
    SizeBuilder.for animationKey
        >> fromW w
        >> SizeBuilder.toW w
        >> SizeBuilder.build
        >> InternalBuilder.registerSizeInitAxes [ CssUnitStore.sizeWidth ]


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
initH animationKey h =
    SizeBuilder.for animationKey
        >> fromH h
        >> SizeBuilder.toH h
        >> SizeBuilder.build
        >> InternalBuilder.registerSizeInitAxes [ CssUnitStore.sizeHeight ]



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a size animation `Builder` for the specified animation group.

Use this to start configuring a size animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.begin
            >> ... -- Configure and build the animation

-}
begin : AnimBuilder eng -> Builder eng
begin animBuilder =
    case InternalBuilder.getCurrentAnimGroupName animBuilder of
        Just animGroupName ->
            SizeBuilder.for animGroupName animBuilder

        Nothing ->
            SizeBuilder.for "" animBuilder


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.begin
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Size.end
            >> ... -- continue with animation

-}
end : Builder eng -> AnimBuilder eng
end =
    SizeBuilder.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting height and width.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.begin
            >> Size.fromHW 200 100
            >> ... -- continue with animation

-}
fromHW : Float -> Float -> Builder eng -> Builder eng
fromHW =
    SizeBuilder.fromHW


{-| Set the starting height. Width is left unchanged (or 0 if not set).
-}
fromH : Float -> Builder eng -> Builder eng
fromH =
    SizeBuilder.fromH


{-| Set the starting width. Height is left unchanged (or 0 if not set).
-}
fromW : Float -> Builder eng -> Builder eng
fromW =
    SizeBuilder.fromW


{-| Set both starting width and height to the same value.

This is equivalent to calling `fromHW value value`.

-}
from : Float -> Builder eng -> Builder eng
from value =
    SizeBuilder.fromHW value value



-- ============================================================
-- TO
-- ============================================================


{-| Set the target height and width.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.begin
            >> Size.toHW 200 100
            >> ... -- continue with animation

-}
toHW : Float -> Float -> Builder eng -> Builder eng
toHW =
    SizeBuilder.toHW


{-| Set the target height. Width is left unchanged (or 0 if not set).
-}
toH : Float -> Builder eng -> Builder eng
toH =
    SizeBuilder.toH


{-| Set the target width. Height is left unchanged (or 0 if not set).
-}
toW : Float -> Builder eng -> Builder eng
toW =
    SizeBuilder.toW



-- ============================================================
-- SNAP
-- ============================================================


{-| Snap to a uniform width and height.
-}
set : Float -> Builder eng -> Builder eng
set hw =
    SizeBuilder.setHW hw hw


{-| Snap target height and width values.
-}
setHW : Float -> Float -> Builder eng -> Builder eng
setHW =
    SizeBuilder.setHW


{-| Snap target height, preserving the current width.
-}
setH : Float -> Builder eng -> Builder eng
setH =
    SizeBuilder.setH


{-| Snap target width, preserving the current height.
-}
setW : Float -> Builder eng -> Builder eng
setW =
    SizeBuilder.setW



-- ============================================================
-- BY
-- ============================================================


{-| Move by a delta on height and width.
-}
byHW : Float -> Float -> Builder eng -> Builder eng
byHW =
    SizeBuilder.byHW


{-| Move by a delta on height. Width is unaffected.
-}
byH : Float -> Builder eng -> Builder eng
byH =
    SizeBuilder.byH


{-| Move by a delta on width. Height is unaffected.
-}
byW : Float -> Builder eng -> Builder eng
byW =
    SizeBuilder.byW



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    SizeBuilder.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    SizeBuilder.duration


{-| The speed represents how many units the element's size changes per second.

For example, a size animation from `(100, 100)` to `(200, 200)` with a speed
of `50.0` will take 2 seconds to complete.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    SizeBuilder.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Motion.Easing exposing (Easing(..))

    Size.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    SizeBuilder.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Size.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    SizeBuilder.spring



-- ============================================================
-- CSS UNITS
-- ============================================================


{-| Set the length [Unit](Anim-Unit#Unit) for all sides.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ Size.initHW "btn" 8 25
            >> Size.initCssUnit Cqmin
        ]

-}
initCssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
initCssUnit =
    InternalBuilder.setSizeInitCssUnit


{-| Set the length [Unit](Anim-Unit#Unit) for the width.
-}
initCssUnitW : Unit -> AnimBuilder eng -> AnimBuilder eng
initCssUnitW =
    InternalBuilder.setSizeInitCssUnitW


{-| Set the length [Unit](Anim-Unit#Unit) for the height.
-}
initCssUnitH : Unit -> AnimBuilder eng -> AnimBuilder eng
initCssUnitH =
    InternalBuilder.setSizeInitCssUnitH


{-| Set the length [Unit](Anim-Unit#Unit) for all sides.

    import Anim.Unit exposing (Unit(..))

    Size.begin
        >> Size.cssUnit Cqmin
        >> ... -- continue with animation

-}
cssUnit : Unit -> Builder eng -> Builder eng
cssUnit =
    SizeBuilder.setCssUnit


{-| Set the length [Unit](Anim-Unit#Unit) for the width.
-}
cssUnitW : Unit -> Builder eng -> Builder eng
cssUnitW =
    SizeBuilder.setCssUnitW


{-| Set the length [Unit](Anim-Unit#Unit) for the height.
-}
cssUnitH : Unit -> Builder eng -> Builder eng
cssUnitH =
    SizeBuilder.setCssUnitH



-- ============================================================
-- BOUNDS
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

You can set the bounds for multiple anim groups in one call:

    Sub.onResize model.animState <|
        Size.bounds "box" boxBounds
            >> Size.bounds "card" cardBounds

The engine proportionally remaps the in-flight animation onto the new
range and pins its endpoints to it.

Only callable from inside an engine's `onResize` builder - calling it from
anywhere else results in a type error.

-}
bounds : AnimGroupName -> AxisBounds -> AnimBuilder { eng | withBounds : () } -> AnimBuilder { eng | withBounds : () }
bounds name ranges =
    SizeBuilder.for name
        >> SizeBuilder.bounds (toBuilderRanges ranges)
        >> SizeBuilder.build


toBuilderRanges : AxisBounds -> InternalBuilder.AxisBounds
toBuilderRanges ranges =
    { x = ranges.width
    , y = ranges.height
    , z = Nothing
    }



-- ============================================================
-- CLAMP / UNCLAMP
-- ============================================================


{-| Keep width within `min` and `max` values. If `min > max` the values are flipped.
-}
clampWidth : Float -> Float -> Builder eng -> Builder eng
clampWidth =
    SizeBuilder.clampWidth


{-| Keep height within `min` and `max` values. If `min > max` the values are flipped.
-}
clampHeight : Float -> Float -> Builder eng -> Builder eng
clampHeight =
    SizeBuilder.clampHeight


{-| Remove the width range for this animation group. Does nothing if no range is set.
-}
unclampWidth : Builder eng -> Builder eng
unclampWidth =
    SizeBuilder.unclampWidth


{-| Remove the height range for this animation group. Does nothing if no range is set.
-}
unclampHeight : Builder eng -> Builder eng
unclampHeight =
    SizeBuilder.unclampHeight
