module Anim.Unit exposing
    ( Unit(..)
    , toCssSuffix
    )

{-| Length unit for length-bearing properties
([Translate](Anim.Property.Translate), [Size](Anim.Property.Size),
[PerspectiveOrigin](Anim.Property.PerspectiveOrigin),
[Custom](Anim.Property.Custom)).

The default is `Px`. Switching to a relative unit (`Percent`, `Vw`, `Vh`,
`Cqw`, `Cqh`, `Rem`, `Em`, etc.) makes the browser re-evaluate the animation
against current layout, so the animation follows window or container resize
automatically - no [Resize.bounds](Anim.Resize#bounds) plumbing needed.

You can set the unit per-property (`Translate.cssUnit`, `Size.cssUnit`,
`PerspectiveOrigin.cssUnit`) or globally on an Engine (`WAAPI.cssUnit`,
`Transition.cssUnit`, etc.). Property-level settings win over Engine-level ones.

The `Sub` Engine only supports `Px`. Setting a non-`Px` unit on a property
animated by `Sub` falls back to `Px` and reports an error.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for full per-engine behaviour.


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

-- ============================================================
-- TYPES
-- ============================================================


{-| The length unit applied when rendering length-bearing values.

**Absolute**

  - `Px` - CSS pixels. The default.

**Element- and font-relative**

  - `Percent` - Percentage of the containing block (or the element's own box,
    for `translate`).
      - `Cap` / `Ch` / `Ex` / `Ic` / `Lh` - Font-relative CSS lengths.
  - `Rem` - Font size of the root element.
  - `Em` - Font size of the element.
      - `Rcap` / `Rch` / `Rex` / `Ric` / `Rlh` - Root-font-relative CSS lengths.

**Viewport-relative**

  - `Vw` / `Vh` - 1% of the viewport's width / height.
      - `Vi` / `Vb` - 1% of the viewport's inline / block axes.
      - `Vmin` / `Vmax` - 1% of the viewport's smaller / larger axis.
  - `Dvw` / `Dvh` - Dynamic viewport: tracks URL-bar collapse on mobile.
      - `Dvi` / `Dvb` - Dynamic viewport inline / block axes.
      - `Dvmin` / `Dvmax` - Dynamic viewport smaller / larger axis.
  - `Svw` / `Svh` - Small viewport: assumes UI chrome is visible.
      - `Svi` / `Svb` - Small viewport inline / block axes.
      - `Svmin` / `Svmax` - Small viewport smaller / larger axis.
  - `Lvw` / `Lvh` - Large viewport: assumes UI chrome is hidden.
      - `Lvi` / `Lvb` - Large viewport inline / block axes.
      - `Lvmin` / `Lvmax` - Large viewport smaller / larger axis.

**Physical absolute**

    - `Cm` / `Mm` / `Q` / `In` / `Pt` / `Pc` - CSS physical length units.

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
    | Cm
    | Mm
    | Q
    | In
    | Pt
    | Pc
    | Percent
    | Cap
    | Ch
    | Ex
    | Ic
    | Lh
    | Vw
    | Vh
    | Vi
    | Vb
    | Vmin
    | Vmax
    | Dvw
    | Dvh
    | Dvi
    | Dvb
    | Dvmin
    | Dvmax
    | Svw
    | Svh
    | Svi
    | Svb
    | Svmin
    | Svmax
    | Lvw
    | Lvh
    | Lvi
    | Lvb
    | Lvmin
    | Lvmax
    | Rem
    | Em
    | Rcap
    | Rch
    | Rex
    | Ric
    | Rlh
    | Cqi
    | Cqb
    | Cqw
    | Cqh
    | Cqmin
    | Cqmax



-- ============================================================
-- RENDER
-- ============================================================


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

        Cm ->
            "cm"

        Mm ->
            "mm"

        Q ->
            "Q"

        In ->
            "in"

        Pt ->
            "pt"

        Pc ->
            "pc"

        Percent ->
            "%"

        Cap ->
            "cap"

        Ch ->
            "ch"

        Ex ->
            "ex"

        Ic ->
            "ic"

        Lh ->
            "lh"

        Vw ->
            "vw"

        Vh ->
            "vh"

        Vi ->
            "vi"

        Vb ->
            "vb"

        Vmin ->
            "vmin"

        Vmax ->
            "vmax"

        Dvw ->
            "dvw"

        Dvh ->
            "dvh"

        Dvi ->
            "dvi"

        Dvb ->
            "dvb"

        Dvmin ->
            "dvmin"

        Dvmax ->
            "dvmax"

        Svw ->
            "svw"

        Svh ->
            "svh"

        Svi ->
            "svi"

        Svb ->
            "svb"

        Svmin ->
            "svmin"

        Svmax ->
            "svmax"

        Lvw ->
            "lvw"

        Lvh ->
            "lvh"

        Lvi ->
            "lvi"

        Lvb ->
            "lvb"

        Lvmin ->
            "lvmin"

        Lvmax ->
            "lvmax"

        Rem ->
            "rem"

        Em ->
            "em"

        Rcap ->
            "rcap"

        Rch ->
            "rch"

        Rex ->
            "rex"

        Ric ->
            "ric"

        Rlh ->
            "rlh"

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
