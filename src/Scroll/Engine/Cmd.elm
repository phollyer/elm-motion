module Scroll.Engine.Cmd exposing
    ( ScrollBuilder
    , scroll
    , delay, duration, speed
    , easing
    )

{-| Use a simple fire-and-forget scroll command.

Choose this engine when you just want to trigger a scroll and move on.

📖 For setup, examples, and behaviour details, see the
[Scroll Cmd Engine Documentation](https://phollyer.github.io/elm-motion/engines/scroll/cmd/)
and the
[Scroll Overview](https://phollyer.github.io/elm-motion/engines/scroll/overview/).

Use the [Builder](Scroll-Builder) module to configure scroll targets.


# Types

@docs ScrollBuilder


# Trigger

@docs scroll


# Timing

@docs delay, duration, speed


# Easing

@docs easing

📖 See [Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/) and
[Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) in the docs.

-}

import Motion.Easing exposing (Easing)
import Scroll.Internal.Engine.Cmd as Internal
import Scroll.Internal.ScrollBuilder as SB



-- ============================================================
-- TYPES
-- ============================================================


{-| Builder type for scroll animations.
-}
type alias ScrollBuilder =
    SB.ScrollBuilder



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Start a scroll as a fire-and-forget [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    import Scroll.Engine.Cmd as Cmd

    type Msg
        = ScrollCompleted
        | ...

    Cmd.scroll ScrollCompleted <|
        scrollToElement "target-section"

If you need progress, cancellation, or safe retriggering, use
[Scroll.Engine.Sub](Scroll-Engine-Sub) instead.

-}
scroll : msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg
scroll =
    Internal.scroll



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all scrolls.

This will be inherited by all scrolls that
don't define their own delay.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Cmd as Cmd

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Cmd.delay 100
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    SB.setDelay


{-| Set the duration of all scrolls.

This will be inherited by all scrolls that
don't define their own duration.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Cmd as Cmd

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Cmd.duration 1000
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.build

-}
duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    SB.setDuration


{-| Set the speed that scrolls should run at.

This will be inherited by all scrolls that
don't define their own speed.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Cmd as Cmd

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Cmd.speed 200
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.build

-}
speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    SB.setSpeed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function to be used by all scrolls.

This will be inherited by all scrolls that
don't define their own easing.

    import Easing exposing (Easing(..))
    import Scroll.Builder as Scroll
    import Scroll.Engine.Cmd as Cmd

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Cmd.easing BounceOut
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    SB.setEasing
