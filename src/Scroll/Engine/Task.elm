module Scroll.Engine.Task exposing
    ( ScrollBuilder, Container(..)
    , ScrollError(..), ScrollOk
    , scroll, scrollEach
    , delay, duration, speed
    , easing
    )

{-| Scroll animations as Tasks for when you want results, typed error handling or composition
with other Tasks.

📖 See
[Scroll Task Engine Documentation](https://phollyer.github.io/elm-motion/scroll/engines/task/)
and
[Scroll Overview](https://phollyer.github.io/elm-motion/scroll/engines/overview/)
for details.

Use the [Builder](Scroll-Builder) module to configure scroll targets.


# Types

@docs ScrollBuilder, Container


# Trigger

@docs ScrollError, ScrollOk

@docs scroll, scrollEach


# Timing

📖 See [Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/) for details.

@docs delay, duration, speed


# Easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) for details.

@docs easing

-}

import Browser.Dom as Dom
import Motion.Easing exposing (Easing(..))
import Scroll.Internal.Engine.Task as Internal
import Scroll.Internal.ScrollBuilder as SB
import Task exposing (Task)



-- ============================================================
-- TYPES
-- ============================================================


{-| Builder type for scroll animations.
-}
type alias ScrollBuilder =
    SB.ScrollBuilder


{-| Identifies the scroll surface handled by the engine.

Use `Document` for the document body, or `Container "element-id"` for a
specific scrollable element.

-}
type Container
    = Document
    | Container String


{-| Error returned when a scroll task fails.

It tells you what container failed, which target was involved, and the DOM error:

  - `container`: The container that was being scrolled
  - `targetElementId`: The element ID if scrolling to an element target
  - `domError`: The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) that caused the scroll to fail

-}
type ScrollError
    = ScrollError
        { container : Container
        , targetElementId : Maybe String
        , domError : Dom.Error
        }


{-| Value returned when a scroll task succeeds.

It tells you which container finished scrolling and, when relevant, which target element was used:

  - `container`: The container that was scrolled
  - `targetElementId`: The element ID if scrolled to an element target

-}
type alias ScrollOk =
    { container : Container
    , targetElementId : Maybe String
    }



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Start one or more scrolls as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

You get one `ScrollOk` for each completed target. If any target fails, the task stops with `ScrollError`.
Use [`scrollEach`](#scrollEach) when you want every target to run even if one fails.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task
    import Task

    type Msg
        = HandleScrollResult (Result ScrollError (List ScrollOk))
        | ...

    Task.scroll (scrollToElement "target-section")
         |> Task.attempt HandleScrollResult

If you need progress, cancellation, or safe retriggering, use
[Scroll.Engine.Sub](Scroll-Engine-Sub) instead.

-}
scroll : (ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)
scroll =
    Internal.scroll
        >> Task.mapError toPublicError
        >> Task.map (List.map toPublicOk)


{-| Run each scroll target in order and collect every result.

Unlike [`scroll`](#scroll), this keeps going after failures and gives you one `Result` per target.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task
    import Task

    type Msg
        = HandleScrollResults (List (Result ScrollError ScrollOk))
        | ...

    Task.scrollEach (scrollSequence "chapter-2")
         |> Task.perform HandleScrollResults

-}
scrollEach : (ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))
scrollEach =
    Internal.scrollEach
        >> Task.map (List.map (Result.mapError toPublicError >> Result.map toPublicOk))


toPublicError : Internal.ScrollError -> ScrollError
toPublicError error =
    case error of
        Internal.ScrollError { containerId, targetElementId, domError } ->
            ScrollError
                { container = containerFromId containerId
                , targetElementId = targetElementId
                , domError = domError
                }


toPublicOk : { containerId : String, targetElementId : Maybe String } -> ScrollOk
toPublicOk ok =
    { container = containerFromId ok.containerId
    , targetElementId = ok.targetElementId
    }


containerFromId : String -> Container
containerFromId containerId =
    if containerId == "document" then
        Document

    else
        Container containerId



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all scrolls.

This will be inherited by all scrolls that
don't define their own delay.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.delay 100
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
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.duration 1000
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
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.speed 200
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

    import Motion.Easing exposing (Easing(..))
    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.easing BounceOut
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    SB.setEasing
