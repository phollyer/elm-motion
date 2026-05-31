module Anim.Property.Translate exposing
    ( Builder, AnimGroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , initUnit, initUnitX, initUnitY, initUnitZ
    , for, build
    , continueFor
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    , spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ
    , clampX, clampY, clampZ, unclampX, unclampY, unclampZ
    , bounds
    , setXYZ, setXY, setXZ, setX, setYZ, setY, setZ
    )

{-| Move elements along the X, Y, and Z axes.

**Default**: 0 for all axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available for any axis, the default will be used for that axis.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXY 200 100
            >> Translate.duration 1000
            >> Translate.easing EaseInOut
            >> Translate.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


## Initial Unit

Set the length [Unit](Anim-Unit#Unit) used by subsequent `init*` calls.
Order matters - `initUnit*` only affects `init*` calls that follow it in
the pipeline. Defaults to `Px`.

    import Anim.Unit exposing (Unit(..))

    init _ =
        ( { animState =
                Engine.init
                    [ Translate.initUnit Cqw
                        >> Translate.initX "box" 50
                    , Translate.initUnitX Cqw
                        >> Translate.initUnitY Cqh
                        >> Translate.initXY "ball" 40 20
                    ]
          }
        , Cmd.none
        )

@docs initUnit, initUnitX, initUnitY, initUnitZ


# Build

@docs for, build


# Continue a Running Animation

@docs continueFor


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value (Absolute)

@docs toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## End Value (Relative)

Move by a delta instead of to a fixed position. The end value is `current + delta`.

What counts as **current** depends on the engine: `Sub` and `WAAPI` always use the live
animated position, while `Keyframe` and `Transition` use the last configured start or end value.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for full per-engine behaviour.

@docs byXYZ, byXY, byXZ, byX, byYZ, byY, byZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring


## Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ


## Bounds

Keep translate values on each axis within a range you choose.

Values outside the range are clamped to the nearest boundary. Relative `byX`/`byY`/`byZ` moves
stop at the boundary instead of pushing past it — handy for keeping an element on-screen
during drags or resizes.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clampX, clampY, clampZ, unclampX, unclampY, unclampZ


## Resize

@docs bounds
@docs setXYZ, setXY, setXZ, setX, setYZ, setY, setZ

-}

import Anim.Internal.Builder as SB exposing (AnimBuilder)
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
        >> TB.applyInitCssUnitX
        >> TB.applyInitCssUnitY
        >> TB.applyInitCssUnitZ
        >> fromXYZ x y z
        >> TB.toXYZ x y z
        >> TB.build


{-| Set the initial X and Y position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initXY "animGroupName" 100 20 ] }
        , Cmd.none
        )

-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXY animationKey x y animBuilder =
    animBuilder
        |> TB.for animationKey
        |> TB.applyInitCssUnitX
        |> TB.applyInitCssUnitY
        |> fromXY x y
        |> TB.toXY x y
        |> TB.build


{-| Set the initial X and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initXZ "animGroupName" 100 50 ] }
        , Cmd.none
        )

-}
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initXZ animationKey x z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> TB.applyInitCssUnitX
        |> TB.applyInitCssUnitZ
        |> fromXZ x z
        |> TB.toXZ x z
        |> TB.build


{-| Set the initial X position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initX "animGroupName" 100 ] }
        , Cmd.none
        )

-}
initX : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initX animationKey x animBuilder =
    animBuilder
        |> TB.for animationKey
        |> TB.applyInitCssUnitX
        |> fromX x
        |> TB.toX x
        |> TB.build


{-| Set the initial Y and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initYZ "animGroupName" 20 50 ] }
        , Cmd.none
        )

-}
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
initYZ animationKey y z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> TB.applyInitCssUnitY
        |> TB.applyInitCssUnitZ
        |> fromYZ y z
        |> TB.toYZ y z
        |> TB.build


{-| Set the initial Y position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initY "animGroupName" 20 ] }
        , Cmd.none
        )

-}
initY : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initY animationKey y animBuilder =
    animBuilder
        |> TB.for animationKey
        |> TB.applyInitCssUnitY
        |> fromY y
        |> TB.toY y
        |> TB.build


{-| Set the initial Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : ( Model, Cmd Msg )
    init =
        ( { animState = Engine.init [ Translate.initZ "animGroupName" 50 ] }
        , Cmd.none
        )

-}
initZ : AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng
initZ animationKey z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> TB.applyInitCssUnitZ
        |> fromZ z
        |> TB.toZ z
        |> TB.build



-- Initial Unit


{-| Set the length [Unit](Anim-Unit#Unit) used by every subsequent `init*` call
for `Translate` values. Defaults to `Px`.

Order matters - only `init*` calls downstream of this setter in the pipeline
are affected; calls upstream keep their previously selected unit (or `Px`).
Later per-axis setters ([`initUnitX`](#initUnitX), [`initUnitY`](#initUnitY),
[`initUnitZ`](#initUnitZ)) override this setting on the relevant axis.

    import Anim.Unit exposing (Unit(..))

    Engine.init
        [ Translate.initUnit Cqw
            >> Translate.initX "box" 50
        ]

-}
initUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnit =
    SB.setTranslateInitCssUnit


{-| Set the X-axis unit used by every subsequent `init*` call for `Translate`
values. Overrides any unit set by [`initUnit`](#initUnit) on the X axis.
-}
initUnitX : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitX =
    SB.setTranslateInitCssUnitX


{-| Set the Y-axis unit used by every subsequent `init*` call for `Translate`
values. Overrides any unit set by [`initUnit`](#initUnit) on the Y axis.
-}
initUnitY : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitY =
    SB.setTranslateInitCssUnitY


{-| Set the Z-axis unit used by every subsequent `init*` call for `Translate`
values. Overrides any unit set by [`initUnit`](#initUnit) on the Z axis.
-}
initUnitZ : Unit -> AnimBuilder eng -> AnimBuilder eng
initUnitZ =
    SB.setTranslateInitCssUnitZ



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a translate animation `Builder` for the specified animation group.

Use this to start configuring a translate animation.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder eng -> Builder eng
for =
    TB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Translate.build
            >> ... -- continue with animation

-}
build : Builder eng -> AnimBuilder eng
build =
    TB.build



-- ============================================================
-- CONTINUE A RUNNING ANIMATION
-- ============================================================


{-| Like [for](#for), but inherits `easing`, `spring`, `delay`, and timing
(`duration` / `speed`) from the previous translate animation on the same
animation group.

Use this when the surrounding world changed (e.g. window resize, parent
relayout) and the animation should continue toward an updated target while
keeping the same visual character.

    -- on resize:
    Translate.continueFor "box"
        >> Translate.toX newTargetX
        >> Translate.build

Any of the four inherited fields can still be overridden by setting them
explicitly after `continueFor`:

    Translate.continueFor "box"
        >> Translate.toX newTargetX
        >> Translate.speed 200
        -- override inherited timing
        >> Translate.build

If no previous translate animation exists for the group, `continueFor`
behaves exactly like `for`.

-}
continueFor : AnimGroupName -> AnimBuilder eng -> Builder eng
continueFor =
    TB.forContinuing



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X, Y, and Z position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXYZ 100 20 50
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
fromXYZ =
    TB.fromXYZ


{-| Set the starting X and Y position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 20
            >> ... -- continue with animation

The Z position remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder eng -> Builder eng
fromXY =
    TB.fromXY


{-| Set the starting X and Z position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXZ 100 50
            >> ... -- continue with animation

The Y position remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder eng -> Builder eng
fromXZ =
    TB.fromXZ


{-| Set the starting X position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromX 100
            >> ... -- continue with animation

The Y and Z positions remain unchanged, or zero if not set.

-}
fromX : Float -> Builder eng -> Builder eng
fromX =
    TB.fromX


{-| Set the starting Y and Z position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromYZ 200 50
            >> ... -- continue with animation

The X position remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder eng -> Builder eng
fromYZ =
    TB.fromYZ


{-| Set the starting Y position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromY 50
            >> ... -- continue with animation

The X and Z positions remain unchanged, or zero if not set.

-}
fromY : Float -> Builder eng -> Builder eng
fromY =
    TB.fromY


{-| Set the starting Z position.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromZ 75
            >> ... -- continue with animation

The X and Y positions remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder eng -> Builder eng
fromZ =
    TB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X, Y, and Z position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXYZ 100 200 50
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
toXYZ =
    TB.toXYZ


{-| Set the target X and Y position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXY 100 200
            >> ... -- continue with animation

The Z position remains unchanged, or zero if not set.

-}
toXY : Float -> Float -> Builder eng -> Builder eng
toXY =
    TB.toXY


{-| Set the target X and Z position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXZ 100 50
            >> ... -- continue with animation

The Y position remains unchanged, or zero if not set.

-}
toXZ : Float -> Float -> Builder eng -> Builder eng
toXZ =
    TB.toXZ


{-| Set the target X position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 150
            >> ... -- continue with animation

The Y and Z positions remain unchanged, or zero if not set.

-}
toX : Float -> Builder eng -> Builder eng
toX =
    TB.toX


{-| Set the target Y and Z position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toYZ 200 75
            >> ... -- continue with animation

The X position remains unchanged, or zero if not set.

-}
toYZ : Float -> Float -> Builder eng -> Builder eng
toYZ =
    TB.toYZ


{-| Set the target Y position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 250
            >> ... -- continue with animation

The X and Z positions remain unchanged, or zero if not set.

-}
toY : Float -> Builder eng -> Builder eng
toY =
    TB.toY


{-| Set the target Z position for the current animation group.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toZ 75
            >> ... -- continue with animation

The X and Y positions remain unchanged, or zero if not set.

-}
toZ : Float -> Builder eng -> Builder eng
toZ =
    TB.toZ



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap target X, Y and Z values silently, cancelling any
in-flight animation on this property.
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

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 100
            >> Translate.byXYZ 50 -25 10
            >> ... -- continue with animation

This would animate from `(100, 100, 0)` to `(150, 75, 10)`.

-}
byXYZ : Float -> Float -> Float -> Builder eng -> Builder eng
byXYZ =
    TB.byXYZ


{-| Move by specific amounts on the X and Y axes.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 100
            >> Translate.byXY 50 -25
            >> ... -- continue with animation

This would animate from `(100, 100)` to `(150, 75)`.

-}
byXY : Float -> Float -> Builder eng -> Builder eng
byXY =
    TB.byXY


{-| Move by specific amounts on the X and Z axes.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.byXZ 50 10
            >> ... -- continue with animation

-}
byXZ : Float -> Float -> Builder eng -> Builder eng
byXZ =
    TB.byXZ


{-| Move by a specific amount on the X axis.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromX 100
            >> Translate.byX 50
            >> ... -- continue with animation

This would animate from `100` to `150` on the X axis.

-}
byX : Float -> Builder eng -> Builder eng
byX =
    TB.byX


{-| Move by specific amounts on the Y and Z axes.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.byYZ -25 10
            >> ... -- continue with animation

-}
byYZ : Float -> Float -> Builder eng -> Builder eng
byYZ =
    TB.byYZ


{-| Move by a specific amount on the Y axis.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromY 100
            >> Translate.byY -50
            >> ... -- continue with animation

This would animate from `100` to `50` on the Y axis.

-}
byY : Float -> Builder eng -> Builder eng
byY =
    TB.byY


{-| Move by a specific amount on the Z axis.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromZ 0
            >> Translate.byZ 100
            >> ... -- continue with animation

This would animate from `0` to `100` on the Z axis.

-}
byZ : Float -> Builder eng -> Builder eng
byZ =
    TB.byZ



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    TB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    TB.duration


{-| The speed represents how many pixels the element moves per second.

For example, lets take a translate animation from `(0, 0)` to `(100, 0)`.
A speed of `50.0` means the element will move 50 pixels per second, so our animation will take 2 seconds to complete (0 -> 50 in 1 second, then 50 -> 100 in the next second).

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 100
            >> Translate.speed 50
            >> ... -- continue with animation

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    TB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    TB.easing



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
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    TB.spring



-- ============================================================
-- UNIT
-- ============================================================


{-| Set the length [Unit](Anim-Unit#Unit) used to render translate values for
this property.

Defaults to `Px`. Setting a relative unit (`Percent`, `Vw`, `Vh`, `Rem`, `Em`)
makes the browser re-evaluate the rendered translation against current layout,
so the animation follows resize automatically.

    import Anim.Unit as Unit

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 50
            >> Translate.cssUnit Unit.Percent
            >> Translate.build

This setting takes precedence over any [length](Anim-Engine-WAAPI#cssUnit) set
on the engine.

`Sub` renders non-`Px` units normally. During `onResize` bounds remapping,
only `Px` translate axes are remapped; non-`Px` axes are left unchanged.

-}
cssUnit : Unit -> Builder eng -> Builder eng
cssUnit =
    TB.cssUnit


{-| Set the length [Unit](Anim-Unit#Unit) used to render the X-axis translate
value for this property. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitX` setter for the X axis.
-}
cssUnitX : Unit -> Builder eng -> Builder eng
cssUnitX =
    TB.cssUnitX


{-| Set the length [Unit](Anim-Unit#Unit) used to render the Y-axis translate
value for this property. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitY` setter for the Y axis.
-}
cssUnitY : Unit -> Builder eng -> Builder eng
cssUnitY =
    TB.cssUnitY


{-| Set the length [Unit](Anim-Unit#Unit) used to render the Z-axis translate
value for this property. Overrides any unit set by [`cssUnit`](#cssUnit) or by
the engine's `cssUnit`/`cssUnitZ` setter for the Z axis.
-}
cssUnitZ : Unit -> Builder eng -> Builder eng
cssUnitZ =
    TB.cssUnitZ



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep the X axis translate within `[min, max]` for this animation group.

The range stays in effect for future `animate` / `retarget` calls
until you call [unclampX](#unclampX). Values outside the range are clamped to the boundary,
and relative `byX` moves stop at the boundary instead of pushing past it.

Typical use is a resize handler that updates playfield bounds when the canvas changes:

    update msg model =
        case msg of
            GotCanvas (Ok element) ->
                let
                    w =
                        element.element.width

                    h =
                        element.element.height
                in
                ( { model | canvasW = w, canvasH = h }
                , WAAPI.retarget model.animState <|
                    Translate.continueFor animGroupName
                        >> Translate.clampX 0 (w - boxWidth)
                        >> Translate.clampY 0 (h - boxWidth)
                        >> Translate.toXY (targetX model.xPos w) (targetY h)
                        >> Translate.build
                )

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for more patterns.

-}
clampX : Float -> Float -> Builder eng -> Builder eng
clampX =
    TB.clampX


{-| Keep the Y axis translate within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour and example.

-}
clampY : Float -> Float -> Builder eng -> Builder eng
clampY =
    TB.clampY


{-| Keep the Z axis translate within `[min, max]` for this animation group.

See [clampX](#clampX) for behaviour and example.

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



-- ============================================================
-- RESIZE
-- ============================================================


{-| Apply new translate bounds for an anim group during resize.

Pass this inside an engine's `onResize` builder:

    Sub.onResize model.animState <|
        Translate.bounds "box"
            { x = Just { min = 0, max = newWidth - boxSize }
            , y = Nothing
            , z = Nothing
            }

You can resize multiple anim groups in one call:

    Sub.onResize model.animState <|
        Translate.bounds "box" boxBounds
            >> Translate.bounds "card" cardBounds

Leave an axis as `Nothing` to ignore it. The engine proportionally remaps
the in-flight animation onto the new range and pins its endpoints to it.

Only callable from inside an engine's `onResize` callback - the `withBounds`
capability on the builder type is what gates it.

-}
bounds : AnimGroupName -> SB.AxisRanges -> AnimBuilder { eng | withBounds : () } -> AnimBuilder { eng | withBounds : () }
bounds name ranges =
    TB.for name >> TB.bounds ranges >> TB.build
