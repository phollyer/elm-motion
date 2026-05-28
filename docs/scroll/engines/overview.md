# Scroll Engines Overview

Three engines, one shared [builder](../builder.md). You describe the scroll once, then pick the engine that matches the level of control you need.

| Engine | One-liner |
| ------ | --------- |
| [`Scroll.Cmd`](cmd.md) | Fire-and-forget. The simplest possible setup. |
| [`Scroll.Task`](task.md) | Fire-and-forget with a typed `Result`. Composable with other `Task`s. |
| [`Scroll.Sub`](sub.md) | State-tracked. Pause, resume, stop, query position, react to live progress, redirect mid-flight. |

Cmd and Task share most of their API and trade-offs, so they live on one page. Sub is the full-featured engine and gets its own.

## Decision Guide

| What you want to do | Pick |
| ------------------- | ---- |
| Scroll, and that's all | [Cmd](cmd.md) |
| Scroll, and know if it succeeded or failed | [Task](task.md) |
| Compose a scroll with another `Task` (e.g. fetch then scroll) | [Task](task.md) |
| Smooth redirect when the user clicks a different target mid-scroll | [Sub](sub.md) |
| Pause / resume / restart / stop a running scroll | [Sub](sub.md) |
| Drive a scrollbar or percentage readout from live progress | [Sub](sub.md) |
| Query the current scroll position | [Sub](sub.md) |
| Precise timing on high-refresh-rate displays | [Sub](sub.md) |

## Feature Comparison

| Feature | Cmd | Task | Sub |
| ------- | :-: | :--: | :-: |
| Fire-and-forget | ✓ | ✓ | |
| State-tracked | | | ✓ |
| Completion message | ✓ | | |
| Typed `Result` | | ✓ | |
| Continue-through-failure mode | | ✓ | |
| Composable with other `Task`s | | ✓ | |
| Lifecycle events stream | | | ✓ |
| Stop / Pause / Resume / Reset / Restart | | | ✓ |
| Mid-flight redirect | | | ✓ |
| Per-frame `Progress` event | | | ✓ |
| Position queries | | | ✓ |
| Frame-rate-independent timing | | | ✓ |

## Why Cmd and Task Behave the Same

Both engines pre-calculate every frame of the scroll at dispatch time and write them out as a chain of DOM updates. That has two practical consequences they both inherit:

- **Timing can drift.** Without access to vsync, the actual duration depends on machine load and refresh rate.
- **Re-triggering doesn't cancel.** A new scroll runs *alongside* the running one - they compete for the container.

[Sub](sub.md) avoids both because it advances each frame with a real delta-time and replaces the running scroll on re-trigger.

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live side-by-side demo.

## Switching Engines

The [builder](../builder.md) is the same in every engine, so the *scroll definition* stays put when you change engines - only the wiring changes:

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

Start with the simplest engines and work up only when you need more.

[Cmd Engine →](cmd.md){ .md-button .md-button--primary }
