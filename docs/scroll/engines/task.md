# Scroll Task Engine

This page is a practical guide to using the Task engine.
Read [Scroll Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

`Scroll.Task` is `Scroll.Cmd` with a typed result attached. It returns a `Task` instead of a `Cmd`, which means you can:

- find out whether the scroll succeeded or failed,
- chain it with other `Task`s (load data, then scroll to the new content),
- run a sequence of scrolls and decide what to do if one fails partway through.

If you don't need any of that, [Cmd](cmd.md) is simpler. If you need pause / resume / live progress, you want [Sub](sub.md).

## Example

A vertical scroll between three named sections, with `Ok` / `Err` handling.

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Task/FirstScroll/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm"
    ```

📖 See [Vertical Scrolling](../first-scrolls/vertical-scrolling.md) for a step-by-step breakdown.

---

## Quick Walkthrough

### 1. Build

Same builder API as every other scroll engine:

??? example "View Source Code"

    ```elm
    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task exposing (ScrollBuilder, ScrollOk, ScrollError)
    import Motion.Easing exposing (Easing(..))


    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement targetId =
        Scroll.forContainer "scroll-container"
            >> Scroll.toElement targetId
            >> Scroll.speed 400
            >> Scroll.easing BounceOut
            >> Scroll.build
    ```

📖 See [Build](../workflow/build.md) for the full builder API.

### 2. Trigger

`Task.scroll` returns a `Task ScrollError (List ScrollOk)`. Turn it into a `Cmd` with `Task.attempt`:

??? example "View Source Code"

    ```elm
    import Task


    type Msg
        = ScrollTo String
        | ScrollResult (Result ScrollError (List ScrollOk))


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( model
                , scrollToElement targetId
                    |> Task.scroll
                    |> Task.attempt ScrollResult
                )
    ```

### 3. Handle the Result

`Ok` carries one `ScrollOk` per scroll that completed; `Err` carries a typed `ScrollError`:

??? example "View Source Code"

    ```elm
            ScrollResult (Ok _) ->
                ( { model | status = "Arrived" }, Cmd.none )

            ScrollResult (Err _) ->
                ( { model | status = "Scroll failed" }, Cmd.none )
    ```

📖 See [React](../workflow/react.md) for more info.

---

## In Detail

### Success - `ScrollOk`

`ScrollOk` represents one successfully completed scroll:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was scrolled |
| `targetElementId` | `Maybe String` | The target element ID, if one was set with `toElement` |

### Failure - `ScrollError`

`ScrollError` represents a scroll that couldn't complete - most commonly because the target element wasn't in the DOM:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was being scrolled |
| `targetElementId` | `Maybe String` | The target element ID, if one was set |
| `domError` | `Dom.Error` | The underlying [`Dom.Error`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) |

### Sequential Scrolls in One Builder

Chain several `build` calls into one builder pipeline. The scrolls run one after another, in pipeline order:

??? example "View Source Code"

    ```elm
    scrollSequence : ScrollBuilder -> ScrollBuilder
    scrollSequence =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.build
            >> Scroll.forDocument
            >> Scroll.toElement "section-2"
            >> Scroll.build
    ```

`Task.scroll` is **fail-fast**: the first scroll to fail ends the task immediately, and later scrolls in the same builder are skipped. The `Ok` payload lists every scroll that *did* complete, in order.

### Continue Through Failures

If you'd rather get a result for **every** scroll target - failures included - use `Task.scrollEach`:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollAttempts (List (Result ScrollError ScrollOk))


    ScrollToSequence ->
        ( model
        , scrollSequence
            |> Task.scrollEach
            |> Task.perform ScrollAttempts
        )
    ```

`scrollEach` always completes (its error type is `Never`) and returns one `Result` per target, in pipeline order.

### Parallel Scrolls

To run independent scrolls in parallel (each with its own success/failure handling), build them separately and batch the resulting `Cmd`s:

??? example "View Source Code"

    ```elm
    ( model
    , Cmd.batch
        [ Task.scroll scrollSidebar
            |> Task.attempt SidebarResult
        , Task.scroll scrollMain
            |> Task.attempt MainResult
        ]
    )
    ```

### Task Composition

Because `Task.scroll` is a `Task`, you can compose it with anything else returning a `Task`. Classic example - fetch some data, then scroll to whatever the response pointed at:

??? example "View Source Code"

    ```elm
    fetchArticle "article-123"
        |> Task.andThen
            (Task.scroll << scrollToSection << .anchorId)
        |> Task.attempt GotResult
    ```

### Re-Triggering Mid-Scroll

Like [Cmd](cmd.md), the Task engine doesn't cancel an in-flight scroll when you trigger another one. Each call runs independently. If the new scroll has a different target, the two will fight for control of the container.

If you need clean redirection mid-flight, use [Sub](sub.md).

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live demonstration.

### Timing

Same model as [Cmd](cmd.md): `Task` pre-calculates every frame and dispatches them. On busy pages or high-refresh-rate displays, the actual duration may drift from what you configured.

If timing precision matters, use [Sub](sub.md).

📖 See [Timing](../concepts/timing.md) for more info.

### Easing

Defaults to `Linear`. Any easing from `Motion.Easing` works via `Scroll.easing`.

📖 See [Easing](../concepts/easing.md) for the full list and live previews.

## When to Choose This Engine

Choose `Task` when:

- you need typed `Ok` / `Err` results,
- you want to compose a scroll with other tasks (e.g. fetch then scroll),
- you have a sequence of scrolls and need explicit failure semantics (fail-fast vs continue-through-failure).

Use [Cmd](cmd.md) if you don't need any of the above.

Use [Sub](sub.md) when you need state - pausing, redirecting, querying position, or reacting to live progress.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `ScrollBuilder` | Carries scroll configuration through the builder pipeline |
| `Container` | Scroll surface (`Document` or `Container "element-id"`) |
| `ScrollOk` | Success payload (`container`, `targetElementId`) |
| `ScrollError` | Failure payload (`container`, `targetElementId`, `domError`) |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `scroll` | `(ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)` | Fail-fast scroll task |
| `scrollEach` | `(ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))` | One `Result` per target |

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

For complete API details, see the [Scroll.Engine.Task](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Task) documentation.

## Next Steps

Need state, mid-flight redirects, pause / resume, or per-frame progress?

[Sub Engine →](sub.md){ .md-button .md-button--primary }
