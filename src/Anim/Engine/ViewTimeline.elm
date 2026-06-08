module Anim.Engine.ViewTimeline exposing
    ( EngineBuilder, AnimGroupName
    , for
    , animate
    , AnimEvent(..)
    , withProgressEvents
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
    )

{-| Use an element's position in the viewport to drive animation progress.

Animations run automatically as the element moves through view, so you do not need an `AnimState`.
`update` and `subscriptions` are optional and only matter when you want events.

📖 For setup, browser support, and examples, see the
[ViewTimeline Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/view-timeline/)
and the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/).


# Types

@docs EngineBuilder, AnimGroupName


# Target

@docs for


# Trigger

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) for details.

@docs animate


# Events

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) for details.

@docs AnimEvent


## Progress Events

@docs withProgressEvents


# Update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) for details.

@docs AnimMsg, update


# Subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/view-timeline/#subscriptions) for details.

@docs subscriptions


# View

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) for details.

@docs attributes


# Axis

@docs horizontal


# Range

📖 See [Range](https://phollyer.github.io/elm-motion/animation/engines/view-timeline/#range)
for details.

@docs Unit, Range, rangeStart, rangeEnd


# Playback

These functions are precedence functions, so they can operate as a global setting for all groups in the
builder chain, or you can set them on a per-group basis which overrides any global setting
for that group.

    ViewTimeline.iterations 3 -- global setting
        >> ViewTimeline.for "box"
        >> ViewTimeline.iterations 5 -- overrides global for this group
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
type alias EngineBuilder =
    Internal.EngineBuilder


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Select the animation group that subsequent property builders will target.

    ViewTimeline.for "hero-card"
        >> Opacity.begin
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.end

-}
for : AnimGroupName -> EngineBuilder -> EngineBuilder
for =
    Builder.for


{-| Fire-and-forget view-driven animation using the browser's `ViewTimeline`.

    port motionCmd : Encode.Value -> Cmd msg

    ViewTimeline.animate motionCmd <|
        ViewTimeline.for "hero-card"
            >> Opacity.begin
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.end

-}
animate : (Encode.Value -> Cmd msg) -> (EngineBuilder -> EngineBuilder) -> Cmd msg
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

    ViewTimeline.withProgressEvents True -- global setting
        >> ViewTimeline.for "box"
        >> ViewTimeline.withProgressEvents False -- overrides global for this group
        >> ... -- other builders

-}
withProgressEvents : Bool -> EngineBuilder -> EngineBuilder
withProgressEvents =
    Internal.withProgressEvents



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

This is only required if you want to receive events.

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
            >> ViewTimeline.for "slide"
            >> Opacity.begin
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.end

-}
horizontal : EngineBuilder -> EngineBuilder
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

This is a precedence function, so it can act as a global default for the
whole builder chain or be set after `for` to override the range for a
specific group.

    -- Start animating as the element enters the viewport
    ViewTimeline.rangeStart (Entry 0 Perc)
        >> ViewTimeline.for "section-a"
        -- Give one section its own range inside the same pipeline
        >> ViewTimeline.rangeStart (Entry 10 Perc)

-}
rangeStart : Range -> EngineBuilder -> EngineBuilder
rangeStart range =
    Internal.rangeStart (rangeToString range)


{-| Set when the animation ends relative to the element's position in the viewport.

Optional — defaults to `Cover 100 Perc` when not called.

This is a precedence function, so it can act as a global default for the
whole builder chain or be set after `for` to override the range for a
specific group.

    -- End animating as the element begins to leave the viewport
    ViewTimeline.rangeEnd (Exit 0 Perc)
        >> ViewTimeline.for "section-a"
        -- Give one section its own range inside the same pipeline
        >> ViewTimeline.rangeEnd (Exit 60 Perc)

-}
rangeEnd : Range -> EngineBuilder -> EngineBuilder
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
-- LENGTH UNIT
-- ============================================================


{-| Set the default length unit for all length-bearing properties.

    responsivePanelMotion : AnimBuilder eng -> AnimBuilder eng
    responsivePanelMotion =
        cssUnit Unit.Vw
            >> slidePanelIn
            >> growPanelHeight

-}
cssUnit : LengthUnit.Unit -> EngineBuilder -> EngineBuilder
cssUnit =
    Builder.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slideDrawerX
            >> alignDrawerLabelX

-}
cssUnitX : LengthUnit.Unit -> EngineBuilder -> EngineBuilder
cssUnitX =
    Builder.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : AnimBuilder eng -> AnimBuilder eng
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slideSheetY
            >> alignSheetHeaderY

-}
cssUnitY : LengthUnit.Unit -> EngineBuilder -> EngineBuilder
cssUnitY =
    Builder.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : AnimBuilder eng -> AnimBuilder eng
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> pushSceneBackgroundBack
            >> bringFloatingCardForward

-}
cssUnitZ : LengthUnit.Unit -> EngineBuilder -> EngineBuilder
cssUnitZ =
    Builder.cssUnitZ


{-| Set the default length unit used for width values in ViewTimeline animations.

    responsiveCardWidth : EngineBuilder -> EngineBuilder
    responsiveCardWidth =
        cssUnitWidth LengthUnit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : LengthUnit.Unit -> EngineBuilder -> EngineBuilder
cssUnitWidth =
    Builder.cssUnitWidth


{-| Set the default length unit used for height values in ViewTimeline animations.

    responsivePanelHeight : EngineBuilder -> EngineBuilder
    responsivePanelHeight =
        cssUnitHeight LengthUnit.Vh
            >> expandPanelHeight
            >> alignPanelHeaderY

-}
cssUnitHeight : LengthUnit.Unit -> EngineBuilder -> EngineBuilder
cssUnitHeight =
    Builder.cssUnitHeight



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

    ViewTimeline.animate motionCmd <|
        ViewTimeline.transformOrder [ Scale, Rotate, Translate, Skew ] -- global setting
            >> ViewTimeline.for "box"
            >> ViewTimeline.transformOrder [ Rotate, Translate ] -- overrides global for this group
            >> Translate.begin
            >> Translate.fromXY 0 0
            >> Translate.toXY 100 0
            >> Translate.end

-}
transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
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
            >> ViewTimeline.for "box"
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

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.ViewTimeline as ViewTimeline
    import Anim.Property.Opacity as Opacity

    ViewTimeline.animate motionCmd <|
        ViewTimeline.discreteExit "display" "block" "none"
            >> ViewTimeline.for "box"
            >> Opacity.begin
            >> Opacity.to 0
            >> Opacity.end

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    Internal.discreteExit
