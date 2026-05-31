module Anim.Builder exposing
    ( AnimBuilder
    , ForKeyframe, ForSub, ForTransition, ForWAAPI, ForScroll, ForView
    , delay, duration, speed
    , iterations, alternate
    , easing, spring
    , cssUnit, cssUnitX, cssUnitY, cssUnitZ, cssUnitWidth, cssUnitHeight
    )

{-| Shared builder types and settings for animations.

Most app code will use the engine and property modules directly.

This module contains shared types and global builder settings.


# Types

@docs AnimBuilder


## Engine Capability Types

Use these to constrain a builder function to one specific Engine.

@docs ForKeyframe, ForSub, ForTransition, ForWAAPI, ForScroll, ForView


# Builder Settings

All the engines expose their own equivalents of these functions that are engine-specific,
these are the engine-agnostic versions. Use these when you are writing builder functions
that should work across engines, or when you don't want to commit to a specific engine.


## Timing

These settings are for Document timeline engines: Keyframe, Sub, Transition, and WAAPI.

@docs delay, duration, speed


## Playback

@docs iterations, alternate


# Motion Behaviour

@docs easing, spring


# CSS Units

Set the CSS unit for built-in properties that use length values.

This is useful when you want those properties to render in units like `rem`, `cqh` or `vw`, for example, instead of `px`, the default.

📖 See the property docs and [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for more details.

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

    f : AnimBuilder eng -> AnimBuilder eng

The `eng` type parameter is a phantom type used to optionally constrain
builder functions to specific engines or capabilities.

📖 See [Engine Capabilities](https://phollyer.github.io/elm-motion/animation/concepts/engine-capabilities/)
in the docs for detailed examples and patterns.

-}
type alias AnimBuilder eng =
    Internal.AnimBuilder eng



-- ============================================================
-- ENGINE CAPABILITIES
-- ============================================================


{-| Builder type for Keyframe builders.

    f : AnimBuilder ForKeyframe -> AnimBuilder ForKeyframe

-}
type alias ForKeyframe =
    Internal.ForKeyframe


{-| Builder type for Sub builders.

    f : AnimBuilder ForSub -> AnimBuilder ForSub

-}
type alias ForSub =
    Internal.ForSub


{-| Builder type for Transition builders.

    f : AnimBuilder ForTransition -> AnimBuilder ForTransition

-}
type alias ForTransition =
    Internal.ForTransition


{-| Builder type for WAAPI builders.

    f : AnimBuilder ForWAAPI -> AnimBuilder ForWAAPI

-}
type alias ForWAAPI =
    Internal.ForWAAPI


{-| Builder type for ScrollTimeline builders.

    f : AnimBuilder ForScroll -> AnimBuilder ForScroll

-}
type alias ForScroll =
    Internal.ForScroll


{-| Builder type for ViewTimeline builders.

    f : AnimBuilder ForView -> AnimBuilder ForView

-}
type alias ForView =
    Internal.ForView



-- ============================================================
-- TIMING CAPABILITIES
-- ============================================================


{-| Set the global delay for all animations in a Document timeline builder.

    introAnim : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
    introAnim =
        delay 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
delay : Int -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
delay =
    Internal.delay


{-| Set the global duration for all animations in a Document timeline builder.

    introAnim : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
    introAnim =
        duration 500
            >> fadeInHeader
            >> slideInSidebar
            >> fadeInContent

-}
duration : Int -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
duration =
    Internal.duration


{-| Set the global speed for all animations in a Document timeline builder.

    introAnim : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
    introAnim =
        speed 300
            >> slideDownHeader
            >> slideInSidebar
            >> slideUpContent

-}
speed : Float -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
speed =
    Internal.speed



-- ============================================================
-- PLAYBACK CAPABILITIES
-- ============================================================


{-| Set how many times an animation should repeat.

    notificationAttentionLoop : AnimBuilder { eng | withIterations : () } -> AnimBuilder { eng | withIterations : () }
    notificationAttentionLoop =
        iterations 3
            >> pulseBadge
            >> nudgeBellIcon

-}
iterations : Int -> AnimBuilder { eng | withIterations : () } -> AnimBuilder { eng | withIterations : () }
iterations =
    Internal.iterations


{-| Make an animation alternate direction on each iteration.

    floatingCardLoop : AnimBuilder { eng | withAlternate : () } -> AnimBuilder { eng | withAlternate : () }
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
alternate : AnimBuilder { eng | withAlternate : () } -> AnimBuilder { eng | withAlternate : () }
alternate =
    Internal.alternate



-- ============================================================
-- MOTION CAPABILITIES
-- ============================================================


{-| Set the global easing function.

    heroEntrance : AnimBuilder { eng | withEasing : () } -> AnimBuilder { eng | withEasing : () }
    heroEntrance =
        easing EaseInOut
            >> fadeInHeroTitle
            >> slideInHeroArtwork
            >> revealPrimaryCta

-}
easing : Easing -> AnimBuilder { eng | withEasing : () } -> AnimBuilder { eng | withEasing : () }
easing =
    Internal.easing


{-| Set the global spring.

    draggableCardSettle : AnimBuilder { eng | withSpring : () } -> AnimBuilder { eng | withSpring : () }
    draggableCardSettle =
        spring Spring.wobbly
            >> settleCardPosition
            >> settleCardShadow

-}
spring : Spring -> AnimBuilder { eng | withSpring : () } -> AnimBuilder { eng | withSpring : () }
spring =
    Internal.spring



-- ============================================================
-- CSS UNIT CAPABILITIES
-- ============================================================


{-| Set the default length unit for all length-bearing properties.

    responsivePanelMotion : AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
    responsivePanelMotion =
        cssUnit Unit.Vw
            >> slidePanelIn
            >> growPanelHeight

-}
cssUnit : Unit -> AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
cssUnit =
    Internal.cssUnit


{-| Set the default length unit for the X axis.

    responsiveDrawerMotion : AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
    responsiveDrawerMotion =
        cssUnitX Unit.Vw
            >> slideDrawerX
            >> alignDrawerLabelX

-}
cssUnitX : Unit -> AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
cssUnitX =
    Internal.cssUnitX


{-| Set the default length unit for the Y axis.

    responsiveSheetMotion : AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
    responsiveSheetMotion =
        cssUnitY Unit.Vh
            >> slideSheetY
            >> alignSheetHeaderY

-}
cssUnitY : Unit -> AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
cssUnitY =
    Internal.cssUnitY


{-| Set the default length unit for the Z axis.

    layeredSceneMotion : AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
    layeredSceneMotion =
        cssUnitZ Unit.Px
            >> pushSceneBackgroundBack
            >> bringFloatingCardForward

-}
cssUnitZ : Unit -> AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
cssUnitZ =
    Internal.cssUnitZ


{-| Set the default length unit used for width values.

    responsiveCardWidth : AnimBuilder { eng | withCssUnit : () } -> AnimBuilder { eng | withCssUnit : () }
    responsiveCardWidth =
        cssUnitWidth Unit.Vw
            >> growCardWidth
            >> settleCardSpacing

-}
cssUnitWidth : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitWidth =
    Internal.cssUnitWidth


{-| Set the default length unit used for height values.

    responsivePanelHeight : AnimBuilder eng -> AnimBuilder eng
    responsivePanelHeight =
        cssUnitHeight Unit.Vh
            >> expandPanelHeight
            >> alignPanelHeaderY

-}
cssUnitHeight : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitHeight =
    Internal.cssUnitHeight
