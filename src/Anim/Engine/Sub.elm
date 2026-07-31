module Anim.Engine.Sub exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , EngineBuilder
    , init
    , for
    , animate, retarget, onResize
    , AnimEvent(..)
    , withProgressEvents
    , AnimMsg, update
    , subscriptions
    , attributes
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
    , getDuration, getElapsed, getRemaining
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

{-| A pure Elm subscription-based animation engine with full control, looping, and seamless mid-flight interruptions.

The pure-Elm counterpart to the WAAPI engine. Same feature set — looping, retargeting, per-axis freezing, pause/resume,
mid-flight queries, springs — but driven by Elm's `update` loop instead of the browser compositor. No JavaScript companion,
no ports, and interpolated values are available synchronously on every frame.

Reach for Sub when you want the WAAPI-like feature set but without the JS dependency.

📖 See
[Sub Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/sub/)
and
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/)
for details.


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

@docs animate, retarget, onResize


# Events

@docs AnimEvent


## Progress Events

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) for details.

@docs withProgressEvents


# Update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) for details.

@docs AnimMsg, update


# Subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/sub/#subscriptions) for details.

@docs subscriptions


# View

To render an animation, add `attributes` to the element you want to animate.

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) for details.

@docs attributes


# Playback

These functions are precedence functions, so they can operate as a global setting for all groups in the
builder chain, or you can set them on a per-group basis which overrides any global setting
for that group.

    Sub.iterations 3 -- global setting
        >> Sub.for "box"
        >> Sub.iterations 5 -- overrides global for this group
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

    Sub.freezeX [ Sub.translate ] -- global setting
        >> Sub.for "box"
        >> Sub.freezeY [ Sub.rotate ] -- adds to the inherited global freeze for this group
        >> ... -- other builders

📖 See [Interrupting Animations](https://phollyer.github.io/elm-motion/animation/concepts/interruptions/) for details.

@docs FreezeProperty, translate, rotate, scale, skew

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ


# Unfreeze

Unfreeze an axis to allow it to animate.

This is a precedence function, so it can operate as a global setting for all groups in the builder chain, or you
can remove axes on a per-group basis from the inherited global frozen axes for that group.

    Sub.freezeX [ Sub.translate ] -- global freeze setting
        >> Sub.for "box"
        >> Sub.unfreezeX [ Sub.translate ] -- removes the inherited global freeze for this group
        >> ... -- other builders

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ


# State Queries

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/sub/#state-queries) for details.

@docs anyRunning, isRunning, allComplete, isComplete, getProgress


## Timing Queries

@docs getDuration, getElapsed, getRemaining


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/sub/#property-queries) and
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
import Anim.Internal.Engine.Sub as Internal
import Anim.Unit exposing (Unit)
import Browser exposing (UrlRequest(..))
import Html
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Holds the Sub engine state.

Keep this in your model.

    type alias Model =
        { animState : Sub.AnimState }

-}
type alias AnimState =
    Internal.AnimState


{-| Type alias for the base [AnimBuilder](Anim.Builder#AnimBuilder) type.
-}
type alias AnimBuilder eng =
    Internal.AnimBuilder eng


{-| The name of the animation group you want to target.
-}
type alias AnimGroupName =
    String


{-| Builder type for Sub-only builders.

Use this in type annotations when a builder function should only work with this engine.

📖 See [Engine Capabilities](https://phollyer.github.io/elm-motion/animation/concepts/engine-capabilities/)
for patterns and examples.

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize the engine state with a list of property initializers.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    Sub.init
        [ Opacity.init "animGroupName" 0.5
        , ... -- other property initializers
        ]

-}
init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    Internal.init


{-| Select the animation group that subsequent property builders will target.

    Sub.for "animGroupName"
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

    import Anim.Engine.Sub as Sub

    { model
        | animState =
            Sub.animate model.animState <|
                Sub.for "animGroupName"
                    >> entryAnim
    }

-}
animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    Internal.animate


{-| Change the targeted properties instantly to their new values. If currently animating,
stop.

This is a convenience function for immediately snapping properties or axes to new values
without needing to construct a full animation builder with `animate`.

Just target the properties or axes you want to change, and any properties or axes you
don't mention will be left untouched - if mid-flight, they will continue.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Translate as Translate

    { model
        | animState =
            Sub.retarget model.animState <|
                Sub.for "animGroupName"
                    >> Translate.begin
                    >> Translate.toY 0
                    >> Translate.end
    }

-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget =
    Internal.retarget


{-| Update one or more animation groups after a layout change, or resize event.

Use this to set the new pixel bounds for your animation groups, and the animations
will adjust proportionally to the new bounds.

Typical resize handler:

    import Anim.Engine.Sub as Sub
    import Anim.Property.Translate as Translate

    GotTrack (Ok { element }) ->
        let
            bounds =
                { x = Just { min = 0, max = element.width - boxSize }
                , y = Nothing
                , z = Nothing
                }
        in
        ( { model
            | trackPx = element.element.width
            , animState =
                Sub.onResize model.animState <|
                    Translate.bounds "boxAnim" bounds
                        >> Translate.bounds "cardAnim" bounds
          }
        , Cmd.none
        )

**Note**: all `bounds` are pixel values, regardless of the CSS unit used in your builder.
It makes no sense to remap relative units, that's the browser's job, so this function will
only target pixel values. Any non-pixel units are ignored. So if "boxAnim" is using `Unit.Cqh`
for its axes, any new `bounds` will be ignored and the animation will continue as before.

📖 For resize strategies and examples, see
[Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/).

-}
onResize : AnimState -> (AnimBuilder Builder.ForResizeSub -> AnimBuilder Builder.ForResizeSub) -> AnimState
onResize =
    Internal.onResize



-- ============================================================
-- EVENTS
-- ============================================================


{-| Subscription animation lifecycle events.
-}
type AnimEvent
    = Run AnimGroupName
    | Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Restarted AnimGroupName
    | Paused AnimGroupName Float
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float



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

    Sub.withProgressEvents True -- global setting
        >> Sub.for "box"
        >> Sub.withProgressEvents False -- overrides global for this group
        >> ... -- other builders

-}
withProgressEvents : Bool -> EngineBuilder -> EngineBuilder
withProgressEvents =
    Builder.setEmitProgress



-- ============================================================
-- UPDATE
-- ============================================================


{-| Message type used with `update`.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and a list of [AnimEvent](#AnimEvent)s for you to pattern match on.

    import Anim.Engine.Sub as Sub

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            SubMsg animMsg ->
                let
                    ( animState, events ) =
                        Sub.update animMsg model.animState
                in
                ( List.foldl handleEvent { model | animState = animState } events
                , Cmd.none
                )

    handleEvent : Sub.AnimEvent -> (Model, Cmd Msg) -> ( Model, Cmd Msg )
    handleEvent event (model, cmd) =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond (List.filterMap toAnimEvent)


toAnimEvent : Internal.AnimEvent -> Maybe AnimEvent
toAnimEvent event =
    case event of
        Internal.Tick tickEvent ->
            toTickAnimEvent tickEvent

        Internal.Control controlEvent ->
            toControlAnimEvent controlEvent


toTickAnimEvent : Internal.TickEvent -> Maybe AnimEvent
toTickAnimEvent event =
    case event of
        Internal.Ended key ->
            Just (Ended key)

        Internal.Iteration key iterationNumber ->
            Just (Iteration key iterationNumber)

        Internal.Progress key progressValue ->
            Just (Progress key progressValue)


toControlAnimEvent : Internal.ControlEvent -> Maybe AnimEvent
toControlAnimEvent event =
    case event of
        Internal.Run key ->
            Just (Run key)

        Internal.Started key ->
            Just (Started key)

        Internal.Cancelled key progressValue ->
            Just (Cancelled key progressValue)

        Internal.Paused key progressValue ->
            Just (Paused key progressValue)

        Internal.Resumed key ->
            Just (Resumed key)

        Internal.Restarted key ->
            Just (Restarted key)



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to receive animation frame updates.

Your animations will not run without this subscription, and when
no animations are running, this subscription is silent and has no
performance impact.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions SubMsg model.animState

-}
subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    import Anim.Engine.Sub as Sub
    import Html exposing (div, text)

    div
        (Sub.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes



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

    introAnim : EngineBuilder -> EngineBuilder
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

    introAnim : EngineBuilder -> EngineBuilder
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

    introAnim : EngineBuilder -> EngineBuilder
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

    heroEntrance : EngineBuilder -> EngineBuilder
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

    draggableCardSettle : EngineBuilder -> EngineBuilder
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

    responsivePanelMotion : EngineBuilder -> EngineBuilder
    responsivePanelMotion =
        cssUnit Unit.Vw
            >> slidePanelIn
            >> growPanelHeight

-}
cssUnit : Unit -> EngineBuilder -> EngineBuilder
cssUnit =
    Builder.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : EngineBuilder -> EngineBuilder
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slideDrawerX
            >> alignDrawerLabelX

-}
cssUnitX : Unit -> EngineBuilder -> EngineBuilder
cssUnitX =
    Builder.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : EngineBuilder -> EngineBuilder
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slideSheetY
            >> alignSheetHeaderY

-}
cssUnitY : Unit -> EngineBuilder -> EngineBuilder
cssUnitY =
    Builder.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : EngineBuilder -> EngineBuilder
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> pushSceneBackgroundBack
            >> bringFloatingCardForward

-}
cssUnitZ : Unit -> EngineBuilder -> EngineBuilder
cssUnitZ =
    Builder.cssUnitZ


{-| Set the default length unit used for width values in Sub animations.

    responsiveCardWidth : EngineBuilder -> EngineBuilder
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> EngineBuilder -> EngineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in Sub animations.

    responsivePanelHeight : EngineBuilder -> EngineBuilder
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

`stop` is silent — no `Cancelled` event is emitted. `Cancelled` is
reserved for genuine external interruptions (e.g. browser-level
cancellation outside the engine's control).

    import Anim.Engine.Sub as Sub

    Sub.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.Sub as Sub

    Sub.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    import Anim.Engine.Sub as Sub

    Sub.restart "animGroup" model.animState

-}
restart : AnimGroupName -> AnimState -> AnimState
restart =
    Internal.restart


{-| Pause a running animation.

    import Anim.Engine.Sub as Sub

    Sub.pause "animGroup" model.animState

-}
pause : AnimGroupName -> AnimState -> AnimState
pause =
    Internal.pause


{-| Resume a paused animation.

    import Anim.Engine.Sub as Sub

    Sub.resume "animGroup" model.animState

-}
resume : AnimGroupName -> AnimState -> AnimState
resume =
    Internal.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

This function is a precedence function, so it can operate as a global setting
for all groups in the builder chain, or you can set it on a per-group basis
which overrides any global setting for that group.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    Sub.animate model.animState <|
        Sub.discreteEntry "display" "block"
            >> Sub.discreteEntry "visibility" "visible"
            >> Sub.for "box"
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

This function is a precedence function, so it can operate as a global setting
for all groups in the builder chain, or you can set it on a per-group basis
which overrides any global setting for that group.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    Sub.animate model.animState <|
        Sub.discreteExit "display" "block" "none"
            >> Sub.for "box"
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

    import Anim.Engine.Sub as Sub
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    Sub.transformOrder [ Scale, Rotate, Translate, Skew ] -- global setting
        >> Sub.for "box"
        >> Sub.transformOrder [ Rotate, Translate ] -- overrides global for this group
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


{-| Freeze the scale property.
-}
skew : FreezeProperty
skew =
    Internal.freezeSkew


{-| Freeze the translate property.
-}
translate : FreezeProperty
translate =
    Internal.freezeTranslate


{-| Freeze the X axis of the specified properties at their current animated values.

The named axis indicates which axis will remain frozen while you animate the others.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Translate as Translate

    Sub.animate model.animState <|
        Sub.freezeX [ Sub.translate ]
            >> Sub.for "box"
            >> Translate.begin
            >> Translate.toY 0
            >> Translate.end

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
anyRunning : AnimState -> Maybe Bool
anyRunning =
    Internal.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    Internal.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    Internal.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    Internal.allComplete


{-| Get the current progress of an animation group as a value from 0.0 to 1.0.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.Sub as Sub

    Sub.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress =
    Internal.getProgress


{-| Get the total duration of an animation group, in milliseconds.

This is the wall-clock time for a single iteration - the longest `delay + duration`
across the group's properties. Looping does not multiply it; each iteration reports
the same span.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.Sub as Sub

    Sub.getDuration "myAnimation" model.animState
    -- Just 600

-}
getDuration : AnimGroupName -> AnimState -> Maybe Int
getDuration =
    Internal.getDuration


{-| Get the elapsed time of an animation group within its current iteration, in milliseconds.

Counts from the moment the animation is triggered, so it includes any `delay` before motion
begins. Resets to `0` at each iteration boundary and never exceeds `getDuration`.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.Sub as Sub

    Sub.getElapsed "myAnimation" model.animState
    -- Just 300 (halfway through a 600ms animation)

-}
getElapsed : AnimGroupName -> AnimState -> Maybe Int
getElapsed =
    Internal.getElapsed


{-| Get the remaining time of an animation group within its current iteration, in milliseconds.

Equal to `getDuration - getElapsed`, clamped at `0`.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.Sub as Sub

    Sub.getRemaining "myAnimation" model.animState
    -- Just 300 (halfway through a 600ms animation)

-}
getRemaining : AnimGroupName -> AnimState -> Maybe Int
getRemaining =
    Internal.getRemaining



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
getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange =
    Internal.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart =
    Internal.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd =
    Internal.getPropertyEnd


{-| Get the current interpolated value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyCurrent =
    Internal.getPropertyCurrent



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    Internal.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart =
    Internal.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd =
    Internal.getColorPropertyEnd


{-| Get the current interpolated value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyCurrent =
    Internal.getColorPropertyCurrent



-- ============================
-- OPACITY
-- ============================


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    Internal.getOpacityRange


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    Internal.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    Internal.getOpacityEnd


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent =
    Internal.getOpacityCurrent



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


{-| Get the perspective origin range (start and end) of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange =
    Internal.getPerspectiveOriginRange


{-| Get the start perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

Returns `Just { x = 50, y = 50 }` if no explicit start value was set, which is the default when no start value is set.

-}
getPerspectiveOriginStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart =
    Internal.getPerspectiveOriginStart


{-| Get the end perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd =
    Internal.getPerspectiveOriginEnd


{-| Get the current perspective origin of an element based on its animation state.

Returns `Nothing` if the element has no perspective origin animation.

Returns the start perspective origin if the animation has not started yet.

Returns the current interpolated perspective origin if the animation is running.

Returns the end perspective origin if the animation has completed.

-}
getPerspectiveOriginCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginCurrent =
    Internal.getPerspectiveOriginCurrent



-- ============================
-- ROTATE
-- ============================


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    Internal.getRotateRange


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    Internal.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    Internal.getRotateEnd


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    Internal.getRotateCurrent



-- ============================
-- SCALE
-- ============================


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    Internal.getScaleRange


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    Internal.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    Internal.getScaleEnd


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    Internal.getScaleCurrent



-- ============================
-- SIZE
-- ============================


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    Internal.getSizeRange


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    Internal.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    Internal.getSizeEnd


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent =
    Internal.getSizeCurrent



-- ============================
-- SKEW
-- ============================


{-| Get the skew range (start and end) of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    Internal.getSkewRange


{-| Get the start skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewStart =
    Internal.getSkewStart


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd =
    Internal.getSkewEnd


{-| Get the current skew of an element based on its animation state.

Returns `Nothing` if the element has no skew animation.

Returns the start skew if the animation has not started yet.

Returns the current interpolated skew if the animation is running.

Returns the end skew if the animation has completed.

-}
getSkewCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewCurrent =
    Internal.getSkewCurrent



-- ============================
-- TRANSLATE
-- ============================


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    Internal.getTranslateRange


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    Internal.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    Internal.getTranslateEnd


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    Internal.getTranslateCurrent
