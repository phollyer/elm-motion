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

### Added

- **(npm)** Reduced-motion support for the WAAPI, ScrollTimeline and ViewTimeline Engines: animations honour `prefers-reduced-motion: reduce` by snapping to their end state while still firing lifecycle events. Adds `ElmMotion.setReducedMotion('auto' | 'always' | 'never')` to override the policy. See [Accessibility](docs/shared/accessibility.md).
- **(npm)** Third-party license attribution: the build now generates `dist/THIRD-PARTY-LICENSES.md` carrying the Apache-2.0 notice for the bundled `scroll-timeline-polyfill`.
- **(npm)** `engines` field (`node >= 18`) declared on the published package.
- **(tooling)** Tag-triggered (`npm-v*`) release workflow that publishes the companion to npm with build provenance.
- **(tooling)** Dependency-audit gate in CI (blocking on high/critical advisories in shipped dependencies).
- **(docs)** Accessibility guide covering reduced-motion behaviour and the `setReducedMotion` API.
- Pre-release tag policy for unpublished Elm package testing.
- Git tag checkpoints using `vX.Y.Z-alpha.N` for tester pinning and behind-check workflows.

### Changed

- **(docs)** Documented previously-missing exposed modules in the API reference (`Scroll.Builder`, `Anim.Property.PerspectiveOrigin`, `Anim.Unit`, `Anim.Extra.TransformOrder`) and clarified in the README that `WAAPI.animate` returns `( AnimState, Cmd msg )` and the timeline Engines take extra trigger arguments.
- Bumped the JavaScript companion package version in-repo to `1.0.3` for npm release preparation.
- Clarified release policy: Elm package remains unpublished until first package.elm-lang.org release.

