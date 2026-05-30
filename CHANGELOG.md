# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

---

## [1.0.0] - 2026-05-30

Initial release of `phollyer/elm-motion`.

### Animation

- **Transition Engine** — Browser-native CSS transitions; quick setup for simple A→B animations with minimal setup
- **Keyframe Engine** — Browser-native `@keyframes`; looping, full playback control
- **Sub Engine** — Pure Elm, frame-by-frame via subscriptions; looping, real-time mid-flight queries and diversions
- **WAAPI Engine** — Web Animations API via JavaScript ports; looping, full control, real-time mid-flight queries and diversions
- **ScrollTimeline Engine** — Scroll-driven animations tied to a scroll container's progress, via WAAPI
- **ViewTimeline Engine** — Viewport-driven animations tied to an element entering and leaving view, via WAAPI

### Scroll

- **Cmd Engine** — Fire-and-forget scrolling with minimal setup
- **Task Engine** — Composable scrolling with typed error handling
- **Sub Engine** — Stateful scrolling with full control, events, and mid-scroll queries

### Properties

- `Translate` — X, Y, Z translation (GPU accelerated)
- `Rotate` — Single-axis and 3D rotation (GPU accelerated)
- `Scale` — X, Y, Z scaling (GPU accelerated)
- `Skew` — X and Y skew
- `Opacity` — Opacity (GPU accelerated)
- `PerspectiveOrigin` — Perspective origin for 3D scenes
- `Size` — Width and height
- `Custom` — Arbitrary CSS property animations
- `CustomColor` — Arbitrary CSS color property animations

### Motion

- **`Motion.Easing`** — easing functions for animations and scrolls (`Linear`, `Ease`, `EaseIn/Out/InOut`, full Sine/Quad/Cubic/Quart/Quint/Expo/Circ/Back/Elastic/Bounce families, and `CubicBezier`). Standard `BounceIn/Out/InOut`, `ElasticIn/Out/InOut`, and the full `BackIn/Out/InOut` + `BackIn/Out/InOutCustom` set are included.
- **`Motion.Spring`** — physics-based spring primitive with presets (`gentle`, `wobbly`, `stiff`, `slow`, `noWobble`) and a `custom` builder. Springs derive their settle time from physics rather than a user-specified duration, and produce natural overshoot and oscillation. Spring and easing are mutually exclusive — setting one clears the other.
- Per-property `spring` setter on every property module (`Opacity`, `Translate`, `Rotate`, `Scale`, `Skew`, `Size`, `PerspectiveOrigin`, `Custom`, `CustomColor`).
- Engine-level `spring` setter on every animation engine (`Transition`, `Keyframe`, `Sub`, `WAAPI`, `ScrollTimeline`, `ViewTimeline`).

### Units

- **`Anim.Unit`** — shared length-unit selector covering `Px`, `Percent`, viewport units (`Vw`, `Vh`, `Dvw`, `Dvh`, `Svw`, `Svh`, `Lvw`, `Lvh`), font-relative units (`Rem`, `Em`), and container-query units (`Cqi`, `Cqb`, `Cqw`, `Cqh`, `Cqmin`, `Cqmax`) for length-bearing properties. On every engine the unit is rendered verbatim, so relative units let the browser re-evaluate values against current layout on every frame — animations follow resize automatically. Default is `Px`.
- `Anim.Unit.toCssSuffix : Unit -> String` for bridging a typed `Unit` into the `Anim.Property.Custom.Custom` String escape hatch.
- Per-property `cssUnit : Unit -> Builder -> Builder` setter on `Anim.Property.Translate`, `Anim.Property.Size`, and `Anim.Property.PerspectiveOrigin`.
- Per-axis `Unit` overrides on `Anim.Property.Translate` (`cssUnitX`, `cssUnitY`, `cssUnitZ`), `Anim.Property.Size` (`cssUnitWidth`, `cssUnitHeight`), and `Anim.Property.PerspectiveOrigin` (`cssUnitX`, `cssUnitY`). Each axis falls back to the property-level `cssUnit` (then engine default, then `Px`), so mixed-unit animations like `translate3d(50%, 100px, 0px)` are first-class.
- Engine-level `cssUnit : Unit -> Builder -> Builder` setter on `Anim.Engine.Transition`, `Anim.Engine.Keyframe`, `Anim.Engine.WAAPI`, `Anim.Engine.ScrollTimeline`, and `Anim.Engine.ViewTimeline`. Resolution order: property override → engine default → `Px`.

### Events

- `Anim.Engine.Keyframe.AnimEvent.Run` — fires the moment a keyframe animation is applied, before any configured delay. Mirrors the native `animationrun` event and the existing `Anim.Engine.Transition.AnimEvent.Run`. `Started` continues to fire after the delay, matching the browser's `animationstart`.

### Runtime

- `Anim.Engine.WAAPI.setUpdateThrottle : Int -> AnimState msg -> Cmd msg` — cap the rate of per-frame `propertyUpdate` events sent from the JS runtime to Elm. Equivalent to `ElmMotion.setPropertyUpdateThrottle(ms)` from JavaScript: pass `0` to disable throttling (default, one event per `requestAnimationFrame` tick), or a positive number of milliseconds (e.g. `16` for ~60 Hz, `33` for ~30 Hz). Setting is global to the JS runtime and shared across all WAAPI animations; visual animation is never affected.

### Other

- Composable builder API — define animations once, run on any engine
- Full 3D support — XYZ positioning, multi-axis rotation, perspective
- Easing functions via `elm-community/easing-functions`
- JavaScript companion package `@phollyer/elm-motion` (npm `1.0.0`) for WAAPI integration
- TypeScript definitions for the WAAPI companion
- Resize is proportional: endpoints adopt new bounds, the current value keeps its relative position, and normalized progress is preserved so timing stays in phase
