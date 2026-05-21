module Anim.Unit exposing
    ( Unit(..)
    , toCssSuffix
    )

{-| Length unit selector for length-bearing properties
([Translate](Anim.Property.Translate), [Size](Anim.Property.Size),
[PerspectiveOrigin](Anim.Property.PerspectiveOrigin),
[Custom](Anim.Property.Custom)).

The default is `Px`, which preserves the original pixel-only behaviour.
Setting a relative unit on an Engine, group, or property makes the browser
re-evaluate the rendered values against current layout - the animation follows
resize automatically without needing [Resize.bounds](Anim.Resize#bounds) plumbing.

The Engines reach for the unit in this order, taking the first one set:

1.  Property-level (`Translate.cssUnit`, `Size.cssUnit`, `PerspectiveOrigin.cssUnit`)
2.  Engine-level (`WAAPI.cssUnit`, `Transition.cssUnit`, `Keyframe.cssUnit`,
    `ScrollTimeline.cssUnit`, `ViewTimeline.cssUnit`)
3.  `Px` (built-in default)

The `Sub` Engine currently only supports `Px`. Setting a non-`Px` unit on a
property targeted at `Sub` reports an error and falls back to `Px` for that
animation. Support for relative units on `Sub` is planned for a future release.


# Choosing a unit

  - **Viewport-anchored UI** (full-screen drawers, edge-pinned banners,
    100vh splash screens) - use `Vh`/`Vw`. For mobile-correct behaviour where
    the URL bar collapses, prefer `Dvh`/`Dvw` (dynamic), `Svh`/`Svw` (small,
    URL bar visible) or `Lvh`/`Lvw` (large, URL bar hidden).

  - **Container-anchored UI** (animations inside a card, panel, modal body,
    sidebar, list item) - use the container-query units `Cqi`/`Cqb` (inline /
    block, the recommended defaults) or `Cqw`/`Cqh` (width / height). The
    nearest ancestor must declare `container-type: inline-size` (for
    `Cqi`/`Cqb`) or `container-type: size` (for `Cqw`/`Cqh`/`Cqmin`/`Cqmax`).
    Without a qualifying container, the browser falls back to viewport units,
    which silently masks bugs - declare the container explicitly.

  - **Element-relative** (sliding the element by a fraction of its own size) -
    use `Percent`. Note that for `transform: translate`, percentages resolve
    against the moving element's own box, not its parent.

  - **Font-relative** (animations that should scale with text size) - use
    `Rem` (root font size) or `Em` (element's own font size).


# Type

@docs Unit


# Render

@docs toCssSuffix

-}


{-| The length unit applied when rendering length-bearing values.

**Absolute**

  - `Px` - CSS pixels. The default.

**Element- and font-relative**

  - `Percent` - Percentage of the containing block (or the element's own box,
    for `translate`).
  - `Rem` - Font size of the root element.
  - `Em` - Font size of the element.

**Viewport-relative**

  - `Vw` / `Vh` - 1% of the viewport's width / height.
  - `Dvw` / `Dvh` - Dynamic viewport: tracks URL-bar collapse on mobile.
  - `Svw` / `Svh` - Small viewport: assumes UI chrome is visible.
  - `Lvw` / `Lvh` - Large viewport: assumes UI chrome is hidden.

**Container-relative** (require an ancestor with `container-type` set)

  - `Cqi` / `Cqb` - 1% of the query container's inline / block size.
    Recommended; only requires `container-type: inline-size`.
  - `Cqw` / `Cqh` - 1% of the query container's width / height. Require
    `container-type: size`, which forces the container to ignore intrinsic
    sizing in both axes.
  - `Cqmin` / `Cqmax` - 1% of the smaller / larger of the container's two
    axes. Require `container-type: size`.

-}
type Unit
    = Px
    | Percent
    | Vw
    | Vh
    | Dvw
    | Dvh
    | Svw
    | Svh
    | Lvw
    | Lvh
    | Rem
    | Em
    | Cqi
    | Cqb
    | Cqw
    | Cqh
    | Cqmin
    | Cqmax


{-| Render a `Unit` as the matching CSS unit suffix string.

    toCssSuffix Px == "px"

    toCssSuffix Percent == "%"

    toCssSuffix Cqh == "cqh"

Useful when feeding a typed `Unit` into APIs that take a free-form CSS unit
string, such as the `Custom` escape hatch in [Anim.Property.Custom](Anim.Property.Custom).

-}
toCssSuffix : Unit -> String
toCssSuffix unit =
    case unit of
        Px ->
            "px"

        Percent ->
            "%"

        Vw ->
            "vw"

        Vh ->
            "vh"

        Dvw ->
            "dvw"

        Dvh ->
            "dvh"

        Svw ->
            "svw"

        Svh ->
            "svh"

        Lvw ->
            "lvw"

        Lvh ->
            "lvh"

        Rem ->
            "rem"

        Em ->
            "em"

        Cqi ->
            "cqi"

        Cqb ->
            "cqb"

        Cqw ->
            "cqw"

        Cqh ->
            "cqh"

        Cqmin ->
            "cqmin"

        Cqmax ->
            "cqmax"
