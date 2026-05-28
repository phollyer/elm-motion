# Scroll Sub Engine

This page is a practical guide to using the Sub engine.
Read [Scroll Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

`Scroll.Sub` is the full-featured scroll engine. Instead of pre-calculating a scroll and firing it as a `Cmd`, it stores `ScrollState` in your model and updates it on every animation frame via a subscription.

That extra wiring buys you a lot:

- pause, resume, stop, reset, restart at any time,
- redirect the scroll to a new target mid-flight,
- read the current scroll position any time,
- react to `Started`, `Ended`, `Progress`, `Paused`, `Resumed`, `Stopped`, `Restarted` events.

If you don't need any of those, [Cmd](cmd.md) or [Task](task.md) are simpler.

## Example

A vertical scroll with full state and event handling.

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Sub/FirstScroll/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/FirstScroll/Main.elm"
    ```

📖 See [Vertical Scrolling](../first-scrolls/vertical-scrolling.md) for a step-by-step breakdown.

---

## Quick Walkthrough

There are four moving parts to wire up: a piece of state in your model, a subscription, an `update` handler, and the trigger.

### 1. Initialize

Store a `ScrollState` in your model and seed it with `Sub.init`:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Sub as Sub


    type alias Model =
        { scrollState : Sub.ScrollState }


    init : ( Model, Cmd Msg )
    init =
        ( { scrollState = Sub.init }, Cmd.none )
    ```

### 2. Subscribe

Wire the engine into `subscriptions`. The subscription is dormant when no scrolls are running and only activates while something is in flight:

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions ScrollMsg model.scrollState
    ```

📖 See [Subscribe](../workflow/subscribe.md) for more info.

### 3. Trigger

`Sub.scroll` takes a tagger, the current state, and a builder. It returns `( ScrollState, Cmd msg )`:

??? example "View Source Code"

    ```elm
    import Scroll.Builder as Scroll
    import Motion.Easing exposing (Easing(..))


    type Msg
        = ScrollTo String
        | ScrollMsg Sub.ScrollMsg


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                let
                    ( newState, cmd ) =
                        Sub.scroll ScrollMsg model.scrollState <|
                            Scroll.forContainer "scroll-container"
                                >> Scroll.toElement targetId
                                >> Scroll.speed 400
                                >> Scroll.easing BounceOut
                                >> Scroll.build
                in
                ( { model | scrollState = newState }, cmd )
    ```

If a scroll for the same container is already running, this **replaces** it - the new scroll picks up from the current position. That's how mid-flight redirection works.

### 4. React

Forward engine messages into `Sub.update`. It returns the new state, a list of events that happened on this frame, and any `Cmd` the engine needs to issue:

??? example "View Source Code"

    ```elm
            ScrollMsg scrollMsg ->
                let
                    ( newState, events, cmd ) =
                        Sub.update ScrollMsg scrollMsg model.scrollState
                in
                ( { model | scrollState = newState }
                , cmd
                )
    ```

If you want to react to events, fold over the list - see [Events](#events) below.

📖 See [React](../workflow/react.md) for more info.

---

## In Detail

### Events

`Sub.update` returns a `List ScrollEvent`. Multiple events can fire on the same frame.

Every event carries a `Container` so you know which scroll surface (`Sub.Document` or `Sub.Container "id"`) it belongs to.

| Event | Payload | Fires when... |
| ----- | ------- | ------------- |
| `Started` | `Container` | A scroll begins. |
| `Ended` | `Container` | A scroll completes naturally. |
| `Progress` | `Container`, `{ x, y }`, `Float` | Every frame while running. The `Float` is `0.0`–`1.0` progress. |
| `Stopped` | `Container` | A scroll was stopped before completing. |
| `Paused` | `Container` | A scroll was paused. |
| `Resumed` | `Container` | A paused scroll resumed. |
| `Restarted` | `Container` | A scroll was reset and replayed. |

??? example "Handling events"

    ```elm
    ScrollMsg scrollMsg ->
        let
            ( newState, events, cmd ) =
                Sub.update ScrollMsg scrollMsg model.scrollState
        in
        ( List.foldl handleEvent { model | scrollState = newState } events
        , cmd
        )


    handleEvent : Sub.ScrollEvent -> Model -> Model
    handleEvent event model =
        case event of
            Sub.Progress _ _ progress ->
                { model | percent = round (progress * 100) }

            Sub.Ended _ ->
                { model | status = "Arrived" }

            _ ->
                model
    ```

### Live Progress

Because `Progress` fires every frame with the current `{ x, y }` position and a `0.0`–`1.0` progress value, you can drive scrollbars, percentage readouts, and parallax effects directly from scroll state:

??? example "View Source Code"

    ```elm
    Sub.Progress _ position progress ->
        { model
            | scrollX = position.x
            , scrollY = position.y
            , percent = round (progress * 100)
        }
    ```

### Controls

Each control takes a `Container` so you can target a specific scroll.

| Function | Behaviour |
| -------- | --------- |
| `stop` | Jump to the **target** position and finish |
| `pause` | Freeze at the current position |
| `resume` | Continue from where `pause` froze |
| `reset` | Jump to the **start** position and finish |
| `restart` | Reset to start, then play again |

`stop`, `reset`, and `restart` issue commands, so they return `( ScrollState, Cmd msg )`:

??? example "View Source Code"

    ```elm
    StopScroll ->
        let
            ( newState, cmd ) =
                Sub.stop Sub.Document ScrollMsg model.scrollState
        in
        ( { model | scrollState = newState }, cmd )
    ```

`pause` and `resume` are state-only - they return just `ScrollState`:

??? example "View Source Code"

    ```elm
    PauseScroll ->
        ( { model | scrollState = Sub.pause (Sub.Container "sidebar") model.scrollState }
        , Cmd.none
        )
    ```

📖 See [Controlling Scrolls](../concepts/controlling-scroll.md) for live examples.

### Querying State

You can ask the engine what's happening at any moment - useful for showing UI ("Scrolling..."), conditionally enabling controls, or making decisions before triggering the next scroll.

??? example "View Source Code"

    ```elm
    -- Is any scroll currently running?
    Sub.anyRunning model.scrollState
        -- Maybe Bool

    -- Is a specific container scrolling?
    Sub.isRunning Sub.Document model.scrollState
        -- Maybe Bool

    -- Current scroll position
    Sub.getPosition Sub.Document model.scrollState
        -- Maybe { x : Float, y : Float }

    -- Single-axis variants
    Sub.getPositionX Sub.Document model.scrollState
    Sub.getPositionY Sub.Document model.scrollState
    ```

All queries return `Maybe` because the container in question might never have been scrolled.

### Multiple Concurrent Scrolls

You can have several scrolls running at once inside a single `ScrollState` - for example a sidebar and a main panel scrolling independently. Each container is tracked separately, fires its own events, and can be controlled and queried on its own.

### Mid-Flight Redirection

This is the headline feature. Trigger `Sub.scroll` for the same container while a scroll is in flight, and the engine replaces it - smoothly carrying on from the current position to the new target instead of fighting with the old animation.

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live side-by-side demonstration of all three engines.

### Timing

`Sub` advances each frame with a real animation-frame delta-time, so the configured `duration` / `speed` stays close to actual perceived time, even on high-refresh-rate displays.

If you need timing precision, this is the engine to pick.

[Check your display's refresh rate](../../tools/fps-test.html){ target="_blank" }

📖 See [Timing](../concepts/timing.md) for more info.

### Easing

Defaults to `Linear`. Any easing from `Motion.Easing` works via `Scroll.easing`.

📖 See [Easing](../concepts/easing.md) for the full list and live previews.

## When to Choose This Engine

Choose `Sub` when you need any of:

- pause / resume / stop / reset / restart,
- mid-flight redirection,
- live progress events (scrollbars, percentage readouts, parallax),
- queries for current scroll position or "is a scroll running?",
- precise timing that doesn't drift with frame rate.

For everything else, [Cmd](cmd.md) or [Task](task.md) are simpler.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `ScrollState` | Lives in your model |
| `ScrollMsg` | Internal message handled by `update` and `subscriptions` |
| `ScrollEvent` | `Started` / `Ended` / `Progress` / `Stopped` / `Paused` / `Resumed` / `Restarted` |
| `Container` | `Document` or `Container "element-id"` |

### Initialize

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `ScrollState` | Empty initial state |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `scroll` | `(ScrollMsg -> msg) -> ScrollState -> (ScrollBuilder -> ScrollBuilder) -> ( ScrollState, Cmd msg )` | Start or redirect a scroll |

### Update / Subscribe

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `(ScrollMsg -> msg) -> ScrollMsg -> ScrollState -> ( ScrollState, List ScrollEvent, Cmd msg )` | Advance state and emit events |
| `subscriptions` | `(ScrollMsg -> msg) -> ScrollState -> Sub msg` | Animation-frame subscription |

### Timing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `delay` | `Int -> ScrollBuilder -> ScrollBuilder` | Wait before scrolling (ms) |
| `duration` | `Int -> ScrollBuilder -> ScrollBuilder` | Total scroll time (ms) |
| `speed` | `Float -> ScrollBuilder -> ScrollBuilder` | Scroll rate (px/sec) |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> ScrollBuilder -> ScrollBuilder` | Set the easing curve |

### Controls

| Function | Type | Description |
| -------- | ---- | ----------- |
| `stop` | `Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )` | Jump to target and finish |
| `pause` | `Container -> ScrollState -> ScrollState` | Freeze at current position |
| `resume` | `Container -> ScrollState -> ScrollState` | Continue a paused scroll |
| `reset` | `Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )` | Jump to start and finish |
| `restart` | `Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )` | Reset, then replay |

### Queries

| Function | Type | Description |
| -------- | ---- | ----------- |
| `anyRunning` | `ScrollState -> Maybe Bool` | Any scroll running? |
| `isRunning` | `Container -> ScrollState -> Maybe Bool` | This container scrolling? |
| `getPosition` | `Container -> ScrollState -> Maybe { x : Float, y : Float }` | Current position |
| `getPositionX` | `Container -> ScrollState -> Maybe Float` | Current X |
| `getPositionY` | `Container -> ScrollState -> Maybe Float` | Current Y |

For complete API details, see the [Scroll.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Sub) documentation.

## Next Steps

Now that you know the engines, learn how the same scroll behaves differently when interrupted mid-flight.

[Interrupting Scrolls →](../concepts/interrupting-scrolls.md){ .md-button .md-button--primary }
