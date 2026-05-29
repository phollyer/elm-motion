# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

- **`Anim.Engine.WAAPI.setUpdateThrottle : Int -> AnimState msg -> Cmd msg`** — cap the rate of per-frame `propertyUpdate` events sent from the JS runtime to Elm, directly from Elm. Equivalent to calling `ElmMotion.setPropertyUpdateThrottle(ms)` from JavaScript: pass `0` to disable throttling (default, one event per `requestAnimationFrame` tick), or a positive number of milliseconds (e.g. `16` for ~60 Hz, `33` for ~30 Hz) to cap the rate. Setting is global to the JS runtime and shared across all WAAPI animations. The visual animation is never affected. Wired through a new `setUpdateThrottle` motionCmd command type.
- **`Anim.Engine.Keyframe.AnimEvent.Run`** — fires the moment a keyframe animation is applied, before any configured delay. Mirrors the native `animationrun` event and the existing `Anim.Engine.Transition.AnimEvent.Run`. `Started` continues to fire after the delay, matching the browser's `animationstart`. `events` and `eventsStopPropagation` now wire the additional `animationrun` listener.
- **`Anim.Unit`** — shared length-unit selector covering `Px`, `Percent`, viewport units (`Vw`, `Vh`, `Dvw`, `Dvh`, `Svw`, `Svh`, `Lvw`, `Lvh`), font-relative units (`Rem`, `Em`), and container-query units (`Cqi`, `Cqb`, `Cqw`, `Cqh`, `Cqmin`, `Cqmax`) for length-bearing properties. On CSS Transition, Keyframe, WAAPI, ScrollTimeline, and ViewTimeline engines the unit is rendered verbatim, so relative units let the browser re-evaluate values against current layout on every frame — animations follow resize automatically without `Resize.bounds` plumbing. Default remains `Px`.
- `Anim.Unit.toCssSuffix : Unit -> String` — exposed so callers can bridge a typed `Unit` into the `Anim.Property.Custom.Custom` String escape hatch.
- Per-property `cssUnit : Unit -> Builder -> Builder` setter on `Anim.Property.Translate`, `Anim.Property.Size`, and `Anim.Property.PerspectiveOrigin`.
- Per-axis `Unit` overrides on `Anim.Property.Translate` (`cssUnitX`, `cssUnitY`, `cssUnitZ`), `Anim.Property.Size` (`cssUnitWidth`, `cssUnitHeight`), and `Anim.Property.PerspectiveOrigin` (`cssUnitX`, `cssUnitY`). Each axis falls back to the property-level `cssUnit` (then engine default, then `Px`), so mixed-unit animations like `translate3d(50%, 100px, 0px)` are first-class. The WAAPI wire format now emits per-axis `unitX`/`unitY`/`unitZ` (translate), `unitWidth`/`unitHeight` (size), and `unitX`/`unitY` (perspectiveOrigin); the JS companion renders each axis independently in keyframes and `parseTransformString` recovers per-axis units from inline styles.
- Engine-level `cssUnit : Unit -> Builder -> Builder` setter on `Anim.Engine.Transition`, `Anim.Engine.Keyframe`, `Anim.Engine.WAAPI`, `Anim.Engine.ScrollTimeline`, and `Anim.Engine.ViewTimeline`. Resolution order: property override → engine default → `Px`.
- **`Motion.Spring`** — physics-based spring primitive with presets (`gentle`, `wobbly`, `stiff`, `slow`, `noWobble`) and a `custom` builder. Springs derive their settle time from physics rather than a user-specified duration, and produce natural overshoot and oscillation.
- Per-property `spring` setter on every property module (`Opacity`, `Translate`, `Rotate`, `Scale`, `Skew`, `Size`, `PerspectiveOrigin`, `Custom`, `CustomColor`).
- Engine-level `spring` setter on every animation engine (`Transition`, `Keyframe`, `Sub`, `WAAPI`, `ScrollTimeline`, `ViewTimeline`). Spring and easing are mutually exclusive — setting one clears the other.

### Changed

- **BREAKING — `Anim.Property.Custom.Property`** — length-typed constructors (`BorderRadius`, `BorderTopLeftRadius`, `BorderTopRightRadius`, `BorderBottomLeftRadius`, `BorderBottomRightRadius`, `BorderWidth`, `BorderTopWidth`, `BorderRightWidth`, `BorderBottomWidth`, `BorderLeftWidth`, `Bottom`, `ColumnGap`, `ColumnWidth`, `FontSize`, `Gap`, `Inset`, `Left`, `LetterSpacing`, `Margin`, `MarginTop`, `MarginRight`, `MarginBottom`, `MarginLeft`, `MaxHeight`, `MaxWidth`, `MinHeight`, `MinWidth`, `OutlineOffset`, `OutlineWidth`, `Padding`, `PaddingTop`, `PaddingRight`, `PaddingBottom`, `PaddingLeft`, `Perspective`, `Right`, `RowGap`, `TextIndent`, `Top`, `WordSpacing`, `FlexBasis`) now take `Anim.Unit.Unit` instead of `String`. Migration: `Custom.Property.BorderRadius "px"` → `Custom.Property.BorderRadius Anim.Unit.Px`. The `LineHeight`, `TabSize`, and `Custom` constructors keep `String` (they support unitless values and exotic units outside the `Unit` vocabulary).
- **BREAKING — `Anim.Property.Custom.CssUnit`** — type alias removed. Length-typed constructors now use `Anim.Unit.Unit` (above); the `Custom String String` escape hatch still accepts any unit string and can be fed via `Anim.Unit.toCssSuffix` when typed values are preferred.
- WAAPI `size` payload now carries `unitWidth`/`unitHeight` fields reflecting `Size.cssUnitWidth`/`Size.cssUnitHeight` (or `Size.cssUnit` as the per-axis fallback), and the JS companion renders `width`/`height` keyframes with each configured unit independently instead of hard-coded `px`. Existing call sites that don't set a unit continue to render in `px` on both axes.
- **Renamed `Easing` → `Motion.Easing`** to bring it under the same `Motion.*` namespace as `Motion.Spring`. Callers must update `import Easing` to `import Motion.Easing` (or `import Motion.Easing as Easing` to keep qualified references unchanged).
- `Shared.Easing.toFunction` no longer takes a `durationMs` parameter; it was only used by the now-removed Custom/Advanced bounce/elastic keyframe sampling. Engine call sites updated accordingly.

### Removed

- **`Anim.Property.PerspectiveOrigin.px` and `Anim.Property.PerspectiveOrigin.percent`** — the bespoke unit selectors on `PerspectiveOrigin` are replaced by the shared `Anim.Property.PerspectiveOrigin.cssUnit : Anim.Unit.Unit -> Builder -> Builder` cascade. Callers using `PerspectiveOrigin.percent` should switch to `PerspectiveOrigin.cssUnit Anim.Unit.Percent` (or set it engine-wide via `WAAPI.cssUnit`, etc.). The internal `PerspectiveOrigin` variant no longer carries its own `Unit` type.
- **Resize policy API collapsed to proportional-only.** Removed `Anim.Resize.Policy`, `Anim.Resize.policy`, `Anim.Resize.clamp`, `Anim.Resize.retarget`, `Anim.Resize.proportional`, `Anim.Resize.withTiming`, `Anim.Resize.SolveFromCurrent`, `Anim.Resize.PreserveProgress`, and the per-property `resizePolicy` helpers on every property module. Resize now always remaps proportionally: endpoints adopt the new bounds, the current value keeps its relative position, and normalized progress is preserved so timing stays in phase. The internal `authoredStart` / `authoredEnd` fields and clamp/retarget code paths were removed accordingly.
- **`BounceInCustom`, `BounceOutCustom`, `BounceInOutCustom`** — Custom bounce variants. Use `Motion.Spring` for tunable overshoot, or the standard `BounceIn` / `BounceOut` / `BounceInOut` for the algebraic curve.
- **`BounceInAdvanced`, `BounceOutAdvanced`, `BounceInOutAdvanced`** — same rationale.
- **`ElasticInCustom`, `ElasticOutCustom`, `ElasticInOutCustom`** — Custom elastic variants. Use `Motion.Spring` for tunable oscillation.
- **`ElasticInAdvanced`, `ElasticOutAdvanced`, `ElasticInOutAdvanced`** — same rationale.
- `Shared.Easing.Physics` module and the `transitionFractionOf` re-export — only the removed variants needed the physics-derived ratio; surviving easings always returned `1.0`.
- Internal `keyframeBased` helper and the bulk of `Shared.Easing.Keyframes` (~800 lines of physics simulation, transition stitching, velocity-matching, and parameter-derivation helpers).

### Preserved unchanged

- Standard `BounceIn`, `BounceOut`, `BounceInOut`.
- Standard `ElasticIn`, `ElasticOut`, `ElasticInOut`.
- All `BackIn`, `BackOut`, `BackInOut`, `BackInCustom`, `BackOutCustom`, `BackInOutCustom`.
- All Cubic/Quad/Quart/Quint/Sine/Expo/Circ/Ease/Linear/CubicBezier easings.

---

## [1.0.0] - 2026-04-28

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

### Other

- Composable builder API — define animations once, run on any engine
- Full 3D support — XYZ positioning, multi-axis rotation, perspective
- Easing functions via `elm-community/easing-functions`
- JavaScript companion package `@phollyer/elm-motion` (npm `1.0.0`) for WAAPI integration
- TypeScript definitions for the WAAPI companion
