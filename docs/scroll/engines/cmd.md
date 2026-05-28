# Scroll Cmd Engine

This page is a practical guide to using the Cmd engine.
Read [Scroll Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

`Scroll.Cmd` is the simplest possible scroll. You build a scroll, hand it to the runtime as a `Cmd`, and that's it - no model state, no subscriptions, no view wiring.

If your scroll is genuinely fire-and-forget ("scroll to here, I don't care about anything else"), this is the engine for you.

## Example

A vertical scroll between three named sections.

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Cmd/FirstScroll/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm"
    ```

📖 See [Vertical Scrolling](../first-scrolls/vertical-scrolling.md) for a step-by-step breakdown.

---

## Quick Walkthrough

### 1. Build

Describe the scroll as a builder function. Anything starting with `Scroll.forDocument` or `Scroll.forContainer "..."` and ending with `Scroll.build` is a valid scroll.

??? example "View Source Code"

    ```elm
    import Scroll.Builder as Scroll
    import Scroll.Engine.Cmd as Cmd exposing (ScrollBuilder)
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

Call `Cmd.scroll` from `update`. It takes a completion message and the builder, and returns a `Cmd`.

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollTo String
        | ScrollComplete


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( model
                , Cmd.scroll ScrollComplete <|
                    scrollToElement targetId
                )

            ScrollComplete ->
                ( model, Cmd.none )
    ```

That's the whole engine. No `init`, no `subscriptions`, nothing to render.

📖 See [Trigger](../workflow/trigger.md) for more info.

---

## In Detail

### Completion Message

The first argument to `Cmd.scroll` is the message you want fired when the scroll finishes. You can ignore it (do nothing in `update`), or use it to drive follow-up behaviour - load more data, kick off the next step in a tour, hide a "scrolling..." spinner, and so on.

If the target element doesn't exist in the DOM, `Cmd.scroll` fails silently. There's no error path - that's the trade-off for the simplest possible API. If you need to know about failures, use [Task](task.md).

### Multiple Targets in One Builder

You can chain several `build` calls into a single builder pipeline. Each one becomes a separate scroll dispatched at the same time:

??? example "View Source Code"

    ```elm
    scrollSidebarAndMain : ScrollBuilder -> ScrollBuilder
    scrollSidebarAndMain =
        Scroll.forContainer "sidebar"
            >> Scroll.toElement "nav-item-3"
            >> Scroll.speed 300
            >> Scroll.build
            >> Scroll.forContainer "main-content"
            >> Scroll.toElement "section-3"
            >> Scroll.speed 400
            >> Scroll.build
    ```

The completion message fires once **per target**, so the example above will fire `ScrollComplete` twice - once for each container.

### Re-Triggering Mid-Scroll

If the user clicks the same button twice while a scroll is in flight, `Cmd.scroll` does not cancel the running scroll. Both scrolls dispatch independently, and they will compete for control of the container.

Practical consequences:

- if the second click goes to the **same** target, both scrolls end correctly (they're aiming at the same place).
- if the second click goes to a **different** target, both scrolls fight, and the longer one usually wins - often finishing short of its actual target.

If you need clean redirection mid-flight, use [Sub](sub.md).

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live demonstration of all three engines side by side.

### Timing

`duration` and `speed` are interchangeable - use whichever is more natural for the scroll you're describing.

- `duration` - how long the scroll should take, in ms.
- `speed` - how fast the scroll should move, in pixels per second.
- `delay` - wait this many ms before starting.

Because `Cmd` pre-calculates every frame up front then writes them out as a `Task` chain, the *actual* duration can drift on busy pages or high-refresh-rate displays. If timing precision matters, use [Sub](sub.md).

📖 See [Timing](../concepts/timing.md) for more info.

### Easing

Defaults to `Linear`. Set any easing curve from `Motion.Easing` via `Scroll.easing`.

📖 See [Easing](../concepts/easing.md) for the full list and live previews.

## When to Choose This Engine

Choose `Cmd` when:

- the scroll is genuinely fire-and-forget,
- you don't need to know if it succeeded or failed,
- you don't need to pause, redirect, or query progress,
- you want the absolute minimum amount of wiring.

Use [Task](task.md) when you need a typed success/failure result, or want to compose scrolling with other tasks.

Use [Sub](sub.md) when you need to pause, resume, redirect, query position, or react to per-frame progress.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `ScrollBuilder` | Carries scroll configuration through the builder pipeline |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `scroll` | `msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg` | Dispatch a scroll and fire `msg` on completion |

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

For complete API details, see the [Scroll.Engine.Cmd](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Cmd) documentation.

## Next Steps

Need typed success / failure, or want to compose scrolls with other tasks?

[Task Engine →](task.md){ .md-button .md-button--primary }
