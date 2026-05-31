module Anim.Internal.Unit exposing
    ( CssUnitAxes
    , ResolvedCssUnitAxes
    , default
    , emptyCssUnitAxes
    , resolveCssUnitAxes
    , setAllCssUnitAxes
    , setCssUnitX
    , setCssUnitY
    , setCssUnitZ
    , toCssSuffix
    )

{-| Internal unit helpers.

`CssUnitAxes` is the unresolved per-axis unit override carried through the
builder pipeline. `ResolvedCssUnitAxes` is the resolved record stored on a
`ProcessedAnimationConfig` after defaults and global overrides are merged.

-}

import Anim.Unit as Unit exposing (Unit(..))



-- ============================================================
-- RE-EXPORTS
-- ============================================================


default : Unit
default =
    Unit.Px


toCssSuffix : Unit -> String
toCssSuffix unit =
    case unit of
        Cap ->
            "cap"

        Ch ->
            "ch"

        Cm ->
            "cm"

        Cqb ->
            "cqb"

        Cqh ->
            "cqh"

        Cqi ->
            "cqi"

        Cqmax ->
            "cqmax"

        Cqmin ->
            "cqmin"

        Cqw ->
            "cqw"

        Dvb ->
            "dvb"

        Dvh ->
            "dvh"

        Dvi ->
            "dvi"

        Dvmax ->
            "dvmax"

        Dvmin ->
            "dvmin"

        Dvw ->
            "dvw"

        Em ->
            "em"

        Ex ->
            "ex"

        Ic ->
            "ic"

        In ->
            "in"

        Lh ->
            "lh"

        Lvb ->
            "lvb"

        Lvh ->
            "lvh"

        Lvi ->
            "lvi"

        Lvmax ->
            "lvmax"

        Lvmin ->
            "lvmin"

        Lvw ->
            "lvw"

        Mm ->
            "mm"

        Pc ->
            "pc"

        Percent ->
            "%"

        Pt ->
            "pt"

        Px ->
            "px"

        Q ->
            "Q"

        Rcap ->
            "rcap"

        Rch ->
            "rch"

        Rem ->
            "rem"

        Rex ->
            "rex"

        Ric ->
            "ric"

        Rlh ->
            "rlh"

        Svb ->
            "svb"

        Svh ->
            "svh"

        Svi ->
            "svi"

        Svmax ->
            "svmax"

        Svmin ->
            "svmin"

        Svw ->
            "svw"

        Vb ->
            "vb"

        Vh ->
            "vh"

        Vi ->
            "vi"

        Vmax ->
            "vmax"

        Vmin ->
            "vmin"

        Vw ->
            "vw"



-- ============================================================
-- TYPES
-- ============================================================


type alias CssUnitAxes =
    { x : Maybe Unit
    , y : Maybe Unit
    , z : Maybe Unit
    }


type alias ResolvedCssUnitAxes =
    { x : Unit
    , y : Unit
    , z : Unit
    }



-- ============================================================
-- BUILD
-- ============================================================


emptyCssUnitAxes : CssUnitAxes
emptyCssUnitAxes =
    { x = Nothing, y = Nothing, z = Nothing }


setAllCssUnitAxes : Unit -> CssUnitAxes -> CssUnitAxes
setAllCssUnitAxes unit _ =
    { x = Just unit, y = Just unit, z = Just unit }


setCssUnitX : Unit -> CssUnitAxes -> CssUnitAxes
setCssUnitX unit axes =
    { axes | x = Just unit }


setCssUnitY : Unit -> CssUnitAxes -> CssUnitAxes
setCssUnitY unit axes =
    { axes | y = Just unit }


setCssUnitZ : Unit -> CssUnitAxes -> CssUnitAxes
setCssUnitZ unit axes =
    { axes | z = Just unit }



-- ============================================================
-- RESOLVE
-- ============================================================


{-| Merge per-axis local overrides over global overrides, falling back to
the property's scalar default if neither is set on a given axis.
-}
resolveCssUnitAxes : CssUnitAxes -> CssUnitAxes -> Unit -> ResolvedCssUnitAxes
resolveCssUnitAxes local global default_ =
    { x = pickAxis local.x global.x default_
    , y = pickAxis local.y global.y default_
    , z = pickAxis local.z global.z default_
    }


pickAxis : Maybe Unit -> Maybe Unit -> Unit -> Unit
pickAxis local global default_ =
    case local of
        Just unit ->
            unit

        Nothing ->
            case global of
                Just unit ->
                    unit

                Nothing ->
                    default_
