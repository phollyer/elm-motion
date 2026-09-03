# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## Versioning

Elm Motion ships as **two independently versioned artifacts**:

- The **Elm package** on [package.elm-lang.org](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/) follows the version in `elm.json`.
- The **JavaScript companion** on [npm](https://www.npmjs.com/package/@phollyer/elm-motion) (`@phollyer/elm-motion`) follows the version in `package.json`.

The two version lines are **not kept in lockstep**. The npm companion can ship JavaScript-only fixes without a matching Elm release, and the Elm package can evolve without a companion change. Entries below are tagged with the artifact they affect: **(elm)**, **(npm)**, **(docs)**, or **(tooling)**.

---

## [Unreleased]

### Fixed

**(elm)** Discrete Properties: depending on where the user positioned the `discreteEntry` and `discreteExit` functions in their builder chain, the Transition engine may not always render the exit state correctly. This now fixed internally.

### Added

**(docs)** Clarify the Transition engine requires event listeners to be set up in order to handle discrete properties correctly.

Nothing

## [3.0.2] - 2026-09-01 (elm)

**(docs)** Fixed all examples that were failing to build due to the API changes in the 3.0.0 release.

## [3.0.1] - 2026-09-01 (elm)

### Fixed

**(tooling)** Removed leftover `EasingSpec` test cases for `BackInCustom`, `BackOutCustom` and `BackInOutCustom`, which were deleted from the public API in 3.0.0 but not fully removed from the test suite.

## [3.0.0] - 2026-09-01 (elm)

### Removed

**(elm)** Remove unsupported easings `BackInCustom`, `BackOutCustom` and `BackInOutCustom`.

### Added

**(elm)** Add `initCssUnit*` group of functions to the `PerspectiveOrigin`, `Size` and `Translate` properties. Improve their docs.

### Changed

**(elm)** Changed the type annotations for the `cssUnit*` group of functions for the `PerspectiveOrigin`, `Size` and `Translate` properties, (`AnimBuilder eng` becomes a property specific `Builder eng`). This forces/enables the functions to be used inside the property builder chain, rather than outside. This is a breaking change, but makes their use clearer and more intuitive.

## [2.1.4] - 2026-08-08 (elm)

### Fixed

**(elm)** Changing CSS Unit's across the same animation group with new animations now persists the new Unit correctly. This is an internal fix, no public facing modules are affected. Behaviour changes, but now behaves as expected.

## [2.1.3] - 2026-08-05 (elm)

Documentation-only patch release - no API changes.

### Fixed

- **(docs)** Fixed incorrect code examples across five public modules:
  - `Anim.Engine.Keyframe`: `events` and `eventsStopPropagation` examples showed a spurious `String` first argument that does not exist in the actual `(AnimMsg -> msg) -> List (Html.Attribute msg)` signature.
  - `Anim.Engine.Transition`: same spurious-argument fix for `events`/`eventsStopPropagation`; `cssUnit`, `cssUnitX`, `cssUnitY`, `cssUnitZ`, `cssUnitWidth`, `cssUnitHeight`, `delay`, `duration`, and `speed` examples annotated helper functions as `AnimBuilder { eng | with... }` instead of `EngineBuilder`.
  - `Anim.Engine.ScrollTimeline`: `spring`, `cssUnit`, `cssUnitX`, `cssUnitY`, and `cssUnitZ` examples had the same stale `AnimBuilder { eng | with... }` annotation instead of `EngineBuilder`.
  - `Anim.Engine.ViewTimeline`: same five functions as ScrollTimeline.
  - `Anim.Property.Custom`: the module-level Clamping section example called `Custom.begin Px)` — `Px` is a `Unit`, not a `Property`, there was a stray `)`, and the `>> Custom.to size` step was missing.

## [2.1.2] - 2026-08-03 (elm)

### Fixed

- **(elm)** Per-animation playback settings (`iterations`, `loopForever`, `alternate`) set at global builder scope no longer leak into the next `animate` call. Previously, once an animation completed, a follow-up animation on the same group that specified no playback of its own inherited the prior iteration count and alternating direction. Playback is now reset between `animate` calls. Group-scoped playback (set after `for`) was never affected. The fix lives in the shared builder, so every engine benefits.

## [2.1.1] - 2026-08-01 (elm)

### Removed

- **(elm)** Internal cleanup: removed the unused, duplicate `TimelineBuilder` type alias from the internal engine modules (`CSS`, `Keyframe`, `Transition`, `WAAPI`, `Sub`), consolidating on the equivalent `AnimBuilder`. No public API change — these modules are not exposed.

### Fixed

- **(docs)** Corrected the doc-comment examples for the engine-specialized setters (delay, duration, speed, easing, spring, cssUnit*) in the Sub, Keyframe, WAAPI, Transition, ScrollTimeline and ViewTimeline modules, which annotated the helper functions as the too-general AnimBuilder eng -> AnimBuilder eng instead of the engine-specialized EngineBuilder -> EngineBuilder.


## [2.1.0] - 2026-07-31 (elm)

### Added

- **(elm)** `Anim.Engine.Sub`: new timing queries `getDuration`, `getElapsed` and `getRemaining`, each `AnimGroupName -> AnimState -> Maybe Int`. They report per-iteration wall-clock milliseconds for a named group - `getDuration` is the longest `delay + duration` across the group's properties, `getElapsed` is the time elapsed within the current iteration (clamped to the duration), and `getRemaining` is the difference (clamped at `0`). Values include delay and reset each iteration, complementing the existing `getProgress`.

- **(docs)** Add timing (duration) to example code in README so that the examples match real world use.

## [2.0.0] - 2026-07-30 (elm)

Major release - a single breaking type-signature change to `Anim.Builder`.

### Changed

- **(elm)** `Anim.Builder.easing` is now `Easing -> AnimBuilder eng -> AnimBuilder eng`, dropping the previous `{ eng | withEasing : () }` capability constraint. That constraint required a `withEasing` row field that no engine capability record declares, so the engine-agnostic setter could not be applied to any concrete engine builder. Easing is supported by every engine, so no capability gating is warranted. Elm's type-based versioning classifies this as major, but in practice it only widens what already compiled and needs no changes at existing call sites.
- **(docs)** Version-compatibility notes (README, npm README and installation guide) now state that the current `1.x` JavaScript companion works with any `1.x` or `2.x` Elm package. The `2.0.0` bump is an Elm-only type-signature change with no change to the `motionCmd` / `motionMsg` port protocol, so companion compatibility is unaffected.

### Fixed

- **(docs)** Corrected the `easing` doc-comment examples in `Anim.Builder` and the `Transition`, `ScrollTimeline` and `ViewTimeline` engine modules, which showed the invalid `{ eng | withEasing : () }` signature.

## [1.0.3][1.0.3-elm] - 2026-07-29 (elm)

Documentation-only patch release - no API changes.

### Changed

- **(docs)** README: streamlined for the package landing page - consolidated the capability lists, kept a single "one API, many engines" example, moved the full first-animation and first-scroll walkthroughs to the documentation site, and slimmed the sponsor section.

## [1.0.2] - 2026-07-29 (elm)

Bug-fix patch release - no API changes.

### Fixed

- **(elm)** `Anim.Extra.Color`: three-character shorthand hex strings are now expanded correctly. `hex "#f00"` previously decoded to `{ r = 240, g = 0, b = 0 }`; it now returns `{ r = 255, g = 0, b = 0 }`.
- **(elm)** `Anim.Extra.Color`: `toRgba` now preserves the alpha channel of eight-character hex strings. `hex "#ff000080" |> toRgba` previously reported `a = 1`; it now returns `a ≈ 0.502`.

## [1.0.1] - 2026-07-29 (elm)

Documentation-only patch release - no API changes.

### Fixed

- **(docs)** README: corrected the `SPONSORS.md` link to an absolute GitHub URL so it resolves on package.elm-lang.org.
- **(docs)** Changelog: corrected the companion build-format note (the companion ships ESM and a browser global, not CommonJS).

## [1.0.0] - 2026-07-29 (elm)

Initial public release.

### Added

- Six animation engines sharing a single, consistent builder API:
  - `Anim.Engine.Transition` - CSS transitions, minimal setup.
  - `Anim.Engine.Keyframe` - CSS keyframes with looping and full control.
  - `Anim.Engine.Sub` - pure Elm, frame-based, with real-time queries.
  - `Anim.Engine.WAAPI` - Web Animations API via the JavaScript companion.
  - `Anim.Engine.ScrollTimeline` - scroll-driven animation via the companion.
  - `Anim.Engine.ViewTimeline` - viewport-driven animation via the companion.
- Three scroll engines: `Scroll.Engine.Cmd` (fire-and-forget), `Scroll.Engine.Task` (composable with error handling) and `Scroll.Engine.Sub` (stateful, with mid-scroll queries).
- Property modules under `Anim.Property.*`: `Opacity`, `Translate`, `Rotate`, `Scale`, `Skew`, `Size`, `PerspectiveOrigin`, `Custom` (any numeric CSS property with a unit) and `CustomColor` (any color CSS property).
- Builders and helpers: `Anim.Builder`, `Scroll.Builder` and `Anim.Unit`.
- Motion helpers: `Motion.Spring` and `Motion.Easing`.
- Extras: `Anim.Extra.Color`, `Anim.Extra.TransformOrder` and `Anim.Extra.View3D`.

## [1.0.3][1.0.3-npm] - 2026-07-29 (npm)

Initial release of the `@phollyer/elm-motion` JavaScript companion. The in-repo version starts at `1.0.3`; earlier `1.0.x` numbers were used during pre-release preparation and never published.

### Added

- `ElmMotion.init(ports)` driving the WAAPI, ScrollTimeline and ViewTimeline engines through the `motionCmd` / `motionMsg` port pair.
- Reduced-motion support: animations honour `prefers-reduced-motion: reduce` by snapping to their end state while still firing lifecycle events, with `ElmMotion.setReducedMotion('auto' | 'always' | 'never')` to override the policy. See [Accessibility](docs/shared/accessibility.md).
- Bundled `scroll-timeline-polyfill` (Apache-2.0), with third-party license attribution generated to `dist/THIRD-PARTY-LICENSES.md`.
- ESM (`elm-motion.mjs`) and standalone browser (IIFE, global `ElmMotion`, `elm-motion.js`) builds, plus TypeScript definitions (`elm-motion.d.ts`), all shipped in `dist/`.
- `engines` field (`node >= 18`) declared on the published package.

[3.0.2]: https://github.com/phollyer/elm-motion/compare/3.0.2...3.0.1
[3.0.1]: https://github.com/phollyer/elm-motion/compare/3.0.1...3.0.0
[3.0.0]: https://github.com/phollyer/elm-motion/compare/3.0.0...2.1.4
[2.1.4]: https://github.com/phollyer/elm-motion/compare/2.1.3...2.1.4
[2.1.3]: https://github.com/phollyer/elm-motion/compare/2.1.2...2.1.3
[2.1.2]: https://github.com/phollyer/elm-motion/compare/2.1.1...2.1.2
[2.1.1]: https://github.com/phollyer/elm-motion/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/phollyer/elm-motion/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/phollyer/elm-motion/compare/1.0.3...2.0.0
[1.0.3-elm]: https://github.com/phollyer/elm-motion/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/phollyer/elm-motion/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/phollyer/elm-motion/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/phollyer/elm-motion/releases/tag/1.0.0
[1.0.3-npm]: https://www.npmjs.com/package/@phollyer/elm-motion/v/1.0.3

