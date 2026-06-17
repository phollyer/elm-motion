module Anim.Property.Translate exposing
    ( Builder, AnimGroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , begin, end
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    , spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ
    , Bounds, AxisBounds, bounds
    , clampX, clampY, clampZ
    , unclampX, unclampY, unclampZ
    , setXYZ, setXY, setXZ, setX, setYZ, setY, setZ
    )

{-| Move elements along the X, Y, and Z axes.

**Default**: 0 for all axes

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

Move by a delta instead of to a fixed position. The end value is
`current + delta`, where `current` is the live animated position.

Only available on the Sub and WAAPI engines. Using these with
any other engine results in a type error.

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


## CSS Units

Set the CSS length unit(s) used in translate animations.

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ


## Responsive Animations

When using responsive units like `%` or `Cqw`, the animation automatically responds
to changes in screen or container size without extra configuration. However, when
using fixed units like `Px`, the animation needs to be made aware of size changes
in order to respond to them. This is done with the functions below.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.


### Bounds

Keep translate values within a range you choose. Values outside the range are clamped
to the nearest boundary. An animation that is within the bounds, either mid-flight or
paused, will me remapped proportionally inside the bounds.

@docs Bounds, AxisBounds, bounds


## Clamping

Keep translate values on each axis within a range you choose.

Values outside the range are clamped to the nearest boundary.

Similar to `bounds`, but without proportional remapping.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    update msg model =
        case msg of
            GotCanvas (Ok { element }) ->
                let
                    w =
                        element.width

                    h =
                        element.height

                    ( animState, cmd ) =
                        WAAPI.retarget model.animState <|
                            Translate.begin
                                >> Translate.clampX 0 (w - boxWidth)
                                >> Translate.clampY 0 (h - boxWidth)
                                >> Translate.end
                in
                ( { model | animState = animState }
                , cmd
                )


### Clamp

@docs clampX, clampY, clampZ


### Unclamp

@docs unclampX, unclampY, unclampZ


## Snap

Snap to a specific position, cancelling any in-flight animation on this property.

@docs setXYZ, setXY, setXZ, setX, setYZ, setY, setZ

-}

import Anim.Internal.Builder as SB exposing (AnimBuilder)
import Anim.Internal.Builder.CssUnitStore as CssUnitStore
import Anim.Internal.Builder.Translate as TB
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


{-| Builder type for translate animations.
-}
type alias Builder eng =
    TB.TranslateBuilder eng



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial X, Y, and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initXYZ "animGroupName" 100 20 50 ] }
        , Cmd.none
        )

-}
initXYZ : AnimGroupName -> Float -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXYZ animationKey x y z =
    TB.for animationKey
        >> fromXYZ x y z
        >> TB.toXYZ x y z
        >> TB.build
        >> SB.registerTranslateInitAxes [ CssUnitStore.translateX, CssUnitStore.translateY, CssUnitStore.translateZ ]


{-| Set the initial X and Y position.
-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXY animationKey x y animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromXY x y
        |> TB.toXY x y
        |> TB.build
        |> SB.registerTranslateInitAxes [ CssUnitStore.translateX, CssUnitStore.translateY ]


{-| Set the initial X and Z position.
-}
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXZ animationKey x z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromXZ x z
        |> TB.toXZ x z
        |> TB.build
        |> SB.registerTranslateInitAxes [ CssUnitStore.translateX, CssUnitStore.translateZ ]


{-| Set the initial X position.
-}
initX : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initX animationKey x animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromX x
        |> TB.toX x
        |> TB.build
        |> SB.registerTranslateInitAxes [ CssUnitStore.translateX ]


{-| Set the initial Y and Z position.
-}
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initYZ animationKey y z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromYZ y z
        |> TB.toYZ y z
        |> TB.build
        |> SB.registerTranslateInitAxes [ CssUnitStore.translateY, CssUnitStore.translateZ ]


{-| Set the initial Y position.
-}
initY : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initY animationKey y animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromY y
        |> TB.toY y
        |> TB.build
        |> SB.registerTranslateInitAxes [ CssUnitStore.translateY ]


{-| Set the initial Z position.
-}
initZ : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initZ animationKey z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromZ z
        |> TB.toZ z
        |> TB.build
        |> SB.registerTranslateInitAxes [ CssUnitStore.translateZ ]



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a translate animation `Builder` for the specified animation group.

Use this to start configuring a translate animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.begin
            >> ... -- Configure and build the animation

-}
begin : AnimBuilder eng -> Builder eng
begin animBuilder =
    case SB.getCurrentAnimGroupName animBuilder of
        Just animGroupName ->
            TB.for animGroupName animBuilder

        Nothing ->
            TB.for "" animBuilder


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.begin
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Translate.end
            >> ... -- continue with animation

-}
end : Builder eng -> AnimBuilder eng
end =
    TB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X, Y, and Z position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.begin
            >> Translate.fromXYZ 100 20 50
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
fromXYZ =
    TB.fromXYZ


{-| Set the starting X and Y position. Z is left unchanged (or 0 if not set).
-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    TB.fromXY


{-| Set the starting X and Z position. Y is left unchanged (or 0 if not set).
-}
fromXZ : Float -> Float -> Builder eng -> Builder eng
fromXZ =
    TB.fromXZ


{-| Set the starting X position. Y and Z are left unchanged (or 0 if not set).
-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    TB.fromX


{-| Set the starting Y and Z position. X is left unchanged (or 0 if not set).
-}
fromYZ : Float -> Float -> Builder eng -> Builder eng
fromYZ =
    TB.fromYZ


{-| Set the starting Y position. X and Z are left unchanged (or 0 if not set).
-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    TB.fromY


{-| Set the starting Z position. X and Y are left unchanged (or 0 if not set).
-}
fromZ : Float -> Builder eng -> Builder eng
fromZ =
    TB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X, Y, and Z position for the current animation group.
-}
toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
toXYZ =
    TB.toXYZ


{-| Set the target X and Y position. Z is left unchanged (or 0 if not set).
-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    TB.toXY


{-| Set the target X and Z position. Y is left unchanged (or 0 if not set).
-}
toXZ : Float -> Float -> Builder eng -> Builder eng
toXZ =
    TB.toXZ


{-| Set the target X position. Y and Z are left unchanged (or 0 if not set).
-}
toX : Float -> Builder eng -> Builder eng
toX =
    TB.toX


{-| Set the target Y and Z position. X is left unchanged (or 0 if not set).
-}
toYZ : Float -> Float -> Builder eng -> Builder eng
toYZ =
    TB.toYZ


{-| Set the target Y position. X and Z are left unchanged (or 0 if not set).
-}
toY : Float -> Builder eng -> Builder eng
toY =
    TB.toY


{-| Set the target Z position. X and Y are left unchanged (or 0 if not set).
-}
toZ : Float -> Builder eng -> Builder eng
toZ =
    TB.toZ



-- ============================================================
-- SNAP
-- ============================================================


{-| Snap target X, Y and Z values silently
-}
setXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
setXYZ =
    TB.setXYZ


{-| Snap target X and Y values, preserving the current Z value.
-}
setXY : Float -> Float -> Builder eng -> Builder eng
setXY =
    TB.setXY


{-| Snap target X and Z values, preserving the current Y value.
-}
setXZ : Float -> Float -> Builder eng -> Builder eng
setXZ =
    TB.setXZ


{-| Snap target X value, preserving the current Y and Z values.
-}
setX : Float -> Builder eng -> Builder eng
setX =
    TB.setX


{-| Snap target Y and Z values, preserving the current X value.
-}
setYZ : Float -> Float -> Builder eng -> Builder eng
setYZ =
    TB.setYZ


{-| Snap target Y value, preserving the current X and Z values.
-}
setY : Float -> Builder eng -> Builder eng
setY =
    TB.setY


{-| Snap target Z value, preserving the current X and Y values.
-}
setZ : Float -> Builder eng -> Builder eng
setZ =
    TB.setZ



-- ============================================================
-- BY
-- ============================================================


{-| Move by specific amounts on the X, Y, and Z axes.

    myAnimation : AnimBuilder { eng | withLiveDelta : () } -> AnimBuilder { eng | withLiveDelta : () }
    myAnimation =
        Translate.begin
            >> Translate.byXYZ 50 -25 10
            >> ... -- continue with animation

-}
byXYZ : Float -> Float -> Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byXYZ =
    TB.byXYZ


{-| Move by specific amounts on the X and Y axes. Z is unaffected.
-}
byXY : Float -> Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byXY =
    TB.byXY


{-| Move by specific amounts on the X and Z axes. Y is unaffected.
-}
byXZ : Float -> Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byXZ =
    TB.byXZ


{-| Move by a specific amount on the X axis. Y and Z are unaffected.
-}
byX : Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byX =
    TB.byX


{-| Move by specific amounts on the Y and Z axes. X is unaffected.
-}
byYZ : Float -> Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byYZ =
    TB.byYZ


{-| Move by a specific amount on the Y axis. X and Z are unaffected.
-}
byY : Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byY =
    TB.byY


{-| Move by a specific amount on the Z axis. X and Y are unaffected.
-}
byZ : Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
byZ =
    TB.byZ



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    TB.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    TB.duration


{-| The speed represents how many `Unit`s the element moves per second.

So if the CSS Unit is `Px` and the speed is `100`, the element will move 100 pixels per second,
likewise, if the CSS Unit is `Cqw` and the speed is `100`, the element will move 100% of it's
container's width per second.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    TB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Motion.Easing exposing (Easing(..))

    Translate.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    TB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Translate.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    TB.spring



-- ============================================================
-- CSS UNITS
-- ============================================================


{-| Set the length [Unit](Anim-Unit#Unit) for all axes.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ Translate.initX "box" 50
            >> Translate.cssUnit Cqw
        ]

-}
cssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnit =
    SB.setTranslateInitCssUnit


{-| Set the length [Unit](Anim-Unit#Unit) for the X axis.
-}
cssUnitX : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitX =
    SB.setTranslateInitCssUnitX


{-| Set the length [Unit](Anim-Unit#Unit) for the Y axis.
-}
cssUnitY : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitY =
    SB.setTranslateInitCssUnitY


{-| Set the length [Unit](Anim-Unit#Unit) for the Z axis.
-}
cssUnitZ : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitZ =
    SB.setTranslateInitCssUnitZ



-- ============================================================
-- RESIZE
-- ============================================================


{-| A numeric range with `min` and `max` boundaries.
-}
type alias Bounds =
    { min : Float, max : Float }


{-| Per-axis resize ranges. `Nothing` leaves an axis untouched.

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


{-| Apply new translate bounds for an anim group during resize.

Pass this inside an engine's `onResize` builder:

    Sub.onResize model.animState <|
        Translate.bounds "box"
            { x = Just { min = 0, max = newWidth - boxSize }
            , y = Nothing
            , z = Nothing
            }

You can set the bounds for multiple anim groups in one call:

    Sub.onResize model.animState <|
        Translate.bounds "box" boxBounds
            >> Translate.bounds "card" cardBounds

The engine proportionally remaps the in-flight animation onto the new
range and pins its endpoints to it.

Only callable from inside an engine's `onResize` builder - calling it from
anywhere else results in a type error.

-}
bounds : AnimGroupName -> AxisBounds -> AnimBuilder { eng | withBounds : () } -> AnimBuilder { eng | withBounds : () }
bounds name ranges =
    TB.for name >> TB.bounds ranges >> TB.build



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis translate within `min` and `max` values. If `min > max` the values are flipped.
-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    TB.clampX


{-| Keep the Y axis translate within `min` and `max` values. If `min > max` the values are flipped.
-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    TB.clampY


{-| Keep the Z axis translate within `min` and `max` values. If `min > max` the values are flipped.
-}
clampZ : Float -> Float -> Builder eng -> Builder eng
clampZ =
    TB.clampZ


{-| Remove the X axis range for this animation group. Does nothing if no range is set.
-}
unclampX : Builder eng -> Builder eng
unclampX =
    TB.unclampX


{-| Remove the Y axis range for this animation group. Does nothing if no range is set.
-}
unclampY : Builder eng -> Builder eng
unclampY =
    TB.unclampY


{-| Remove the Z axis range for this animation group. Does nothing if no range is set.
-}
unclampZ : Builder eng -> Builder eng
unclampZ =
    TB.unclampZ
