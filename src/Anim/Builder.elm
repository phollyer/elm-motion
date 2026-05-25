module Anim.Builder exposing
    ( AnimBuilder
    , ForScrollTimeline, ForViewTimeline, ForDocumentTimeline
    , ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine
    , delay, duration, speed
    , iterations, alternate
    , easing, spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    )

{-| Shared builder types and settings for animations.

Most app code will use the engine and property modules directly.
This module is mainly for shared type annotations and global builder settings.


# Types

📖 See [Builder Modes](https://phollyer.github.io/elm-motion/animation/concepts/builder-modes/)
in the docs for detailed examples and patterns.

@docs AnimBuilder


## Timeline Modes

Use these in type annotations when a helper should only work on a certain timeline.

@docs ForScrollTimeline, ForViewTimeline, ForDocumentTimeline


### Engine Modes

Use these with `ForDocumentTimeline` when a helper should only work with one document-timeline engine.

@docs ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine


# Document Timeline Functions

These settings are for document-timeline engines: Keyframe, Sub, Transition, and WAAPI.
The engine modules re-export the same functions.

@docs delay, duration, speed


# Universal Functions

Use the shared builder functions below for settings that work across engines.
The engine modules re-export the same functions.


## Playback

@docs iterations, alternate


## Motion Behaviour

@docs easing, spring


## Units

Set the CSS unit for built-in properties that use length values.

This is useful when you want those properties to render in units like `px`, `rem`, or container units.

📖 See the property docs and [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for details.

@docs cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight

-}

import Anim.Internal.Builder as Internal
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


{-| Base builder type for animations.

    f : AnimBuilder mode -> AnimBuilder mode

-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| Builder mode for ScrollTimeline helpers.

    f : AnimBuilder ForScrollTimeline -> AnimBuilder ForScrollTimeline

-}
type alias ForScrollTimeline =
    Internal.ForScrollTimeline


{-| Builder mode for ViewTimeline helpers.

    f : AnimBuilder ForViewTimeline -> AnimBuilder ForViewTimeline

-}
type alias ForViewTimeline =
    Internal.ForViewTimeline


{-| Builder mode for document-timeline helpers.

    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)

-}
type alias ForDocumentTimeline engine =
    Internal.ForDocumentTimeline engine


{-| Builder mode for Keyframe helpers.

    f : AnimBuilder (ForDocumentTimeline ForKeyframeEngine) -> AnimBuilder (ForDocumentTimeline ForKeyframeEngine)

-}
type alias ForKeyframeEngine =
    Internal.ForKeyframeEngine


{-| Builder mode for Sub helpers.

    f : AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)

-}
type alias ForSubEngine =
    Internal.ForSubEngine


{-| Builder mode for Transition helpers.

    f : AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)

-}
type alias ForTransitionEngine =
    Internal.ForTransitionEngine


{-| Builder mode for WAAPI helpers.

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
