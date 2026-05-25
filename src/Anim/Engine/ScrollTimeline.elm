module Anim.Engine.ScrollTimeline exposing
    ( TimelineBuilder, AnimGroupName
    , Container(..)
    , animate
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , horizontal
    , iterations, alternate
    , easing
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    , spring
    , discreteEntry, discreteExit
    , transformOrder
    )

{-| Use scroll position to drive animation progress.

Animations run automatically as the user scrolls, so you do not need an `AnimState`.
`update` and `subscriptions` are optional and only matter when you want events.

📖 For setup, browser support, and examples, see the
[ScrollTimeline Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/scroll-timeline/)
and the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/).


# Types

@docs TimelineBuilder, AnimGroupName


# Trigger

@docs Container

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) in the docs.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) in the docs.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/scroll-timeline/#subscriptions) in the docs.


# View

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) in the docs.


# Axis

@docs horizontal


# Playback

@docs iterations, alternate


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) in the docs.


# Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight


# Spring

@docs spring


# Discrete Properties

@docs discreteEntry, discreteExit


# Transform Order

@docs transformOrder

-}

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.ScrollTimeline as Internal
import Anim.Unit exposing (Unit)
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Builder type for scroll-driven animations.
-}
type alias TimelineBuilder =
    Internal.TimelineBuilder


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Identifies the scroll surface handled by the engine.

Use `Document` for the document body, or `Container "element-id"` for a
specific scrollable element.

-}
type Container
    = Document
    | Container String


{-| Fire-and-forget scroll-driven animation using the browser's `ScrollTimeline`.

    port motionCmd : Encode.Value -> Cmd msg

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
animate : (Encode.Value -> Cmd msg) -> Container -> (TimelineBuilder -> TimelineBuilder) -> Cmd msg
animate =
    Internal.animate containerToId


containerToId : Container -> String
containerToId container =
    case container of
        Document ->
            "document"

        Container elementId ->
            elementId



-- ============================================================
-- EVENTS
-- ============================================================


{-| Lifecycle events from the ScrollTimeline engine.

  - `Ended String` — the scroll position reached the end of the animation range
  - `Cancelled String` — the animation was cancelled (e.g. element removed)
  - `Iteration String Int` — the animation looped; the `Int` is the cumulative iteration count
  - `AnimError String` — a message arrived but could not be decoded

`Nothing` means the message was for something else.

-}
type AnimEvent
    = Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Iteration AnimGroupName Int
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


{-| Message type used with `update`.

    type Msg
        = GotScrollMsg ScrollTimeline.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Turn an engine message into an event.

Messages that do not belong to this engine return `Nothing`.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotScrollMsg animMsg ->
                case ScrollTimeline.update animMsg of
                    Just (ScrollTimeline.Ended animGroup) ->
                        ...

                    _ ->
                        ( model, Cmd.none )

-}
update : AnimMsg -> Maybe AnimEvent
update =
    Internal.update toAnimEvent


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent internalEvent =
    case internalEvent of
        Internal.Ended animGroup ->
            Ended animGroup

        Internal.Cancelled animGroup progress ->
            Cancelled animGroup progress

        Internal.Iteration animGroup iteration ->
            Iteration animGroup iteration

        Internal.AnimError errorMsg ->
            AnimError errorMsg



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to lifecycle events for this engine.

Wire this up alongside your `motionMsg` port.

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ScrollTimeline.subscriptions GotScrollMsg motionMsg

-}
subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Attach the animation group identifier to an element.

    div (ScrollTimeline.attributes "hero-card") [ ... ]

-}
attributes : AnimGroupName -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- AXIS
-- ============================================================


{-| Use horizontal scroll as the timeline source.

Vertical scroll is the default, so this is only needed when the
container scrolls horizontally.

    -- Animate based on horizontal scroll position in a carousel
    ScrollTimeline.animate motionCmd (Container "carousel") <|
        ScrollTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
horizontal : TimelineBuilder -> TimelineBuilder
horizontal =
    Internal.horizontal



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Alias of [Anim.Builder.iterations](Anim-Builder#iterations).
-}
iterations : Int -> TimelineBuilder -> TimelineBuilder
iterations =
    Builder.iterations


{-| Alias of [Anim.Builder.alternate](Anim-Builder#alternate).
-}
alternate : TimelineBuilder -> TimelineBuilder
alternate =
    Builder.alternate



-- ============================================================
-- EASING
-- ============================================================


{-| Alias of [Anim.Builder.easing](Anim-Builder#easing).
-}
easing : Easing -> TimelineBuilder -> TimelineBuilder
easing =
    Builder.easing



-- ============================================================
-- UNIT
-- ============================================================


{-| Alias of [Anim.Builder.cssUnit](Anim-Builder#cssUnit).
-}
cssUnit : Unit -> TimelineBuilder -> TimelineBuilder
cssUnit =
    Builder.cssUnit


{-| Alias of [Anim.Builder.cssUnitX](Anim-Builder#cssUnitX).
-}
cssUnitX : Unit -> TimelineBuilder -> TimelineBuilder
cssUnitX =
    Builder.cssUnitX


{-| Alias of [Anim.Builder.cssUnitY](Anim-Builder#cssUnitY).
-}
cssUnitY : Unit -> TimelineBuilder -> TimelineBuilder
cssUnitY =
    Builder.cssUnitY


{-| Alias of [Anim.Builder.cssUnitZ](Anim-Builder#cssUnitZ).
-}
cssUnitZ : Unit -> TimelineBuilder -> TimelineBuilder
cssUnitZ =
    Builder.cssUnitZ


{-| Set the default length unit used for width values in ScrollTimeline animations.

    responsiveCardWidth : TimelineBuilder -> TimelineBuilder
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> TimelineBuilder -> TimelineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in ScrollTimeline animations.

    responsivePanelHeight : TimelineBuilder -> TimelineBuilder
    responsivePanelHeight =
        cssUnitHeight Unit.Vh
            >> expandPanelHeight
            >> alignPanelHeaderY

-}
cssUnitHeight : Unit -> TimelineBuilder -> TimelineBuilder
cssUnitHeight =
    Builder.cssUnitHeight



-- ============================================================
-- SPRING
-- ============================================================


{-| Alias of [Anim.Builder.spring](Anim-Builder#spring).
-}
spring : Spring -> TimelineBuilder -> TimelineBuilder
spring =
    Builder.spring



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Override the order in which transform functions are applied.

By default, transforms are applied in the order: translate → rotate → skew → scale.
Use this when you need a different order for specific visual effects.

    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        ScrollTimeline.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "box"
            >> Translate.fromXY 0 0
            >> Translate.toXY 100 0
            >> Translate.build

-}
transformOrder : List TransformProperty -> TimelineBuilder -> TimelineBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Set a discrete CSS property to hold during the animation.

Used for non-interpolatable properties like `display` or `visibility` that need
to be set to a specific value while the animation is active.

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        ScrollTimeline.discreteEntry "display" "block"
            >> ScrollTimeline.discreteEntry "visibility" "visible"
            >> Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> TimelineBuilder -> TimelineBuilder
discreteEntry =
    Internal.discreteEntry


{-| Flip a discrete CSS property when the animation completes.

  - `from` — the value to hold during the animation

  - `to` — the value to apply when the animation finishes

    ScrollTimeline.animate motionCmd (Container "scroller") <|
    ScrollTimeline.discreteExit "display" "block" "none"

    > > Opacity.for "box"
    > > Opacity.from 1
    > > Opacity.to 0
    > > Opacity.build

-}
discreteExit : String -> String -> String -> TimelineBuilder -> TimelineBuilder
discreteExit =
    Internal.discreteExit
