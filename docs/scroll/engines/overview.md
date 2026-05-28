# Scroll Engines Overview

Three engines, one shared builder API. This page lays them out side by side so you can pick the right one for the job.

For implementation details, each engine page is a complete walkthrough:

- [`Scroll.Cmd`](cmd.md) - fire-and-forget. Simplest setup. No state.
- [`Scroll.Task`](task.md) - a `Task` you can compose, with typed success/failure results.
- [`Scroll.Sub`](sub.md) - state-tracked. Pause, resume, stop, query position, react to live progress, interrupt mid-flight.

## One Mental Model

All three engines build scrolls from the same `Scroll.Builder` pipeline.

You describe *what* to scroll to once, and the same builder works in every engine:

??? example "Shared Builder Pattern"

    ```elm
    scrollToSection : String -> ScrollBuilder -> ScrollBuilder
    scrollToSection sectionId =
        Scroll.forDocument
            >> Scroll.toElement sectionId
            >> Scroll.speed 300
            >> Scroll.build
    ```

What changes per engine is *how* you run that builder: how the scroll is triggered, how results come back, and how much you can do mid-scroll.

## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| "Scroll to here, I don't need to know when it's done" | [Cmd](cmd.md) |
| "Scroll to here, tell me if it succeeded or failed" | [Task](task.md) |
| "Scroll to here, and let me change my mind mid-flight" | [Sub](sub.md) |
| Live progress (e.g. driving a scrollbar indicator) | [Sub](sub.md) |
| Pause / resume / restart while scrolling | [Sub](sub.md) |
| Composing a scroll with another `Task` (e.g. fetch then scroll) | [Task](task.md) |
| Smooth redirect when the user clicks a different target mid-scroll | [Sub](sub.md) |

### Feature Comparison

| Feature | Cmd | Task | Sub |
| ------- | :-: | :--: | :-: |
| **Trigger return type** |
| Fire-and-forget `Cmd` | ✓ | | |
| Composable `Task` | | ✓ | |
| `( ScrollState, Cmd msg )` | | | ✓ |
| **State** |
| Stateless | ✓ | ✓ | |
| Stored in your model | | | ✓ |
| **Result handling** |
| Completion message | ✓ | | |
| Typed `Result` | | ✓ | |
| Lifecycle events stream | | | ✓ |
| Continue-through-failure mode | | ✓ | |
| **Mid-Scroll Control** |
| Stop | | | ✓ |
| Pause / Resume | | | ✓ |
| Reset / Restart | | | ✓ |
| Interrupt and redirect | | | ✓ |
| **Live Events** |
| Started / Ended | | | ✓ |
| Stopped / Paused / Resumed / Restarted | | | ✓ |
| Progress (per-frame position + percentage) | | | ✓ |
| **Queries** |
| Current scroll position | | | ✓ |
| Is a scroll running? | | | ✓ |

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live, side-by-side demonstration of what happens when each engine is re-triggered mid-flight.

## Engine Families

### Fire-and-forget engines

`Cmd` and `Task` keep no state at runtime. You describe a scroll, hand it to the engine, and the scroll happens. Once dispatched, you cannot cancel or redirect it.

- `Cmd` returns a `Cmd msg` directly. You optionally hear back via a completion message.
- `Task` returns a `Task` you can compose with other `Task`s before turning it into a `Cmd`. You get a typed `Result` when it finishes.

### State-tracked engine

`Sub` stores `ScrollState` in your model. The engine subscribes for animation-frame updates while a scroll is in progress and emits lifecycle events you can react to. Because the engine sees every frame, it can pause, resume, redirect, and answer questions like "where is the scroll right now?" - none of which are possible with `Cmd` or `Task`.

## Timing

`Cmd` and `Task` pre-calculate every frame of the scroll up front, then write them out as a chain of DOM updates. On busy pages or high-refresh-rate displays, the *perceived* duration can drift from the configured duration.

`Sub` advances each frame using a real delta-time, so timing stays close to what you configured regardless of frame rate.

If timing precision matters, use [Sub](sub.md).

[Check your display's refresh rate](../../tools/fps-test.html){ target="_blank" }

## Switching Engines

Because the builder API is shared, the *scroll definition* stays the same when you move between engines. What changes is the wiring around it:

- imports
- the trigger call (`Cmd` returns `Cmd msg`, `Task` returns a `Task`, `Sub` returns `( ScrollState, Cmd msg )`)
- whether you wire `update` and `subscriptions` for engine messages (only `Sub`)

??? example "Portable Scroll Builder"

    ```elm
    scrollToTop : ScrollBuilder -> ScrollBuilder
    scrollToTop =
        Scroll.forContainer "results-panel"
            >> Scroll.toTop
            >> Scroll.duration 350
            >> Scroll.build
    ```

    This single definition is valid input for `Cmd.scroll`, `Task.scroll`, and `Sub.scroll`.

## Next Steps

Start with the simplest engine and work up only when you need more.

[Cmd Engine →](cmd.md){ .md-button .md-button--primary }
