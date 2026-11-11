# Elm Motion

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

(See also [important note](#important-note-with-an-apology) at the end)

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
        >> Transition.duration 600
        >> fadeIn

Keyframe.animate model.animState <|
    Keyframe.for "entrance"
        >> Keyframe.duration 600
        >> fadeIn

Sub.animate model.animState <|
    Sub.for "entrance"
        >> Sub.duration 600
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

The companion carries its own version — the current `1.x` companion works with any `1.x` or `2.x` Elm package.

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

---

## Important Note - with an apology

### A bit of history

I started working on this package at the start of October 2025, writing and designing it by hand, with very little LLM involvement. This was while I was full-time carer for my mother, she had dementia then full blown Alzheimers. She always stated that she never wanted to go into a nursing home, so looking after her became my job around early 2021.

In December of 2025 she passed away, and I entered into the most stressful time of my life. The bungalow we lived in had been left to my mum to live in rent free until she passed away, and then it was to go to the family of the previous owner for them to sell. They required me to vacate the property by July 1st 2026.

Due to not having worked for many years while looking after mum, I was unable to obtain a rental property to live in, and because I didn't fight the family who were now selling the property, the council would not help me either.

This meant that from July 1st 2026 I was going to be homeless.

### The Apology

As a result of looking like being made homeless, with my mental state being all over the place, I started vibe coding this package around April 2026 I think, with minimal oversight. I wanted to get it released before I ended up living on the street.

The result of the vibe coding was something that 'worked' but was not production ready and I shouldn't have released the package when I did. Unfortunately, at the time, I needed something good in my life, and Elm and this package had given me something to focus on during those very hard times. I shouldn't have vibe coded, and I sincerely apologise to anyone that may have invested their time into using/trying the package and been burned as a result.

### From there to here

I ended up in a rundown hostel type of place for down and outs for a couple of weeks before being rescued by my Step-Aunt. I stayed with her for a couple of weeks, then my brother flew me out to Australia to live with him and his wife and kids.

I am now trying to stay in Australia permanently. My head has been in a much better place, and I have gone back to hand coding the package myself, using LLM for only simple, time saving biolerplate type work, which is then carefully reviewed.

I have started to re-write the tests myself (see [tests/Specs](https://github.com/phollyer/elm-motion/tree/main/tests/Specs)). They are in a structure that will allow me to test multiple engines with a single set of test data for each scenario being tested. Currently the Specs test the Transition and Keyframe engines, more engines will be added. Multiple bugs and design flaws have been fixed. I have also cleaned up some of the library code, with much more work to do there.

It looks like it will be some time before I obtain permission to work in Australia, so I have lots of time to myself. I am, however, spending much of that time now on another project that can provide me with an income. This project does use elm-motion extensively, and so far the Transition engine is working wonderfully.

I will try to keep moving elm-motion forward by spending a couple of days a week on it, and will post updates on [Discourse](https://discourse.elm-lang.org/) as and when there is something to update, but as I do not have permission to work in Australia, and do not know when that may happen, I need to focus on my other project primarily which will offer me an income stream when completed.

### And Finally

If you do want to try the package out, I would recommend the Transition and Keyframe engines for animation, and the Scroll engines have been working fine when I have used them.

If you do try it, I would appreciate any feedback you have.

Thank you for reading this far, and I look forward to gradually improving the package until it is fully production ready.

