module Anim.Engine.ViewTimeline exposing
    ( TimelineBuilder, AnimGroupName
    , animate
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , horizontal
    , Unit(..), Range(..), rangeStart, rangeEnd
    , iterations, alternate
    , easing
    , spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    , discreteEntry, discreteExit
    , transformOrder
    , withProgressEvents
    )

{-| Use an element's position in the viewport to drive animation progress.

Animations run automatically as the element moves through view, so you do not need an `AnimState`.
`update` and `subscriptions` are optional and only matter when you want events.

📖 For setup, browser support, and examples, see the
[ViewTimeline Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/view-timeline/)
and the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/).


# Types

@docs TimelineBuilder, AnimGroupName


# Trigger

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) for details.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) for details.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) for details.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/view-timeline/#subscriptions) for details.


# View

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) for details.


# Axis

@docs horizontal


# Range

@docs Unit, Range, rangeStart, rangeEnd


# Playback

@docs iterations, alternate


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) for details.


# Spring

@docs spring


# Length Unit

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight


# Discrete Properties

@docs discreteEntry, discreteExit


# Transform Order

@docs transformOrder


# Progress Events

@docs withProgressEvents

-}

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.ViewTimeline as Internal
import Anim.Unit as LengthUnit
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Builder type for view-driven animations.

Use this in type annotations when a builder function should only work with ViewTimeline.

📖 See [Engine Capabilities](https://phollyer.github.io/elm-motion/animation/concepts/engine-capabilities/)
for patterns and examples.

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


{-| Fire-and-forget view-driven animation using the browser's `ViewTimeline`.

    port motionCmd : Encode.Value -> Cmd msg

    ViewTimeline.animate motionCmd <|
        Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
animate : (Encode.Value -> Cmd msg) -> (TimelineBuilder -> TimelineBuilder) -> Cmd msg
animate =
    Internal.animate



-- ============================================================
-- EVENTS
-- ============================================================


{-| Lifecycle events from the ViewTimeline engine.

  - `Started String` — the element entered the animation range. Fires every
    time the element re-enters range, not just on the first entry.
  - `Ended String` — the element scrolled past the end of the animation range
  - `Cancelled String` — the animation was cancelled (e.g. element removed)
  - `Iteration String Int` — the animation looped; the `Int` is the cumulative iteration count
  - `Progress String Float` — the timeline's current progress (0..1) while in range.
    Only emitted when [`withProgressEvents`](#withProgressEvents) `True` was set on the builder.
  - `AnimError String` — a message arrived but could not be decoded

-}
type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


{-| Message type used with `update`.

    type Msg
        = GotViewMsg ViewTimeline.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Turn an engine message into an event.

Messages that do not belong to this engine return `Nothing`.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotViewMsg animMsg ->
                case ViewTimeline.update animMsg of
                    Just (ViewTimeline.Ended animGroup) ->
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

Wire this up alongside your `motionMsg` port.

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg motionMsg

-}
subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Attach the animation group identifier to an element.

    div (ViewTimeline.attributes "hero-card") [ ... ]

-}
attributes : AnimGroupName -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- AXIS
-- ============================================================


{-| Use horizontal viewport tracking for the timeline.

Vertical scroll is the default, so this is only needed when the
container scrolls horizontally.

    -- Animate an element entering from the side in a horizontal layout
    ViewTimeline.animate motionCmd <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
horizontal : TimelineBuilder -> TimelineBuilder
horizontal =
    Internal.horizontal



-- ============================================================
-- RANGE
-- ============================================================


{-| The unit for a `Range` offset value.

  - `Perc` — percentage of the named range (`Cover 20 Perc` → `cover 20%`)
  - `Px` — fixed pixel offset (`Cover 100 Px` → `cover 100px`)

-}
type Unit
    = Perc
    | Px


{-| A position along the view timeline, used to configure `rangeStart` and `rangeEnd`.

Each constructor takes a numeric value and a `Unit`:

    rangeStart (Entry 0 Perc) -- entry 0%

    rangeEnd (Exit 100 Px) -- exit 100px

See the [Range section](https://phollyer.github.io/elm-motion/animation/engines/view-timeline/#range)
for details.

-}
type Range
    = Cover Float Unit
    | Contain Float Unit
    | Entry Float Unit
    | EntryCrossing Float Unit
    | Exit Float Unit
    | ExitCrossing Float Unit
    | Scroll Float Unit


{-| Set when the animation starts relative to the element's position in the viewport.

Optional — defaults to `Cover 0 Perc` when not called.

    -- Start animating as the element enters the viewport
    ViewTimeline.rangeStart (Entry 0 Perc)

    -- Start animating once the element is fully visible
    ViewTimeline.rangeStart (Entry 100 Perc)

-}
rangeStart : Range -> TimelineBuilder -> TimelineBuilder
rangeStart range =
    Internal.rangeStart (rangeToString range)


{-| Set when the animation ends relative to the element's position in the viewport.

Optional — defaults to `Cover 100 Perc` when not called.

    -- End animating as the element begins to leave the viewport
    ViewTimeline.rangeEnd (Exit 0 Perc)

    -- End animating once the element has fully left the viewport
    ViewTimeline.rangeEnd (Exit 100 Perc)

-}
rangeEnd : Range -> TimelineBuilder -> TimelineBuilder
rangeEnd range =
    Internal.rangeEnd (rangeToString range)


rangeToString : Range -> String
rangeToString range =
    case range of
        Cover n u ->
            "cover " ++ String.fromFloat n ++ unitToString u

        Contain n u ->
            "contain " ++ String.fromFloat n ++ unitToString u

        Entry n u ->
            "entry " ++ String.fromFloat n ++ unitToString u

        EntryCrossing n u ->
            "entry-crossing " ++ String.fromFloat n ++ unitToString u

        Exit n u ->
            "exit " ++ String.fromFloat n ++ unitToString u

        ExitCrossing n u ->
            "exit-crossing " ++ String.fromFloat n ++ unitToString u

        Scroll n u ->
            "scroll " ++ String.fromFloat n ++ unitToString u


unitToString : Unit -> String
unitToString unit =
    case unit of
        Perc ->
            "%"

        Px ->
            "px"



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times an animation should repeat.

    notificationAttentionLoop : AnimBuilder eng -> AnimBuilder eng
    notificationAttentionLoop =
        iterations 3
            >> pulseBadge
            >> nudgeBellIcon

-}
iterations : Int -> TimelineBuilder -> TimelineBuilder
iterations =
    Builder.iterations


{-| Make an animation alternate direction on each iteration.

    floatingCardLoop : AnimBuilder eng -> AnimBuilder eng
    floatingCardLoop =
        iterations 4
            >> alternate
            >> liftCard
            >> glowCardBorder

`alternate` only has a visible effect when the animation runs more than once,
so calling it when `iterations` is unset or `1` automatically bumps
`iterations` to `2`. An explicit `iterations` count (or `loopForever`) set
before or after `alternate` is preserved.

-}
alternate : TimelineBuilder -> TimelineBuilder
alternate =
    Builder.alternate



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
easing : Easing -> TimelineBuilder -> TimelineBuilder
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
spring : Spring -> TimelineBuilder -> TimelineBuilder
spring =
    Builder.spring



-- ============================================================
-- LENGTH UNIT
-- ============================================================


{-| Set the default length unit for all length-bearing properties.

    responsivePanelMotion : AnimBuilder eng -> AnimBuilder eng
    responsivePanelMotion =
        cssUnit Unit.Vw
            >> slidePanelIn
            >> growPanelHeight

-}
cssUnit : LengthUnit.Unit -> TimelineBuilder -> TimelineBuilder
cssUnit =
    Builder.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slideDrawerX
            >> alignDrawerLabelX

-}
cssUnitX : LengthUnit.Unit -> TimelineBuilder -> TimelineBuilder
cssUnitX =
    Builder.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slideSheetY
            >> alignSheetHeaderY

-}
cssUnitY : LengthUnit.Unit -> TimelineBuilder -> TimelineBuilder
cssUnitY =
    Builder.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : AnimBuilder eng -> AnimBuilder eng
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> pushSceneBackgroundBack
            >> bringFloatingCardForward

-}
cssUnitZ : LengthUnit.Unit -> TimelineBuilder -> TimelineBuilder
cssUnitZ =
    Builder.cssUnitZ


{-| Set the default length unit used for width values in ViewTimeline animations.

    responsiveCardWidth : TimelineBuilder -> TimelineBuilder
    responsiveCardWidth =
        cssUnitWidth LengthUnit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : LengthUnit.Unit -> TimelineBuilder -> TimelineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in ViewTimeline animations.

    responsivePanelHeight : TimelineBuilder -> TimelineBuilder
    responsivePanelHeight =
        cssUnitHeight LengthUnit.Vh
            >> expandPanelHeight
            >> alignPanelHeaderY

-}
cssUnitHeight : LengthUnit.Unit -> TimelineBuilder -> TimelineBuilder
cssUnitHeight =
    Builder.cssUnitHeight



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Override the order in which transform functions are applied.

By default, transforms are applied in the order: translate → rotate → skew → scale.
Use this when you need a different order for specific visual effects.

    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ViewTimeline.animate motionCmd <|
        ViewTimeline.transformOrder [ Scale, Rotate, Translate ]
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

    ViewTimeline.animate motionCmd <|
        ViewTimeline.discreteEntry "display" "block"
            >> ViewTimeline.discreteEntry "visibility" "visible"
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

    ViewTimeline.animate motionCmd <|
    ViewTimeline.discreteExit "display" "block" "none"

    > > Opacity.for "box"
    > > Opacity.from 1
    > > Opacity.to 0
    > > Opacity.build

-}
discreteExit : String -> String -> String -> TimelineBuilder -> TimelineBuilder
discreteExit =
    Internal.discreteExit



-- ============================================================
-- PROGRESS EVENTS
-- ============================================================


{-| Opt in to per-frame `Progress` events while the element is in range.

Off by default — view-driven animations render entirely on the GPU and do not
need progress messages to draw. Turn this on when you want to react to the
element's position in the viewport from Elm (for example, to trigger another
animation, mark a milestone, or update a progress badge).

    ViewTimeline.animate motionCmd <|
        ViewTimeline.withProgressEvents True
            >> Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

While enabled, the engine emits one `Progress animGroup t` event per animation
frame (typically ~60/sec) for every group that is currently in range.

-}
withProgressEvents : Bool -> TimelineBuilder -> TimelineBuilder
withProgressEvents =
    Internal.withProgressEvents
