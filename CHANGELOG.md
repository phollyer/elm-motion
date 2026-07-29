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

## [1.0.3] - 2026-07-29 (npm)

Initial release of the `@phollyer/elm-motion` JavaScript companion. The in-repo version starts at `1.0.3`; earlier `1.0.x` numbers were used during pre-release preparation and never published.

### Added

- `ElmMotion.init(ports)` driving the WAAPI, ScrollTimeline and ViewTimeline engines through the `motionCmd` / `motionMsg` port pair.
- Reduced-motion support: animations honour `prefers-reduced-motion: reduce` by snapping to their end state while still firing lifecycle events, with `ElmMotion.setReducedMotion('auto' | 'always' | 'never')` to override the policy. See [Accessibility](docs/shared/accessibility.md).
- Bundled `scroll-timeline-polyfill` (Apache-2.0), with third-party license attribution generated to `dist/THIRD-PARTY-LICENSES.md`.
- ESM (`elm-motion.mjs`) and standalone browser (IIFE, global `ElmMotion`, `elm-motion.js`) builds, plus TypeScript definitions (`elm-motion.d.ts`), all shipped in `dist/`.
- `engines` field (`node >= 18`) declared on the published package.

