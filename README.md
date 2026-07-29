# Elm Motion

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## ✨ Highlights

- **6 animation engines + 3 scroll engines — one builder API**
- **Define once, run with any engine** — swap engines without rewriting your animations
- **Three timelines, one API** — drive motion by time, scroll progress or viewport position
- **Mid-flight control** — query, divert, pause, resume, restart and stop motion in flight
- **Hardware-accelerated** — GPU transforms with full 3D support
- **Composable** — build animations from small, reusable builder pieces
- **Type-safe** — only the capabilities an engine actually supports compile against it
- **Reduced-motion aware** — the WAAPI-based engines honour `prefers-reduced-motion: reduce`

---

## 🎯 One API, many engines

Define an animation once, then run it with any engine — no rewrites:

```elm
fadeIn : AnimBuilder eng -> AnimBuilder eng
fadeIn =
    Opacity.begin 
        >> Opacity.from 0 
        >> Opacity.to 1 
        >> Opacity.end

Transition.animate model.animState <|
    Transition.for "entrance" 
        >> fadeIn

Keyframe.animate model.animState <|
    Keyframe.for "entrance"
        >> fadeIn

Sub.animate model.animState <|
    Sub.for "entrance"
        >> fadeIn

-- … and WAAPI, ScrollTimeline and ViewTimeline take the same definition
```

Scrolling follows the same define-once philosophy across the `Cmd`, `Task` and `Sub` scroll engines.

---

## 🚦 Engines

### Animation

- **Transition** — Browser-native; simple A→B, minimal control (stop, reset)
- **Keyframe** — Browser-native; full control, looping
- **Sub** — Pure Elm; full control, looping, real-time mid-flight queries/diversions
- **WAAPI** — Native via JS; full control, looping, real-time mid-flight queries/diversions
- **ScrollTimeline** — Native via JS; scroll-driven, tied to a container's scroll progress
- **ViewTimeline** — Native via JS; viewport-driven, tied to an element entering/leaving view

### Scroll

- **Cmd** — Fire-and-forget, minimal setup
- **Task** — Composable, with typed error handling
- **Sub** — Stateful, with events and mid-scroll queries

---

## 🚀 Install

```bash
elm install phollyer/elm-motion
```

The `WAAPI`, `ScrollTimeline` and `ViewTimeline` engines also need the JavaScript companion:

```bash
npm install @phollyer/elm-motion
```

The companion carries its own version — any `1.x` companion works with any `1.x` Elm package.

---

## 📚 Getting started

Step-by-step guides for your first animation and first scroll live in the docs:

- **[Your first animation](https://phollyer.github.io/elm-motion/animation/start-here/)**
- **[Your first scroll](https://phollyer.github.io/elm-motion/scroll/start-here/)**
- **[Engine overview](https://phollyer.github.io/elm-motion/animation/engines/overview/)**

Full documentation, property reference and live examples: **[phollyer.github.io/elm-motion](https://phollyer.github.io/elm-motion)**

---

## 🧩 JavaScript companion

See the [npm package README](https://www.npmjs.com/package/@phollyer/elm-motion) for setup, port wiring and error reporting.

---

## 📋 Roadmap — in no particular order or timeframe

- CSS Transitions — potentially bake complex easings, and maybe springs, into the CSS `linear` easing function
- FLIP Engine
- Canvas Engine
- WebGL Engine
- Any other user-suggested features
- Dedicated website similar to motion.dev for React

---

## 💖 Sponsor

Elm Motion is free and open source, built in my own time. If it helps you or your team, please consider [sponsoring on GitHub](https://github.com/sponsors/phollyer) — monthly or a one-time amount. It directly supports ongoing development.

---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/).

The JavaScript companion bundles [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) (Apache-2.0).

---

## 📄 License

BSD-3-Clause
