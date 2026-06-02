module Anim.Unit exposing (Unit(..))

{-| Length unit for length-bearing properties
([Translate](Anim.Property.Translate), [Size](Anim.Property.Size),
[PerspectiveOrigin](Anim.Property.PerspectiveOrigin),
[Custom](Anim.Property.Custom)).

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for full per-engine behaviour.


# Type

@docs Unit

-}

-- ============================================================
-- TYPES
-- ============================================================


{-| The length unit applied when rendering length-bearing values.
-}
type Unit
    = Cap
    | Ch
    | Cm
    | Cqb
    | Cqh
    | Cqi
    | Cqmax
    | Cqmin
    | Cqw
    | Dvb
    | Dvh
    | Dvi
    | Dvmax
    | Dvmin
    | Dvw
    | Em
    | Ex
    | Ic
    | In
    | Lh
    | Lvb
    | Lvh
    | Lvi
    | Lvmax
    | Lvmin
    | Lvw
    | Mm
    | Pc
    | Percent
    | Pt
    | Px
    | Q
    | Rcap
    | Rch
    | Rem
    | Rex
    | Ric
    | Rlh
    | Svb
    | Svh
    | Svi
    | Svmax
    | Svmin
    | Svw
    | Vb
    | Vh
    | Vi
    | Vmax
    | Vmin
    | Vw
    | Unitless
