module Anim.Builder exposing
    ( AnimBuilder
    , ForScrollTimeline, ForViewTimeline, ForDocumentTimeline
    , ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine
    , delay, duration, speed
    , iterations, alternate
    , easing, spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ
    )

{-| Builder types and functions for configuring animations.

The types here are the base building blocks for all animations.

The functions are shared configuration helpers.


# Types

📖 See [Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes)
in the docs for detailed examples and patterns.

@docs AnimBuilder


## Timeline Modes

Use these to restrict helpers to a particular timeline type.

@docs ForScrollTimeline, ForViewTimeline, ForDocumentTimeline


### Engine Modes

Use these with `ForDocumentTimeline` when you want to restrict helpers to a specific engine that uses the
browser's Document timeline: Transition, Keyframe, Sub, or WAAPI.

@docs ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine


# Document Timeline Functions

These functions are configured for Document Timeline engines (Keyframe, Sub, Transition, WAAPI).
They are not compatible with ScrollTimeline or ViewTimeline engines (they make no sense in those contexts).

@docs delay, duration, speed


# Universal Functions

Use the shared helpers below for portable global configuration. The engine
modules keep the same helpers as aliases.


## Playback

@docs iterations, alternate


## Motion Behaviour

@docs easing, spring


## Units

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ

-}

import Anim.Internal.Builder as Internal
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


{-| The base builder type for configuring animations.

The `mode` type parameter is a phantom type that controls where this builder can be used.
Leave it generic for maximum reuse:

    -- A generic builder that can be used with any engine or timeline
    f : AnimBuilder mode -> AnimBuilder mode

Or constrain it to a specific timeline:

    -- A builder that only works with document timeline Engines
    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)

Or constrain it to a specific engine.

    -- A builder that only works with the Sub Engine on the document timeline
    f : AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)

Constrained modes make function intent visible from the type signature, can help narrow
which helpers are relevant during debugging, and trigger compiler errors for invalid usage.

**Note**: For shorter type signatures, the engine modules expose shorthand aliases targeted to
their specific engine and timeline combinations.

-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| Document timeline builder mode, supports Keyframe, Sub, Transition, and WAAPI engines.

Leave the `engine` type parameter generic to allow use with any of these engines,
or constrain it to a specific engine.

Here's a generic Document timeline builder that works with any engine that uses the Document timeline,
but will result in a type error if used with ScrollTimeline or ViewTimeline engines.

    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)

Here's an engine-specific Document timeline builder for the Sub Engine.
It will result in a type error if used with any other engine.

    f : AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)

-}
type alias ForDocumentTimeline engine =
    Internal.ForDocumentTimeline engine


{-| Keyframe Engine builder mode.
-}
type alias ForKeyframeEngine =
    Internal.ForKeyframeEngine


{-| Sub Engine builder mode.
-}
type alias ForSubEngine =
    Internal.ForSubEngine


{-| Transition Engine builder mode.
-}
type alias ForTransitionEngine =
    Internal.ForTransitionEngine


{-| WAAPI Engine builder mode.
-}
type alias ForWAAPIEngine =
    Internal.ForWAAPIEngine


{-| ScrollTimeline Engine builder mode.
-}
type alias ForScrollTimeline =
    Internal.ForScrollTimeline


{-| ViewTimeline Engine builder mode.
-}
type alias ForViewTimeline =
    Internal.ForViewTimeline


{-| Set the global delay for all animations in a document-timeline builder.

    introAnim : AnimBuilder mode -> AnimBuilder (ForDocumentTimeline engine)
    introAnim =
        delay 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
delay : Int -> AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)
delay =
    Internal.delay


{-| Set the global duration for all animations in a document-timeline builder.

    introAnim : AnimBuilder mode -> AnimBuilder (ForDocumentTimeline engine)
    introAnim =
        duration 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
duration : Int -> AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)
duration =
    Internal.duration


{-| Set the global speed for all animations in a document-timeline builder.

    introAnim : AnimBuilder mode -> AnimBuilder (ForDocumentTimeline engine)
    introAnim =
        speed 300
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
speed : Float -> AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)
speed =
    Internal.speed


{-| Set how many times an animation should repeat.

    notificationAttentionLoop : AnimBuilder mode -> AnimBuilder mode
    notificationAttentionLoop =
        iterations 3
            >> pulseBadge
            >> nudgeBellIcon

-}
iterations : Int -> AnimBuilder mode -> AnimBuilder mode
iterations =
    Internal.iterations


{-| Make an animation alternate direction on each iteration.

    floatingCardLoop : AnimBuilder mode -> AnimBuilder mode
    floatingCardLoop =
        iterations 4
            >> alternate
            >> liftCard
            >> glowCardBorder

-}
alternate : AnimBuilder mode -> AnimBuilder mode
alternate =
    Internal.alternate


{-| Set the global easing function.

    heroEntrance : AnimBuilder mode -> AnimBuilder mode
    heroEntrance =
        easing EaseInOut
            >> fadeInHeroTitle
            >> slideInHeroArtwork
            >> revealPrimaryCta

-}
easing : Easing -> AnimBuilder mode -> AnimBuilder mode
easing =
    Internal.easing


{-| Set the global spring.

    draggableCardSettle : AnimBuilder mode -> AnimBuilder mode
    draggableCardSettle =
        spring Spring.wobbly
            >> settleCardPosition
            >> settleCardShadow

-}
spring : Spring -> AnimBuilder mode -> AnimBuilder mode
spring =
    Internal.spring


{-| Set the default length unit for all length-bearing properties.

    responsivePanelMotion : AnimBuilder mode -> AnimBuilder mode
    responsivePanelMotion =
        cssUnit Unit.Vw
            >> slidePanelIn
            >> growPanelHeight

-}
cssUnit : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnit =
    Internal.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : AnimBuilder mode -> AnimBuilder mode
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slideDrawerX
            >> alignDrawerLabelX

-}
cssUnitX : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitX =
    Internal.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : AnimBuilder mode -> AnimBuilder mode
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slideSheetY
            >> alignSheetHeaderY

-}
cssUnitY : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitY =
    Internal.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : AnimBuilder mode -> AnimBuilder mode
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> pushSceneBackgroundBack
            >> bringFloatingCardForward

-}
cssUnitZ : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitZ =
    Internal.cssUnitZ
