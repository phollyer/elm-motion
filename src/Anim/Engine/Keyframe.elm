module Anim.Engine.Keyframe exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , EngineBuilder
    , init
    , for
    , animate, retarget
    , CurrentTargetId, TargetId, AnimEvent(..)
    , AnimMsg, update
    , attributes
    , styleNode, styleNodeFor, maybeString
    , events, eventsStopPropagation
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    , iterations, loopForever, alternate
    , delay, duration, speed
    , easing
    , spring
    , stop, reset, restart, pause, resume
    , discreteEntry, discreteExit
    , transformOrder
    , anyRunning, isRunning, allComplete, isComplete, isCancelled
    , getPropertyEnd, getPropertyRange, getPropertyStart
    , getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart
    , getOpacityStart, getOpacityEnd, getOpacityRange
    , getPerspectiveOriginStart, getPerspectiveOriginEnd, getPerspectiveOriginRange
    , getRotateStart, getRotateEnd, getRotateRange
    , getScaleStart, getScaleEnd, getScaleRange
    , getSizeStart, getSizeEnd, getSizeRange
    , getSkewEnd, getSkewRange, getSkewStart
    , getTranslateStart, getTranslateEnd, getTranslateRange
    )

{-| CSS keyframe animations with browser-native performance.

This engine is a good fit for 'on-load' animations, or if you need looping, alternating, or pause/resume functionality.

📖 See
[Keyframe Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/keyframes/)
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

@docs animate, retarget


# Events

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) for details.

@docs CurrentTargetId, TargetId, AnimEvent


# Update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) for details.

@docs AnimMsg, update


# View

To render keyframes, add `attributes` to the element and include `styleNode`
or `styleNodeFor` somewhere in your view.

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) and
[Keyframe Style Node](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#keyframes-style-node)
for details.

@docs attributes

@docs styleNode, styleNodeFor, maybeString


# Event Listeners

📖 See [Events](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#events) for details.

@docs events, eventsStopPropagation


# Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight


# Playback

These functions are precedence functions, so they can operate as a global setting for all groups in the
builder chain, or you can set them on a per-group basis which overrides any global setting
for that group.

    Keyframe.iterations 3 -- global setting
        >> Keyframe.for "box"
        >> Keyframe.iterations 5 -- overrides global for this group
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


# Animation Control

📖 See [Controlling Animations](https://phollyer.github.io/elm-motion/animation/concepts/controlling-animations/) for details.

@docs stop, reset, restart, pause, resume


# Discrete Properties

📖 See [Discrete Properties](https://phollyer.github.io/elm-motion/animation/concepts/discrete-properties/) for details.

@docs discreteEntry, discreteExit


# Transform Order

📖 See [Transform Ordering](https://phollyer.github.io/elm-motion/animation/concepts/transform-order/) for details.

@docs transformOrder


# State Queries

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#state-queries) for details.

@docs anyRunning, isRunning, allComplete, isComplete, isCancelled


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#property-queries) and
[Properties](https://phollyer.github.io/elm-motion/animation/properties/getting-started/) for details.


## Custom Properties

@docs getPropertyEnd, getPropertyRange, getPropertyStart


## Custom Color Properties

@docs getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart


## Opacity

@docs getOpacityStart, getOpacityEnd, getOpacityRange


## Perspective Origin

@docs getPerspectiveOriginStart, getPerspectiveOriginEnd, getPerspectiveOriginRange


## Rotate

@docs getRotateStart, getRotateEnd, getRotateRange


## Scale

@docs getScaleStart, getScaleEnd, getScaleRange


## Size

@docs getSizeStart, getSizeEnd, getSizeRange


## Skew

@docs getSkewEnd, getSkewRange, getSkewStart


## Translate

@docs getTranslateStart, getTranslateEnd, getTranslateRange

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS
import Anim.Internal.Engine.Keyframe as Internal
import Anim.Internal.Engine.Keyframe.AnimGroup as AnimGroup
import Anim.Unit exposing (Unit)
import Html
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Holds the Keyframe engine state.

Keep this in your model.

    type alias Model =
        { animState : Keyframe.AnimState }

-}
type alias AnimState =
    Internal.AnimState


{-| Type alias for the base [AnimBuilder](Anim.Builder#AnimBuilder) type.
-}
type alias AnimBuilder eng =
    CSS.AnimBuilder eng


{-| The name of the animation group you want to target.
-}
type alias AnimGroupName =
    String


{-| Builder type for Keyframe-only builders.

Use this in type annotations when a builder function should only work with this engine.

Equivalent to `AnimBuilder ForKeyframe`.

📖 See [Engine Capabilities](https://phollyer.github.io/elm-motion/animation/concepts/engine-capabilities/)
for patterns and examples.

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize the engine state with optional property initializers.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    Keyframe.init
        [ Opacity.init "animGroupName" 0.5
        , ... -- other property initializers
        ]

-}
init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    Internal.init



-- ============================================================
-- TARGET
-- ============================================================


{-| Select the animation group that subsequent property builders will target.

    Keyframe.for "animGroupName"
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

    import Anim.Engine.Keyframe as Keyframe

    { model
        | animState =
            Keyframe.animate model.animState <|
                Keyframe.for "animGroupName"
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

Just target the properties or axes you want to change. Any other properties or axes on
the group will snap to their targeted end values if mid-flight.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Translate as Translate

    { model
        | animState =
            Keyframe.retarget model.animState <|
                Keyframe.for "animGroupName"
                    >> Translate.begin
                    >> Translate.toY 0
                    >> Translate.end
    }

-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget =
    Internal.retarget



-- ============================================================
-- EVENTS
-- ============================================================


{-| The ID of the element that owns the event listener.
-}
type alias CurrentTargetId =
    Maybe String


{-| The ID of the element that started the event.

This will be different from `CurrentTargetId` if the event bubbled from a child element.

-}
type alias TargetId =
    Maybe String


{-| CSS keyframe animation lifecycle events.
-}
type AnimEvent
    = Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName Int
    | Paused AnimGroupName
    | Resumed AnimGroupName
    | Restarted AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


{-| Message type used with `update`.

    import Anim.Engine.Keyframe as Keyframe

    type Msg
        = KeyframeMsg Keyframe.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle messages from this engine.

Returns the updated state and an event for this message, if one should
be surfaced.

    import Anim.Engine.Keyframe as Keyframe

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            KeyframeMsg animMsg ->
                let
                    ( animState, maybeEvent ) =
                        Keyframe.update animMsg model.animState

                    nextModel =
                        { model | animState = animState }
                in
                case maybeEvent of
                    Just event ->
                        handleAnimationEvent event nextModel

                    Nothing ->
                        ( nextModel, Cmd.none )

    handleAnimationEvent : Keyframe.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, Maybe AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond (Maybe.andThen toAnimEvent)


toAnimEvent : Internal.AnimEvent -> Maybe AnimEvent
toAnimEvent event =
    case event of
        Internal.Ended currentTargetId targetId animGroup ->
            Just (Ended currentTargetId targetId animGroup)

        Internal.Cancelled currentTargetId targetId animGroup ->
            Just (Cancelled currentTargetId targetId animGroup)

        Internal.Iteration currentTargetId targetId animGroup iteration ->
            Just (Iteration currentTargetId targetId animGroup iteration)

        Internal.Paused animGroup ->
            Just (Paused animGroup)

        Internal.Resumed animGroup ->
            Just (Resumed animGroup)

        Internal.Restarted animGroup ->
            Just (Restarted animGroup)

        Internal.Run currentTargetId targetId animGroup ->
            Just (Run currentTargetId targetId animGroup)



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div, text)

    div
        (Keyframe.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes


{-| Get a `<style>` node containing the keyframes for all animations.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div)

    view model =
        div []
            [ Keyframe.styleNode model.animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNode : AnimState -> Html.Html msg
styleNode =
    Internal.styleNode


{-| Get a `<style>` node containing keyframes for a specific animation group.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div)

    view model =
        div []
            [ Keyframe.styleNodeFor "animGroupName" model.animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
styleNodeFor =
    Internal.styleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString =
    Internal.maybeKeyframesString



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


{-| Receive keyframe animation lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div, text)

    type Msg
        = KeyframeMsg Keyframe.AnimMsg

    div
        (Keyframe.attributes "animGroupName" animState
            ++ Keyframe.events "animGroupName" KeyframeMsg
        )
        [ text "Animating element" ]

-}
events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events =
    Internal.events


{-| The same as [events](#events) but with propagation stopped.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div, text)

    div
        (Keyframe.attributes "animGroupName" animState
            ++ Keyframe.eventsStopPropagation "animGroupName" KeyframeMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Internal.eventsStopPropagation



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
    CSS.loopForever


{-| Make an animation alternate direction on each iteration.

Only has a visible effect when the animation runs more than once,
so calling it when `iterations` is unset or `1` automatically bumps
`iterations` to `2`.

An explicit `iterations` count (or `loopForever`) set before or after
`alternate` is preserved.

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
            >> growPanel

-}
cssUnit : Unit -> EngineBuilder -> EngineBuilder
cssUnit =
    Builder.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slidePanelIn
            >> growPanel

-}
cssUnitX : Unit -> EngineBuilder -> EngineBuilder
cssUnitX =
    Builder.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slidePanelIn
            >> growPanel

-}
cssUnitY : Unit -> EngineBuilder -> EngineBuilder
cssUnitY =
    Builder.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : AnimBuilder eng -> AnimBuilder eng
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> slidePanelIn
            >> growPanel

-}
cssUnitZ : Unit -> EngineBuilder -> EngineBuilder
cssUnitZ =
    Builder.cssUnitZ


{-| Set the default length unit used for width values in Keyframe animations.

    responsiveCardWidth : AnimBuilder eng -> AnimBuilder eng
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> slidePanelIn
            >> growPanel

-}
cssUnitWidth : Unit -> EngineBuilder -> EngineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in Keyframe animations.

    responsivePanelHeight : AnimBuilder eng -> AnimBuilder eng
    responsivePanelHeight =
        cssUnitHeight Unit.Vh
            >> slidePanelIn
            >> growPanel

-}
cssUnitHeight : Unit -> EngineBuilder -> EngineBuilder
cssUnitHeight =
    Builder.cssUnitHeight



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    import Anim.Engine.Keyframe as Keyframe

    Keyframe.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.Keyframe as Keyframe

    Keyframe.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    import Anim.Engine.Keyframe as Keyframe

    let
        ( newState, cmd ) =
            Keyframe.restart "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation.

    import Anim.Engine.Keyframe as Keyframe

    let
        ( newState, cmd ) =
            Keyframe.pause "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation.

    import Anim.Engine.Keyframe as Keyframe

    let
        ( newState, cmd ) =
            Keyframe.resume "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume =
    Internal.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied at every step of the animation, ensuring the element is
immediately in the target state when the animation starts. The browser already
knows the element's pre-animation state from its own CSS.

This function is a precedence function, so it can operate as a global setting
for all groups in the builder chain, or you can set it on a per-group basis
which overrides any global setting for that group.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    Keyframe.animate model.animState <|
        Keyframe.discreteEntry "display" "block"
            >> Keyframe.discreteEntry "pointer-events" "auto"
            >> Keyframe.for "box"
            >> Opacity.begin
            >> Opacity.to 1
            >> Opacity.end

-}
discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    CSS.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.
Therefore you need to set both entry and exit values for the property.

This function is a precedence function, so it can operate as a global setting
for all groups in the builder chain, or you can set it on a per-group basis
which overrides any global setting for that group.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`):

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    Keyframe.animate model.animState <|
        Keyframe.discreteExit "display" "block" "none"
            >> Keyframe.for "box"
            >> Opacity.begin
            >> Opacity.to 0
            >> Opacity.end

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    CSS.discreteExit



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

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    Keyframe.transformOrder [ Scale, Rotate, Translate, Skew ] -- global setting
        >> Keyframe.for "box"
        >> Keyframe.transformOrder [ Rotate, Translate ] -- overrides global for this group
        >> ... -- other builders

-}
transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    CSS.anyRunning AnimGroup.isRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    CSS.isRunning AnimGroup.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    CSS.isComplete AnimGroup.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete AnimGroup.isComplete


{-| Check if a specific animation group was cancelled.

Returns `Nothing` if there are no animations for the group.

-}
isCancelled : AnimGroupName -> AnimState -> Maybe Bool
isCancelled =
    CSS.isCancelled AnimGroup.isCancelled



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
    CSS.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart =
    CSS.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd =
    CSS.getPropertyEnd



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    CSS.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart =
    CSS.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd =
    CSS.getColorPropertyEnd



-- ============================
-- OPACITY
-- ============================


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    CSS.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    CSS.getOpacityRange



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


{-| Get the start perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

Returns `Just { x = 50, y = 50 }` if no explicit start value was set, which is the default when no start value is set.

-}
getPerspectiveOriginStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart =
    CSS.getPerspectiveOriginStart


{-| Get the end perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd =
    CSS.getPerspectiveOriginEnd


{-| Get the perspective origin range (start and end) of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange =
    CSS.getPerspectiveOriginRange



-- ============================
-- ROTATE
-- ============================


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    CSS.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    CSS.getRotateRange



-- ============================
-- SCALE
-- ============================


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    CSS.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    CSS.getScaleRange



-- ============================
-- SIZE
-- ============================


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    CSS.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    CSS.getSizeRange



-- ============================
-- SKEW
-- ============================


{-| Get the start skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

Returns `Just { x = 0, y = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSkewStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewStart =
    CSS.getSkewStart


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd =
    CSS.getSkewEnd


{-| Get the skew range (start and end) of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    CSS.getSkewRange



-- ============================
-- TRANSLATE
-- ============================


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    CSS.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    CSS.getTranslateRange
