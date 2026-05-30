module Anim.Engine.Transition exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , EngineBuilder
    , init
    , animate, retarget
    , CurrentTargetId, TargetId, AnimEvent(..)
    , AnimMsg, update
    , attributes
    , events, eventsStopPropagation
    , delay, duration, speed
    , easing
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    , stop, reset
    , discreteEntry, startingStyleNode, startingStyleNodeFor, discreteExit
    , anyRunning, isRunning, allComplete, isComplete, isCancelled
    , getPropertyEnd
    , getColorPropertyEnd
    , getOpacityEnd
    , getPerspectiveOriginEnd
    , getRotateEnd
    , getScaleEnd
    , getSizeEnd
    , getSkewEnd
    , getTranslateEnd
    )

{-| Use CSS transitions for simple A to B animations.

This engine is a good fit when you want browser-native transitions with a small API surface.

📖 For setup, examples, and behaviour details, see the
[Transition Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/transition/)
and the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/).


# Types

@docs AnimState, AnimGroupName


## Builders

@docs AnimBuilder


### Engine Builder

Use this in type annotations when a builder function should only work with the Transition engine.

@docs EngineBuilder


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-motion/animation/workflow/init/) in the docs.


# Trigger

@docs animate, retarget

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) in the docs.


# Events

@docs CurrentTargetId, TargetId, AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) in the docs.


# View

To render a transition, add `attributes` to the element you want to animate.

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) in the docs.


# Event Listeners

@docs events, eventsStopPropagation

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) in the docs.


# Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/) in the docs.


# Easing

@docs easing


# Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight


# Animation Control

@docs stop, reset

📖 See [Controlling Animations](https://phollyer.github.io/elm-motion/animation/concepts/controlling-animations/) in the docs.

# Discrete Properties

@docs discreteEntry, startingStyleNode, startingStyleNodeFor, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-motion/animation/concepts/discrete-properties/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, isCancelled

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/transition/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/transition/#property-queries) and
[Properties](https://phollyer.github.io/elm-motion/animation/properties/getting-started/) in the docs.


## Custom Properties

@docs getPropertyEnd


## Custom Color Properties

@docs getColorPropertyEnd


## Opacity

@docs getOpacityEnd


## Perspective Origin

@docs getPerspectiveOriginEnd


## Rotate

@docs getRotateEnd


## Scale

@docs getScaleEnd


## Size

@docs getSizeEnd


## Skew

@docs getSkewEnd


## Translate

@docs getTranslateEnd

-}

import Anim.Extra.Color exposing (Color)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS
import Anim.Internal.Engine.Transition as Internal
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup
import Anim.Unit exposing (Unit)
import Html
import Motion.Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Holds the Transition engine state.

Keep this in your model.

    type alias Model =
        { animState : Transition.AnimState }

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


{-| Builder type for Transition-only builders.

Use this in type annotations when a builder function should only work with this engine.

📖 See [Builder Modes](https://phollyer.github.io/elm-motion/animation/concepts/builder-modes/)
for patterns and examples.

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state with optional property initializers.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    -- Empty state
    Transition.init []

    -- With initial properties
    Transition.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

    import Anim.Engine.Transition as Transition

    { model
        | animState = Transition.animate model.animState entryAnim
    }

-}
animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    Internal.animate


{-| Update the target and move the element instantly to the new end values.

Use this when you want to move an animation to a new state without animating.

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

This can be different from `CurrentTargetId` when the event bubbled from a child element.

-}
type alias TargetId =
    Maybe String


{-| CSS transition lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


{-| Message type used with `update`.

    import Anim.Engine.Transition as Transition

    type Msg
        = TransitionMsg Transition.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle messages from this engine.

Returns the updated state and the event for this message.

    import Anim.Engine.Transition as Transition

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            TransitionMsg animMsg ->
                let
                    ( animState, event ) =
                        Transition.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = animState }

    handleAnimationEvent : Transition.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond toAnimEvent


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent event =
    case event of
        Internal.Started currentTargetId targetId animGroup ->
            Started currentTargetId targetId animGroup

        Internal.Ended currentTargetId targetId animGroup ->
            Ended currentTargetId targetId animGroup

        Internal.Cancelled currentTargetId targetId animGroup ->
            Cancelled currentTargetId targetId animGroup

        Internal.Run currentTargetId targetId animGroup ->
            Run currentTargetId targetId animGroup



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    div
        (Transition.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes


{-| Generate a `<style>` node containing `@starting-style` rules for all animated elements.

When an element enters the DOM (or changes from `display: none`), the browser needs
to know what values to animate FROM. Without `@starting-style`, the browser skips
the transition.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    view model =
        div []
            [ Transition.startingStyleNode model.animState
            , div (Transition.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNode : AnimState -> Html.Html msg
startingStyleNode =
    Internal.startingStyleNode


{-| Generate `@starting-style` rules for a specific animation group.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    view model =
        div []
            [ Transition.startingStyleNodeFor "fadeIn" model.animState
            , div (Transition.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
startingStyleNodeFor =
    Internal.startingStyleNodeFor



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


{-| Receive transition lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    type Msg
        = TransitionMsg Transition.AnimMsg

    div
        (Transition.attributes "animGroupName" animState
            ++ Transition.events "animGroupName" TransitionMsg
        )
        [ text "Animating element" ]

-}
events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events =
    Internal.events


{-| The same as [events](#events) but with propagation stopped.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    div
        (Transition.attributes "animGroupName" model.animState
            ++ Transition.eventsStopPropagation "animGroupName" TransitionMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Internal.eventsStopPropagation



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


{-| Set the default length unit used for width values in Transition animations.

    responsiveCardWidth : AnimBuilder eng -> AnimBuilder eng
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> EngineBuilder -> EngineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in Transition animations.

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

    import Anim.Engine.Transition as Transition

    Transition.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.Transition as Transition

    Transition.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

For entry animations, pair this with `startingStyleNode` so the browser knows
what values to transition from.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity

    Transition.animate model.animState <|
        Transition.discreteEntry "display" "block"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    CSS.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity

    Transition.animate model.animState <|
        Transition.discreteExit "display" "block" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.build

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    CSS.discreteExit



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


{-| Check if a specific animation group was cancelled.

Returns `Nothing` if there are no animations for the group.

-}
isCancelled : AnimGroupName -> AnimState -> Maybe Bool
isCancelled =
    CSS.isCancelled AnimGroup.isCancelled


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete AnimGroup.isComplete



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================
--
--
-- ============================
-- CUSTOM PROPERTY
-- ============================


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


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


{-| Get the end perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd =
    CSS.getPerspectiveOriginEnd



-- ============================
-- ROTATE
-- ============================


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd



-- ============================
-- SCALE
-- ============================


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd



-- ============================
-- SIZE
-- ============================


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd



-- ============================
-- SKEW
-- ============================


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd =
    CSS.getSkewEnd



-- ============================
-- TRANSLATE
-- ============================


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd
