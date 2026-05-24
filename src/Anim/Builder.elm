module Anim.Builder exposing
    ( AnimBuilder
    , ForScrollTimeline, ForViewTimeline, ForDocumentTimeline
    , ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine
    , delay, duration, speed
    , iterations, alternate
    , easing, spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    )

{-| Builder types and functions for configuring animations.

The types here are the base building blocks for all animations, and the
functions are shared configuration builder functions.

Use the Engine and Property modules to build animations, the types here to
define your builders and the functions here to configure them where needed.


# Types

📖 See [Builder Modes](https://phollyer.github.io/elm-motion/animation/concepts/builder-modes/)
in the docs for detailed examples and patterns.

@docs AnimBuilder


## Timeline Modes

Use these to restrict builder functions to engines that use a particular timeline.

@docs ForScrollTimeline, ForViewTimeline, ForDocumentTimeline


### Engine Modes

Use these with `ForDocumentTimeline` when you want to restrict builder functions to a specific engine that uses the
browser's Document timeline: Transition, Keyframe, Sub, or WAAPI.

@docs ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine


# Document Timeline Functions

These functions are configured for Document Timeline engines (Keyframe, Sub, Transition, WAAPI).
They are not compatible with ScrollTimeline or ViewTimeline engines (they make no sense in those contexts).
If you try to use them in a ScrollTimeline or ViewTimeline builder, you'll get a type error.

The engine modules re-export these same builder functions.

@docs delay, duration, speed


# Universal Functions

Use the shared builder functions below for portable global configuration. The engine
modules re-export these same builder functions.


## Playback

@docs iterations, alternate


## Motion Behaviour

@docs easing, spring


## Units

Set the CSS unit for all multi-dimensional properties that use length values.

Currently, these functions affect `Translate`, `Size`, and `PerspectiveOrigin`, and are used to define
the CSS unit used for rendering the values of those properties. Useful for responsive designs where you
want to use container-relative units like `cqmin` or `cqw`.

Custom properties that use length values declare which unit they use in their config, and will not be affected by these functions.

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight

-}

import Anim.Internal.Builder as Internal
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


{-| The base builder type for configuring animations that can be consumed
by any animation engine.

    f : AnimBuilder mode -> AnimBuilder mode

-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| ScrollTimeline Engine builder mode.

Builders defined with this `mode` are only compatible with the ScrollTimeline Engine,
and will produce a type error if used with any other engine.

    f : AnimBuilder ForScrollTimeline -> AnimBuilder ForScrollTimeline

-}
type alias ForScrollTimeline =
    Internal.ForScrollTimeline


{-| ViewTimeline Engine builder mode.

Builders defined with this `mode` are only compatible with the ViewTimeline Engine,
and will produce a type error if used with any other engine.

    f : AnimBuilder ForViewTimeline -> AnimBuilder ForViewTimeline

-}
type alias ForViewTimeline =
    Internal.ForViewTimeline


{-| Document timeline builder mode.

Builders defined with this `mode` are compatible with any engine that uses the browser's Document timeline:
Keyframe, Sub, Transition, and WAAPI.

    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)

-}
type alias ForDocumentTimeline engine =
    Internal.ForDocumentTimeline engine


{-| Keyframe Engine builder mode.

    f : AnimBuilder (ForDocumentTimeline ForKeyframeEngine) -> AnimBuilder (ForDocumentTimeline ForKeyframeEngine)

-}
type alias ForKeyframeEngine =
    Internal.ForKeyframeEngine


{-| Sub Engine builder mode.

    f : AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)

-}
type alias ForSubEngine =
    Internal.ForSubEngine


{-| Transition Engine builder mode.

    f : AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)

-}
type alias ForTransitionEngine =
    Internal.ForTransitionEngine


{-| WAAPI Engine builder mode.

    f : AnimBuilder (ForDocumentTimeline ForWAAPIEngine) -> AnimBuilder (ForDocumentTimeline ForWAAPIEngine)

-}
type alias ForWAAPIEngine =
    Internal.ForWAAPIEngine


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
            >> slideDownHeader
            >> slideInSidebar
            >> slideUpContent

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


{-| Set the default length unit used for width values.

    responsiveCardWidth : AnimBuilder mode -> AnimBuilder mode
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitWidth =
    Internal.cssUnitWidth


{-| Set the default length unit used for height values.

    responsivePanelHeight : AnimBuilder mode -> AnimBuilder mode
    responsivePanelHeight =
        cssUnitHeight Unit.Vh
            >> expandPanelHeight
            >> alignPanelHeaderY

-}
cssUnitHeight : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitHeight =
    Internal.cssUnitHeight
