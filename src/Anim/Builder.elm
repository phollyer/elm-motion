module Anim.Builder exposing
    ( AnimBuilder
    , ForScroll, ForView
    , ForKeyframe, ForSub, ForTransition, ForWAAPI
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

Use these in type annotations when a builder function should only work on a certain timeline.

@docs ForScroll, ForView


### Engine Modes

Use these to constrain a builder function to one specific Engine.

@docs ForKeyframe, ForSub, ForTransition, ForWAAPI


# Document Timeline Functions

These settings are for Document timeline engines: Keyframe, Sub, Transition, and WAAPI.
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



-- ============================================================
-- TYPES
-- ============================================================


{-| Base builder type for animations.

    f : AnimBuilder mode -> AnimBuilder mode

-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode



-- ============================================================
-- TIMELINE MODES
-- ============================================================


{-| Builder mode for ScrollTimeline builders.

    f : AnimBuilder ForScroll -> AnimBuilder ForScroll

-}
type alias ForScroll =
    Internal.ForScroll


{-| Builder mode for ViewTimeline builders.

    f : AnimBuilder ForView -> AnimBuilder ForView

-}
type alias ForView =
    Internal.ForView



-- ============================================================
-- ENGINE MODES
-- ============================================================


{-| Builder mode for Keyframe builders.

    f : AnimBuilder ForKeyframe -> AnimBuilder ForKeyframe

-}
type alias ForKeyframe =
    Internal.ForKeyframe


{-| Builder mode for Sub builders.

    f : AnimBuilder ForSub -> AnimBuilder ForSub

-}
type alias ForSub =
    Internal.ForSub


{-| Builder mode for Transition builders.

    f : AnimBuilder ForTransition -> AnimBuilder ForTransition

-}
type alias ForTransition =
    Internal.ForTransition


{-| Builder mode for WAAPI builders.

    f : AnimBuilder ForWAAPI -> AnimBuilder ForWAAPI

-}
type alias ForWAAPI =
    Internal.ForWAAPI



-- ============================================================
-- DOCUMENT TIMELINE FUNCTIONS
-- ============================================================


{-| Set the global delay for all animations in a Document timeline builder.

    introAnim : AnimBuilder { m | forDocument : (), supportsTime : () } -> AnimBuilder { m | forDocument : (), supportsTime : () }
    introAnim =
        delay 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
delay : Int -> AnimBuilder { m | supportsTime : () } -> AnimBuilder { m | supportsTime : () }
delay =
    Internal.delay


{-| Set the global duration for all animations in a Document timeline builder.

    introAnim : AnimBuilder { m | forDocument : (), supportsTime : () } -> AnimBuilder { m | forDocument : (), supportsTime : () }
    introAnim =
        duration 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
duration : Int -> AnimBuilder { m | supportsTime : () } -> AnimBuilder { m | supportsTime : () }
duration =
    Internal.duration


{-| Set the global speed for all animations in a Document timeline builder.

    introAnim : AnimBuilder { m | forDocument : (), supportsTime : () } -> AnimBuilder { m | forDocument : (), supportsTime : () }
    introAnim =
        speed 300
            >> slideDownHeader
            >> slideInSidebar
            >> slideUpContent

-}
speed : Float -> AnimBuilder { m | supportsTime : () } -> AnimBuilder { m | supportsTime : () }
speed =
    Internal.speed



-- ============================================================
-- UNIVERSAL FUNCTIONS
-- ============================================================
-- Playback


{-| Set how many times an animation should repeat.

    notificationAttentionLoop : AnimBuilder mode -> AnimBuilder mode
    notificationAttentionLoop =
        iterations 3
            >> pulseBadge
            >> nudgeBellIcon

-}
iterations : Int -> AnimBuilder { m | supportsIterations : () } -> AnimBuilder { m | supportsIterations : () }
iterations =
    Internal.iterations


{-| Make an animation alternate direction on each iteration.

    floatingCardLoop : AnimBuilder mode -> AnimBuilder mode
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
alternate : AnimBuilder { m | supportsAlternate : () } -> AnimBuilder { m | supportsAlternate : () }
alternate =
    Internal.alternate



-- Motion Behaviour


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
spring : Spring -> AnimBuilder { m | supportsSpring : () } -> AnimBuilder { m | supportsSpring : () }
spring =
    Internal.spring



-- Units


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
