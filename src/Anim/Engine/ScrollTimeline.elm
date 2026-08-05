module Anim.Engine.ScrollTimeline exposing
    ( EngineBuilder, AnimGroupName
    , for
    , Container(..)
    , animate
    , AnimEvent(..)
    , withProgressEvents, setUpdateThrottle
    , AnimMsg, update
    , subscriptions
    , attributes
    , horizontal
    , iterations, alternate
    , easing
    , spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
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

@docs EngineBuilder, AnimGroupName


# Target

@docs for


# Trigger

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) for details.

@docs Container

@docs animate


# Events

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) for details.

@docs AnimEvent


## Progress Events

@docs withProgressEvents, setUpdateThrottle


# Update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) for details.

@docs AnimMsg, update


# Subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/scroll-timeline/#subscriptions) for details.

@docs subscriptions


# View

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) for details.

@docs attributes


# Axis

@docs horizontal


# Playback

These functions are precedence functions, so they can operate as a global setting for all groups in the
builder chain, or you can set them on a per-group basis which overrides any global setting
for that group.

    ScrollTimeline.iterations 3 -- global setting
        >> ScrollTimeline.for "box"
        >> ScrollTimeline.iterations 5 -- overrides global for this group
        >> ... -- other builders

@docs iterations, alternate


# Easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) for details.

@docs easing


# Spring

@docs spring


# Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight


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
type alias EngineBuilder =
    Internal.EngineBuilder


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


{-| Select the animation group that subsequent property builders will target.

    ScrollTimeline.for "hero-card"
        >> Opacity.begin
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.end

-}
for : AnimGroupName -> EngineBuilder -> EngineBuilder
for =
    Builder.for


{-| Fire-and-forget scroll-driven animation using the browser's `ScrollTimeline`.

    port motionCmd : Encode.Value -> Cmd msg

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        ScrollTimeline.for "hero-card"
            >> Opacity.begin
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.end

-}
animate : (Encode.Value -> Cmd msg) -> Container -> (EngineBuilder -> EngineBuilder) -> Cmd msg
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

  - `Started String` — the scroll position entered the animation range. Fires every
    time the timeline re-enters range, not just on the first entry.
  - `Ended String` — the scroll position reached the end of the animation range
  - `Cancelled String` — the animation was cancelled (e.g. element removed)
  - `Iteration String Int` — the animation looped; the `Int` is the cumulative iteration count
  - `Progress String Float` — the timeline's current progress (0..1) while in range.
    Only emitted when [`withProgressEvents`](#withProgressEvents) `True` was set on the builder.
  - `AnimError String` — a message arrived but could not be decoded

-}
type AnimEvent
    = Run AnimGroupName
    | Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
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

    ScrollTimeline.withProgressEvents True -- global setting
        >> ScrollTimeline.for "box"
        >> ScrollTimeline.withProgressEvents False -- overrides global for this group
        >> ... -- other builders

-}
withProgressEvents : Bool -> EngineBuilder -> EngineBuilder
withProgressEvents =
    Internal.withProgressEvents


{-| Set the minimum interval in milliseconds between per-frame
`propertyUpdate` emissions from the JavaScript runtime.

The visual animation is driven by the browser compositor and is **never**
affected by this setting - it only controls how much port traffic is generated.

This is a precedence function, so it can operate as a global setting for all
groups in the builder chain, or you can set it on a per-group basis which
overrides any global setting for that group.

  - Pass `0` (the default) to emit on every `requestAnimationFrame` tick.
  - Pass a positive number of milliseconds to cap the emission rate, e.g.
    `16` for ~60 Hz, `33` for ~30 Hz.

**Note**: Higher throttle values reduce Elm-side mid-flight precision for
queries and interruption bookkeeping.

    ScrollTimeline.setUpdateThrottle 33 -- global default
        >> ScrollTimeline.for "hero"
        >> ScrollTimeline.setUpdateThrottle 0 -- dense updates for interactions
        >> ScrollTimeline.for "background"
        >> ScrollTimeline.setUpdateThrottle 50 -- lower traffic for passive motion
        >> ... -- other builders

-}
setUpdateThrottle : Int -> EngineBuilder -> EngineBuilder
setUpdateThrottle =
    Builder.setUpdateThrottle



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
        Internal.Run animGroup ->
            Run animGroup

        Internal.Started animGroup ->
            Started animGroup

        Internal.Ended animGroup ->
            Ended animGroup

        Internal.Cancelled animGroup progress ->
            Cancelled animGroup progress

        Internal.Iteration animGroup iteration ->
            Iteration animGroup iteration

        Internal.Progress animGroup progress ->
            Progress animGroup progress

        Internal.AnimError errorMsg ->
            AnimError errorMsg



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to lifecycle events for this engine.

This is only required if you want to receive events.

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
            >> ScrollTimeline.for "slide"
            >> Opacity.begin
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.end

-}
horizontal : EngineBuilder -> EngineBuilder
horizontal =
    Internal.horizontal



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times an animation should repeat.
-}
iterations : Int -> EngineBuilder -> EngineBuilder
iterations =
    Builder.iterations


{-| Make an animation alternate direction on each iteration.

`alternate` only has a visible effect when the animation runs more than once,
so calling it when `iterations` is unset or `1` automatically bumps
`iterations` to `2`. An explicit `iterations` count set before or after
`alternate` is preserved.

-}
alternate : EngineBuilder -> EngineBuilder
alternate =
    Builder.alternate



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


{-| Set the default length unit used for width values in ScrollTimeline animations.

    responsiveCardWidth : EngineBuilder -> EngineBuilder
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> EngineBuilder -> EngineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in ScrollTimeline animations.

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
-- DISCRETE PROPERTIES
-- ============================================================


{-| Set a discrete CSS property to hold during the animation.

Used for non-interpolatable properties like `display` or `visibility` that need
to be set to a specific value while the animation is active.

This function is a precedence function, so it can operate as a global setting
for all groups in the builder chain, or you can set it on a per-group basis
which overrides any global setting for that group.

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        ScrollTimeline.discreteEntry "display" "block"
            >> ScrollTimeline.discreteEntry "visibility" "visible"
            >> ScrollTimeline.for "box"
            >> Opacity.begin
            >> Opacity.from 0
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

    import Anim.Engine.ScrollTimeline as ScrollTimeline
    import Anim.Property.Opacity as Opacity

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        ScrollTimeline.discreteExit "display" "block" "none"
            >> ScrollTimeline.for "box"
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

    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ScrollTimeline.animate motionCmd (Container "scroller") <|
        ScrollTimeline.transformOrder [ Scale, Rotate, Translate, Skew ] -- global setting
            >> ScrollTimeline.for "box"
            >> ScrollTimeline.transformOrder [ Rotate, Translate ] -- overrides global for this group
            >> Translate.begin
            >> Translate.fromXY 0 0
            >> Translate.toXY 100 0
            >> Translate.end

-}
transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Internal.transformOrder
