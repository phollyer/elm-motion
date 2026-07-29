# Elm Motion

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

[![Sponsor phollyer](https://img.shields.io/badge/%F0%9F%92%96%20Sponsor-phollyer-ea4aaa?style=for-the-badge)](https://github.com/sponsors/phollyer)

## 👀 At a Glance

- **6 Animation Engines** — Transition, Keyframe, Sub, WAAPI, ScrollTimeline, ViewTimeline
- **3 Scroll Engines** — Cmd, Task, Sub
- **Three timelines, one API** — drive animations by time, scroll progress or viewport position
- **Mid-flight control** — query, divert, pause, resume, restart and stop animations and scrolls in motion
- **Hardware-accelerated** — GPU transforms with full 3D support
- **Type Safe** — only the capabilities an engine actually supports compile against it

---

## 🚦 Engines at a Glance

### **Animation**

- **Transition** — Browser-native performance; quick setup for simple A→B animations, minimal control (stop, reset)
- **Keyframe** — Browser-native performance; full control (stop, reset, restart, pause, resume), looping
- **Sub** — Pure Elm; full control (stop, reset, restart, pause, resume), looping, real-time mid-flight queries/diversions
- **WAAPI** — Browser-native performance via JS; full control (stop, reset, restart, pause, resume), looping, real-time mid-flight queries/diversions
- **ScrollTimeline** — Browser-native performance via JS; scroll-driven, tied to a container's scroll progress
- **ViewTimeline** — Browser-native performance via JS; viewport-driven, tied to an element entering and leaving view

### **Scroll**

- **Cmd** — Simple fire-and-forget scrolls, minimal setup
- **Task** — Composable scrolling with typed error handling
- **Sub** — Stateful scrolling with full control, events, and mid-scroll queries

---

## 🎯 Why Elm Motion?

**One API. Multiple Engines.**

Elm Motion gives you a consistent builder API for configuring animations and scrolls across
multiple Engines.

Define your animations once, then run them with any Engine.

```elm
-- Define once
fadeIn : AnimBuilder eng -> AnimBuilder eng
fadeIn =
    Opacity.begin
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.end

-- Use with any Engine
Transition.animate model.animState <|
    Transition.for "entranceAnim"
        >> fadeIn

Keyframe.animate model.animState <|
    Keyframe.for "entranceAnim"
        >> fadeIn

Sub.animate model.animState <|
    Sub.for "entranceAnim"
        >> fadeIn

WAAPI.animate model.animState <|
    WAAPI.for "entranceAnim"
        >> fadeIn

ScrollTimeline.animate motionCmd Document <|
    ScrollTimeline.for "entranceAnim"
        >> fadeIn

ViewTimeline.animate motionCmd <|
    ViewTimeline.for "entranceAnim"
        >> fadeIn
```

### Composability

The builder API makes animations and their building blocks composable, so you
can easily build animations from smaller pieces.

```elm
-- Standard timing for all animations
standardTiming : AnimBuilder eng -> AnimBuilder eng 
standardTiming =
    Transition.duration 300
        >> Transition.easing QuadOut

-- Define animations
fadeIn : AnimBuilder eng -> AnimBuilder eng
fadeIn =
    Opacity.begin
        >> Opacity.to 1
        >> Opacity.end

slideIn : AnimBuilder eng -> AnimBuilder eng
slideIn =
    Translate.begin
        >> Translate.toX 0
        >> Translate.end

-- Compose together
Transition.animate model.animState <|
    Transition.for "headerEntranceAnim"
        >> standardTiming
        >> fadeIn
        >> slideIn

```

The same philosophy applies to scrolling — define once, use with any Scroll Engine.

```elm
-- Define once
scrollToSection : ScrollBuilder -> ScrollBuilder
scrollToSection =
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.speed 500
        >> Scroll.build

-- Use with any Scroll Engine
Cmd.scroll ScrollDone scrollToSection

Task.scroll scrollToSection

Sub.scroll ScrollMsg model.scrollState scrollToSection
```

---

## ✨ Features

### Animation Features

- **Hardware-Accelerated** — GPU-powered transforms (translate, rotate, scale, skew, opacity)
- **Full 3D Support** — XYZ positioning, multi-axis rotation, perspective
- **Multi-Property Animations** — Animate multiple properties on the same element simultaneously, each with independent timing and easing — no master timeline to orchestrate
- **Time, Scroll & Viewport Driven** — Drive animations by elapsed time, page scroll progress or an element's position in the viewport — same builder API, three different timelines

### Scroll Features

- **Smooth Scrolling** — Document and container
- **Flexible Targets** — Scroll to elements, percentages, edges, corners, or relative deltas
- **Axis Control** — Scroll horizontally, vertically or both

---

## 🚀 Quick Start

```bash
elm install phollyer/elm-motion
```

### Your First Animation

```elm
import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Property.Opacity as Opacity
import Process
import Task

-- 1. Initialize state, then trigger the fade once the header has painted at opacity 0
type alias Model =
    { animState : Transition.AnimState }

init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init <|
                [ Opacity.init "headerAnim" 0 ]
      }
    , Process.sleep 0
        |> Task.perform (always Animate)
    )


-- 2. Define your animation
fadeInHeader : AnimBuilder eng -> AnimBuilder eng
fadeInHeader =
    Opacity.begin
        >> Opacity.to 1
        >> Opacity.end



-- 3. Trigger it
type Msg
    = Animate

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model | animState = 
                Transition.animate model.animState <|
                    Transition.for "headerAnim"
                        >> Transition.duration 400
                        >> fadeInHeader
              }
            , Cmd.none
            )


-- 4. Render
view : Model -> Html Msg
view model =
    Html.div
        (Transition.attributes "headerAnim" model.animState)
        [ Html.text "Animated header with logo and nav" ]
```

### Your First Scroll

```elm
import Scroll.Builder as Scroll
import Scroll.Engine.Cmd as Cmd exposing (ScrollBuilder)


-- 1. Define your scroll
scrollToSection : String -> ScrollBuilder -> ScrollBuilder
scrollToSection targetId =
    Scroll.forDocument
        >> Scroll.toElement targetId
        >> Scroll.speed 400
        >> Scroll.build


-- 2. Trigger it
type Msg
    = ScrollTo String
    | ScrollComplete

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo targetId ->
            ( model
            , Cmd.scroll ScrollComplete <|
                scrollToSection targetId
            )

        ScrollComplete ->
            ( model, Cmd.none )


-- 3. Render
view : Model -> Html Msg
view _ =
    -- Your scrollable content
```

---

## 🧩 JavaScript Companion

The `WAAPI`, `ScrollTimeline` and `ViewTimeline` engines require the
[`@phollyer/elm-motion`](https://www.npmjs.com/package/@phollyer/elm-motion)
JavaScript companion.

```bash
npm install @phollyer/elm-motion
```

The companion carries its own version number, separate from the Elm package -
any `1.x` companion works with any `1.x` Elm package.

See the [npm package README](https://www.npmjs.com/package/@phollyer/elm-motion)
for setup, port wiring and error reporting.

---

## 📚 Documentation

Full documentation at **[phollyer.github.io/elm-motion](https://phollyer.github.io/elm-motion)**

- Getting started guide
- Engine deep-dives
- Property reference (Translate, Rotate, Scale, etc)
- Live examples with source code

---

## 📋 Roadmap — in no particular order or timeframe

- CSS Transitions - potentially bake complex easings, and maybe springs, into the css `linear` easing function
- FLIP Engine
- Canvas Engine
- WebGL Engine
- Any other user suggested features
- Dedicated website similar to motion.dev for React

---

## 💖 Sponsor

Elm Motion is free and open source, built and maintained in my own time. If it helps you or your team, please consider [sponsoring my work on GitHub](https://github.com/sponsors/phollyer) - it directly supports the ongoing development of elm-motion and my other Elm packages. You can sponsor monthly or make a one-time donation of any amount.

[![Sponsor phollyer](https://img.shields.io/badge/%F0%9F%92%96%20Sponsor-phollyer-ea4aaa?style=for-the-badge)](https://github.com/sponsors/phollyer)

Company and Corporate sponsors are featured below. Individual backers and fans are listed in [SPONSORS.md](https://github.com/phollyer/elm-motion/blob/main/SPONSORS.md). Thank you to everyone who helps keep this work going. 💖

**Corporate Sponsors**

_Your logo here — [become a Corporate Sponsor](https://github.com/sponsors/phollyer)._

**Company Sponsors**

_Your logo here — [become a Company Sponsor](https://github.com/sponsors/phollyer)._

---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/).

The JavaScript companion bundles [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) (Apache-2.0).

---

## 📄 License

BSD-3-Clause
