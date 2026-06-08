module Anim.Engine.WAAPI exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , EngineBuilder
    , init
    , for
    , animate, fireAndForget, retarget
    , AnimEvent(..)
    , withProgressEvents, setUpdateThrottle
    , AnimMsg, update
    , subscriptions
    , attributes
    , onResize
    , iterations, loopForever, alternate
    , delay, duration, speed
    , easing
    , spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    , stop, reset, restart, pause, resume
    , discreteEntry, discreteExit
    , transformOrder
    , FreezeProperty, translate, rotate, scale, skew
    , freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ
    , unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ
    , anyRunning, isRunning, allComplete, isComplete, getProgress
    , getPropertyCurrent, getPropertyEnd, getPropertyRange, getPropertyStart
    , getColorPropertyCurrent, getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart
    , getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getPerspectiveOriginRange, getPerspectiveOriginStart, getPerspectiveOriginEnd, getPerspectiveOriginCurrent
    , getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent
    , getSkewRange, getSkewStart, getSkewEnd, getSkewCurrent
    , getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent
    )

{-| Use the Web Animations API through ports.

Choose this engine when you want browser-driven animation with the maximum feature set.

📖 See
[WAAPI Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/waapi/)
and
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/)
for engine details, and [JS Installation](https://phollyer.github.io/elm-motion/installation/#waapi-javascript)
for setup instructions.


# Ports

To use this engine, you need to make your module a port module and set up two ports:

    port module MyModule exposing (..)

    import Json.Decode as Decode
    import Json.Encode as Encode


    -- Outgoing port to send animation commands to JavaScript
    port motionCmd : Encode.Value -> Cmd msg

    -- Incoming port to receive animation messages from JavaScript
    port motionMsg : (Decode.Value -> msg) -> Sub msg


# Types

@docs AnimState, AnimGroupName


## Builders

@docs AnimBuilder


### Engine Builder

@docs EngineBuilder


# Initialize

📖 See [Initialize](https://phollyer.github.io/elm-motion/animation/workflow/init/) for details.

@docs init


# Target

@docs for


# Trigger

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) for details.

@docs animate, fireAndForget, retarget


# Events

@docs AnimEvent


## Progress Events

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) for details.

@docs withProgressEvents, setUpdateThrottle


# Update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) for details.

@docs AnimMsg, update


# Subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/waapi/#subscriptions) for details.

@docs subscriptions


# View

Add `attributes` to the element you want to animate.

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) for details.

@docs attributes


# Responsive Animations

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/#path-3-measured-pixel-values) for details.

@docs onResize


# Playback

These functions are precedence functions, so they can operate as a global setting for all groups in the
builder chain, or you can set them on a per-group basis which overrides any global setting
for that group.

    WAAPI.iterations 3 -- global setting
        >> WAAPI.for "box"
        >> WAAPI.iterations 5 -- overrides global for this group
        >> ... -- other builders

@docs iterations, loopForever, alternate


# Timing

📖 See [Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/) for details.

@docs delay, duration, speed


# Easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) for details.

@docs easing


# Spring

@docs spring


# Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight


# Animation Control

📖 See [Controlling Animations](https://phollyer.github.io/elm-motion/animation/concepts/controlling-animations/) for details.

@docs stop, reset, restart, pause, resume


# Discrete Properties

📖 See [Discrete Properties](https://phollyer.github.io/elm-motion/animation/concepts/discrete-properties/) for details.

@docs discreteEntry, discreteExit


# Transform Order

📖 See [Transform Ordering](https://phollyer.github.io/elm-motion/animation/concepts/transform-order/) for details.

@docs transformOrder


# Freeze

Freeze an axis to hold it in place while other axes or properties animate.

This is a precedence function, so it can operate as a global setting for all groups in the builder chain, or you
can add a per-group freeze on top of the inherited global frozen axes for that group.

    WAAPI.freezeX [ WAAPI.translate ] -- global setting
        >> WAAPI.for "box"
        >> WAAPI.freezeX [ WAAPI.rotate ] -- adds to the inherited global freeze for this group
        >> ... -- other builders

📖 See [Interrupting Animations](https://phollyer.github.io/elm-motion/animation/concepts/interrupting-animations/) for details.

@docs FreezeProperty, translate, rotate, scale, skew

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ


# Unfreeze

Unfreeze an axis to allow it to animate.

This is a precedence function, so it can operate as a global setting for all groups in the builder chain, or you
can remove axes on a per-group basis from the inherited global frozen axes for that group.

    WAAPI.freezeX [ WAAPI.translate ] -- global freeze setting
        >> WAAPI.for "box"
        >> WAAPI.unfreezeX [ WAAPI.translate ] -- removes the inherited global freeze for this group
        >> ... -- other builders

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ


# State Queries

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/waapi/#state-queries) for details.

@docs anyRunning, isRunning, allComplete, isComplete, getProgress


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/waapi/#property-queries) and
[Properties](https://phollyer.github.io/elm-motion/animation/properties/getting-started/) for details.


## Custom Properties

@docs getPropertyCurrent, getPropertyEnd, getPropertyRange, getPropertyStart


## Custom Color Properties

@docs getColorPropertyCurrent, getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart


## Opacity

@docs getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent


## Perspective Origin

@docs getPerspectiveOriginRange, getPerspectiveOriginStart, getPerspectiveOriginEnd, getPerspectiveOriginCurrent


## Rotate

@docs getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent


## Scale

@docs getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent


## Size

@docs getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent


## Skew

@docs getSkewRange, getSkewStart, getSkewEnd, getSkewCurrent


## Translate

@docs getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI as Internal
import Anim.Unit exposing (Unit)
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Holds the WAAPI engine state.

Keep this in your model.

The `msg` type parameter is your `Msg` type.

    type alias Model =
        { animState : WAAPI.AnimState Msg }

-}
type alias AnimState msg =
    Internal.AnimState msg


{-| Base animation builder type for this engine.
-}
type alias AnimBuilder eng =
    Internal.AnimBuilder eng


{-| The name of the animation group you want to target.
-}
type alias AnimGroupName =
    String


{-| Builder type for WAAPI-only builders.

Use this in type annotations when a builder function should only work with this engine.

📖 See [Engine Capabilities](https://phollyer.github.io/elm-motion/animation/concepts/engine-capabilities/)
for patterns and examples.

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize the engine state.

Takes the command port, message port, and a list of property initializers:

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    WAAPI.init motionCmd motionMsg <|
        [ Opacity.init "animGroupName" 0.5
        , ... -- any other property initializers
        ]

-}
init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (EngineBuilder -> EngineBuilder) -> AnimState msg
init =
    Internal.init


{-| Select the animation group that subsequent property builders will target.

    WAAPI.for "animGroupName"
        >> Opacity.begin
        >> Opacity.to 0.2
        >> Opacity.end

-}
for : AnimGroupName -> EngineBuilder -> EngineBuilder
for =
    Builder.for



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

Returns the updated animation state and the command to send to JavaScript.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, animCmd ) =
            WAAPI.animate model.animState entryAnim
    in
    ( { model | animState = animState }, animCmd )

-}
animate : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
animate =
    Internal.animate


{-| Execute a fire-and-forget animation without state tracking.

    import Anim.Engine.WAAPI as WAAPI
    import Json.Encode as Encode

    port motionCmd : Encode.Value -> Cmd msg

    WAAPI.fireAndForget motionCmd entryAnim

Useful if you don't need to track the animation state in your model or handle events
from the engine, and just want to trigger an animation with a one-off command.

-}
fireAndForget : (Encode.Value -> Cmd msg) -> (EngineBuilder -> EngineBuilder) -> Cmd msg
fireAndForget =
    Internal.fireAndForget


{-| Change the targeted properties instantly to their new values. If currently animating,
stop.

This is a convenience function for immediately snapping properties or axes to new values
without needing to construct a full animation builder with `animate`.

Just target the properties or axes you want to change, and any properties or axes you
don't mention will be left untouched - if mid-flight, they will continue.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Translate as Translate

    let
        ( animState, animCmd ) =
            WAAPI.retarget model.animState <|
                WAAPI.for "animGroupName"
                    >> Translate.begin
                    >> Translate.toY 0
                    >> Translate.end
    in
    ( { model | animState = animState }, animCmd )

-}
retarget : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
retarget =
    Internal.retarget



-- ============================================================
-- EVENTS
-- ============================================================


{-| Animation lifecycle events from this engine.
-}
type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Restarted AnimGroupName
    | Paused AnimGroupName Float
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | AnimError String



-- ============================================================
-- PROGRESS EVENTS
-- ============================================================


{-| Opt in to per-frame `Progress` events.

Off by default.

Progress events can create a lot of noise in your update loop,
especially when debugging the `Msg` flow in your app. Therefore
they are suppressed by default and you need to explicitly opt in
to receive them.

This is a precedence function, so it can operate as a global setting for all
groups in the builder chain, or you can set it on a per-group basis which
overrides any global setting for that group.

    WAAPI.withProgressEvents True -- global setting
        >> WAAPI.for "box"
        >> WAAPI.withProgressEvents False -- overrides global for this group
        >> ... -- other builders

-}
withProgressEvents : Bool -> EngineBuilder -> EngineBuilder
withProgressEvents =
    Builder.setEmitProgress


{-| Set the minimum interval in milliseconds between per-frame
`propertyUpdate` emissions from the JavaScript runtime.

The visual animation is driven by the browser compositor and is **never**
affected by this setting - it only controls how much port traffic is generated.

This is a precedence function, so it can operate as a global setting for all
groups in the builder chain, or you can set it on a per-group basis which
overrides any global setting for that group.

  - Pass `0` (the default) to emit on every `requestAnimationFrame` tick,
    matching the display refresh rate (60 Hz, 120 Hz, 144 Hz, …).
  - Pass a positive number of milliseconds to cap the emission rate, e.g.
    `16` for ~60 Hz, `33` for ~30 Hz.

**Note**: Higher throttle values reduce Elm-side mid-flight precision for
queries and interruption bookkeeping.

    WAAPI.setUpdateThrottle 33 -- global default
            >> WAAPI.for "hero"
            >> WAAPI.setUpdateThrottle 0 -- dense updates for interactions
            >> ... -- other builders
            >> WAAPI.for "background"
            >> WAAPI.setUpdateThrottle 50 -- lower traffic for passive motion
            >> ... -- other builders

-}
setUpdateThrottle : Int -> EngineBuilder -> EngineBuilder
setUpdateThrottle =
    Builder.setUpdateThrottle



-- ============================================================
-- UPDATE
-- ============================================================


{-| Message type used with `update`.

    import Anim.Engine.WAAPI as WAAPI

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle messages from this engine.

Returns the updated state and the event for this message.

Messages that do not belong to this engine return `(animState, Nothing)`.

    import Anim.Engine.WAAPI as WAAPI

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            WaapiMsg animMsg ->
                let
                    ( animState, maybeAnimEvent ) =
                        WAAPI.update animMsg model.animState
                in
                handleAnimationEvent maybeAnimEvent { model | animState = animState }

    handleAnimationEvent : Maybe WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond (Maybe.map toAnimEvent)


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent internalEvent =
    case internalEvent of
        Internal.Started animGroup ->
            Started animGroup

        Internal.Ended animGroup ->
            Ended animGroup

        Internal.Cancelled animGroup progress ->
            Cancelled animGroup progress

        Internal.Restarted animGroup ->
            Restarted animGroup

        Internal.Paused animGroup progress ->
            Paused animGroup progress

        Internal.Resumed animGroup ->
            Resumed animGroup

        Internal.Iteration animGroup count ->
            Iteration animGroup count

        Internal.Progress animGroup progress ->
            Progress animGroup progress

        Internal.AnimError errorMsg ->
            AnimError errorMsg



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to receive animation updates from JavaScript.

Without this, your app won't receive any animation events or updates.

    import Anim.Engine.WAAPI as WAAPI

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions WaapiMsg model.animState

-}
subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply baseline and state styles to your element.

Sets the element's starting, current, and end property values as inline styles,
and adds the `data-anim-target` attribute so the JavaScript companion can locate
the element when the animation is triggered.

    import Anim.Engine.WAAPI as WAAPI
    import Html exposing (div, text)

    div
        (WAAPI.attributes "animGroupName" model.animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState msg -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- RESPONSIVE ANIMATIONS
-- ============================================================


{-| A resize handler that updates animation configurations in response to a
layout changes.

Pair this with the `bounds` functions in property modules in order to remap the
properties to new element dimensions or positions on the fly.

Example resize handler targeting two groups in one call:

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Scale as Scale
    import Anim.Property.Translate as Translate

    GotTrack (Ok element) ->
        let
            ( animState, animCmd ) =
                WAAPI.onResize model.animState <|
                    Translate.bounds "box" translateBounds
                        >> Scale.bounds "cube" scaleBounds
        in
        ( { model | animState = animState }
        , animCmd
        )

-}
onResize : AnimState msg -> (AnimBuilder Builder.ForResizeWAAPI -> AnimBuilder Builder.ForResizeWAAPI) -> ( AnimState msg, Cmd msg )
onResize =
    Internal.onResize



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times an animation should repeat.
-}
iterations : Int -> EngineBuilder -> EngineBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.
-}
loopForever : EngineBuilder -> EngineBuilder
loopForever =
    Internal.loopForever


{-| Make an animation alternate direction on each iteration.

`alternate` only has a visible effect when the animation runs more than once,
so calling it when `iterations` is unset or `1` automatically bumps
`iterations` to `2`. An explicit `iterations` count (or `loopForever`) set
before or after `alternate` is preserved.

-}
alternate : EngineBuilder -> EngineBuilder
alternate =
    Builder.alternate



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the global delay for all animations in this builder.

    introAnim : AnimBuilder eng -> AnimBuilder eng
    introAnim =
        delay 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
delay : Int -> EngineBuilder -> EngineBuilder
delay =
    Builder.delay


{-| Set the global duration for all animations in this builder.

    introAnim : AnimBuilder eng -> AnimBuilder eng
    introAnim =
        duration 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
duration : Int -> EngineBuilder -> EngineBuilder
duration =
    Builder.duration


{-| Set the global speed for all animations in this builder.

    introAnim : AnimBuilder eng -> AnimBuilder eng
    introAnim =
        speed 300
            >> slideDownHeader
            >> slideInSidebar
            >> slideUpContent

-}
speed : Float -> EngineBuilder -> EngineBuilder
speed =
    Builder.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the global easing function.

    heroEntrance : AnimBuilder eng -> AnimBuilder eng
    heroEntrance =
        easing EaseInOut
            >> fadeInHeroTitle
            >> slideInHeroArtwork
            >> revealPrimaryCta

-}
easing : Easing -> EngineBuilder -> EngineBuilder
easing =
    Builder.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Set the global spring.

    draggableCardSettle : AnimBuilder eng -> AnimBuilder eng
    draggableCardSettle =
        spring Spring.wobbly
            >> settleCardPosition
            >> settleCardShadow

-}
spring : Spring -> EngineBuilder -> EngineBuilder
spring =
    Builder.spring



-- ============================================================
-- UNIT
-- ============================================================


{-| Set the default length unit for all length-bearing properties.

    responsivePanelMotion : AnimBuilder eng -> AnimBuilder eng
    responsivePanelMotion =
        cssUnit Unit.Vw
            >> slidePanelIn
            >> growPanelHeight

-}
cssUnit : Unit -> EngineBuilder -> EngineBuilder
cssUnit =
    Builder.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slideDrawerX
            >> alignDrawerLabelX

-}
cssUnitX : Unit -> EngineBuilder -> EngineBuilder
cssUnitX =
    Builder.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slideSheetY
            >> alignSheetHeaderY

-}
cssUnitY : Unit -> EngineBuilder -> EngineBuilder
cssUnitY =
    Builder.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : AnimBuilder eng -> AnimBuilder eng
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> pushSceneBackgroundBack
            >> bringFloatingCardForward

-}
cssUnitZ : Unit -> EngineBuilder -> EngineBuilder
cssUnitZ =
    Builder.cssUnitZ


{-| Set the default length unit used for width values in WAAPI animations.

    responsiveCardWidth : AnimBuilder eng -> AnimBuilder eng
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> EngineBuilder -> EngineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in WAAPI animations.

    responsivePanelHeight : AnimBuilder eng -> AnimBuilder eng
    responsivePanelHeight =
        cssUnitHeight Unit.Vh
            >> expandPanelHeight
            >> alignPanelHeaderY

-}
cssUnitHeight : Unit -> EngineBuilder -> EngineBuilder
cssUnitHeight =
    Builder.cssUnitHeight



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, stopCmd ) =
            WAAPI.stop "animGroup" model.animState
    in
    ( { model | animState = animState }, stopCmd )

-}
stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, resetCmd ) =
            WAAPI.reset "animGroup" model.animState
    in
    ( { model | animState = animState }, resetCmd )

-}
reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, restartCmd ) =
            WAAPI.restart "animGroup" model.animState
    in
    ( { model | animState = animState }, restartCmd )

-}
restart : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, pauseCmd ) =
            WAAPI.pause "animGroup" model.animState
    in
    ( { model | animState = animState }, pauseCmd )

-}
pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, resumeCmd ) =
            WAAPI.resume "animGroup" model.animState
    in
    ( { model | animState = animState }, resumeCmd )

-}
resume : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
resume =
    Internal.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

These functions are precedence functions, so they can operate as a global setting
for all groups in the builder chain, or you can set them on a per-group basis which
overrides any global setting for that group.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    WAAPI.animate model.animState <|
        WAAPI.discreteEntry "display" "block"
            >> WAAPI.discreteEntry "visibility" "visible"
            >> WAAPI.for "box"
            >> Opacity.begin
            >> Opacity.to 1
            >> Opacity.end

-}
discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    Internal.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.
Therefore you need to set both entry and exit values for the property.

These functions are precedence functions, so they can operate as a global setting
for all groups in the builder chain, or you can set them on a per-group basis
which overrides any global setting for that group.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    WAAPI.animate model.animState <|
        WAAPI.discreteExit "display" "block" "none"
            >> WAAPI.for "box"
            >> Opacity.begin
            >> Opacity.to 0
            >> Opacity.end

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    Internal.discreteExit



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Set the transform order.

The transform order specifies how `translate`, `rotate`, `skew` and `scale` transforms
are combined. Start the list with the transform to apply first.

This is a precedence function, so it can operate as a global setting for all groups in the
builder chain, or you can set it on a per-group basis which overrides any global setting
for that group.

Any missing transforms are automatically appended in the default order
(`Translate` → `Rotate` → `Skew` → `Scale`).

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    WAAPI.transformOrder [ Scale, Rotate, Translate, Skew ] -- global setting
        >> WAAPI.for "box"
        >> WAAPI.transformOrder [ Rotate, Translate ] -- overrides global for this group
        >> ... -- other builders

-}
transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- FREEZE
-- ============================================================


{-| Identifies a property that can be frozen at its current animated position.

Use with [freezeX](#freezeX), [freezeY](#freezeY), etc. to hold specific axes
at their current values during animation interruptions.

-}
type alias FreezeProperty =
    Internal.FreezeProperty


{-| Freeze the translate property.
-}
translate : FreezeProperty
translate =
    Internal.freezeTranslate


{-| Freeze the rotate property.
-}
rotate : FreezeProperty
rotate =
    Internal.freezeRotate


{-| Freeze the scale property.
-}
scale : FreezeProperty
scale =
    Internal.freezeScale


{-| Freeze the skew property.
-}
skew : FreezeProperty
skew =
    Internal.freezeSkew


{-| Freeze the X axis of the specified properties at their current animated values.

The named axis indicates which axis will remain frozen while you animate the others.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Translate as Translate

    let
        ( animState, animCmd ) =
            WAAPI.animate model.animState <|
                WAAPI.freezeX [ WAAPI.translate ]
                    >> WAAPI.for "box"
                    >> Translate.begin
                    >> Translate.toY 0
                    >> Translate.end
    in
    ( { model | animState = animState }, animCmd )

-}
freezeX : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeX =
    Internal.freezeAxes [ "x" ]


{-| Freeze the Y axis of the specified properties at their current animated values.
-}
freezeY : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeY =
    Internal.freezeAxes [ "y" ]


{-| Freeze the Z axis of the specified properties at their current animated values.
-}
freezeZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeZ =
    Internal.freezeAxes [ "z" ]


{-| Freeze the X and Y axes of the specified properties at their current animated values.
-}
freezeXY : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeXY =
    Internal.freezeAxes [ "x", "y" ]


{-| Freeze the X and Z axes of the specified properties at their current animated values.
-}
freezeXZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeXZ =
    Internal.freezeAxes [ "x", "z" ]


{-| Freeze the Y and Z axes of the specified properties at their current animated values.
-}
freezeYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeYZ =
    Internal.freezeAxes [ "y", "z" ]


{-| Freeze all axes of the specified properties at their current animated values.
-}
freezeXYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeXYZ =
    Internal.freezeAxes [ "x", "y", "z" ]



-- ============================================================
-- UNFREEZE
-- ============================================================


{-| Unfreeze the X axis of the specified properties, allowing it to animate again.
-}
unfreezeX : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeX =
    Internal.unfreezeAxes [ "x" ]


{-| Unfreeze the Y axis of the specified properties, allowing it to animate again.
-}
unfreezeY : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeY =
    Internal.unfreezeAxes [ "y" ]


{-| Unfreeze the Z axis of the specified properties, allowing it to animate again.
-}
unfreezeZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeZ =
    Internal.unfreezeAxes [ "z" ]


{-| Unfreeze the X and Y axes of the specified properties.
-}
unfreezeXY : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeXY =
    Internal.unfreezeAxes [ "x", "y" ]


{-| Unfreeze the X and Z axes of the specified properties.
-}
unfreezeXZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeXZ =
    Internal.unfreezeAxes [ "x", "z" ]


{-| Unfreeze the Y and Z axes of the specified properties.
-}
unfreezeYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeYZ =
    Internal.unfreezeAxes [ "y", "z" ]


{-| Unfreeze all axes of the specified properties.
-}
unfreezeXYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeXYZ =
    Internal.unfreezeAxes [ "x", "y", "z" ]



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState msg -> Maybe Bool
anyRunning =
    Internal.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState msg -> Maybe Bool
isRunning =
    Internal.isRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState msg -> Maybe Bool
allComplete =
    Internal.allComplete


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState msg -> Maybe Bool
isComplete =
    Internal.isComplete


{-| Get the current progress of an animation group as a value from 0.0 to 1.0.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.WAAPI as WAAPI

    WAAPI.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress =
    Internal.getProgress



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================
--
--
-- ============================
-- CUSTOM PROPERTY
-- ============================


{-| Get the custom property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getPropertyRange =
    Internal.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyStart =
    Internal.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyEnd =
    Internal.getPropertyEnd


{-| Get the current interpolated value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyCurrent =
    Internal.getPropertyCurrent



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    Internal.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyStart =
    Internal.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyEnd =
    Internal.getColorPropertyEnd


{-| Get the current interpolated value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyCurrent =
    Internal.getColorPropertyCurrent



-- ============================
-- OPACITY
-- ============================


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart =
    Internal.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityEnd =
    Internal.getOpacityEnd


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityCurrent =
    Internal.getOpacityCurrent


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    Internal.getOpacityRange



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


{-| Get the start perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

Returns `Just { x = 50, y = 50 }` if no explicit start value was set, which is the default when no start value is set.

-}
getPerspectiveOriginStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart =
    Internal.getPerspectiveOriginStart


{-| Get the end perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd =
    Internal.getPerspectiveOriginEnd


{-| Get the current perspective origin of an element based on its animation state.

Returns `Nothing` if the element has no perspective origin animation.

Returns the current perspective origin from the latest engine snapshot.

-}
getPerspectiveOriginCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginCurrent =
    Internal.getPerspectiveOriginCurrent


{-| Get the perspective origin range (start and end) of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange =
    Internal.getPerspectiveOriginRange



-- ============================
-- ROTATE
-- ============================


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    Internal.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    Internal.getRotateEnd


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    Internal.getRotateCurrent


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    Internal.getRotateRange



-- ============================
-- SCALE
-- ============================


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    Internal.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    Internal.getScaleEnd


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    Internal.getScaleCurrent


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    Internal.getScaleRange



-- ============================
-- SIZE
-- ============================


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart =
    Internal.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd =
    Internal.getSizeEnd


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent =
    Internal.getSizeCurrent


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    Internal.getSizeRange



-- ============================
-- SKEW
-- ============================


{-| Get the start skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

Returns `Just {x = 0, y = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getSkewStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewStart =
    Internal.getSkewStart


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewEnd =
    Internal.getSkewEnd


{-| Get the current skew of an element based on its animation state.

Returns `Nothing` if the element has no skew animation.

Returns the start skew if the animation has not started yet.

Returns the current interpolated skew if the animation is running.

Returns the end skew if the animation has completed.

-}
getSkewCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewCurrent =
    Internal.getSkewCurrent


{-| Get the skew range (start and end) of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    Internal.getSkewRange



-- ============================
-- TRANSLATE
-- ============================


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    Internal.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    Internal.getTranslateEnd


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    Internal.getTranslateCurrent


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    Internal.getTranslateRange
