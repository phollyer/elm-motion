# Elm Motion

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.


## ✨ Features

- **Multiple Engines** — 6 Animation Engines, 3 Scroll Engines
- **Unified API** — Follow the same builder workflow across all Engines
- **Composable** — Compose animations and scrolls from small reusable pieces
- **Configurable** — Delay, duration, speed, easing, and spring physics
- **Interruptible & Controllable** — Query, divert, and control animations and scrolls mid-flight
- **Compiler-Enforced Engine Capabilities** — only the capabilities an engine actually supports compile against it

### Animation

- **Hardware-Accelerated** — GPU-powered transforms (translate, rotate, scale, skew, opacity)
- **Full 3D Support** — XYZ positioning, multi-axis rotation, perspective
- **Multi-Property Animations** — Animate multiple properties on the same element simultaneously, each with independent timing, easing, or spring
 — no master timeline to orchestrate
- **Time, Scroll & Viewport Driven** — Drive animations by elapsed time, page scroll progress or an element's position in the viewport — same builder API, three different timelines

### Scroll

- **Smooth Scrolling** — Document and container
- **Flexible Targets** — Scroll to elements, percentages, edges, corners, or relative deltas
- **Axis Control** — Scroll horizontally, vertically or both

## ⚙️ Engine Overview

### Animation

| Engine | Key Features |
| -------- | ---------- |
| [Transition](animation/engines/transition.md) | Browser-native performance; quick setup for simple A→B animations, minimal control (stop, reset) |
| [Keyframe](animation/engines/keyframes.md) | Browser-native performance, full control (stop, reset, restart, pause, resume), looping |
| [Sub](animation/engines/sub.md) | Pure Elm; full control (stop, reset, restart, pause, resume), looping, real-time mid-flight queries/diversions |
| [WAAPI](animation/engines/waapi.md) | Browser-native performance via JS; full control (stop, reset, restart, pause, resume), looping, real-time mid-flight queries/diversions |
| [Scroll Timeline](animation/engines/scroll-timeline.md) | Browser-native performance via JS; scroll-driven, tied to a container's scroll progress |
| [View Timeline](animation/engines/view-timeline.md) | Browser-native performance via JS; viewport-driven, tied to an element entering and leaving view |

### Scroll

| Engine | Key Features |
| -------- | ---------- |
| [Cmd](scroll/engines/cmd.md) | Simple fire-and-forget scrolls, minimal setup |
| [Task](scroll/engines/task.md) | Composable scrolling with typed error handling |
| [Sub](scroll/engines/sub.md) | Stateful scrolling with full control, events, and mid-scroll queries |

## Next Steps

Learn why Elm Motion exists and what it's trying to solve.

[Philosophy →](philosophy.md){ .md-button .md-button--primary }

Or, jump right in and get started.

[Installation →](installation.md){ .md-button .md-button--primary }

## 📚 API Reference

For detailed API documentation, see the official Elm package docs:

[View on elm-lang.org →](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/){ .md-button }
