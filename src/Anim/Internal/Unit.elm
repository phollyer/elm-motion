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

{-| Internal re-exports for `Anim.Unit`. The implementation lives in the
public `Anim.Unit` module; this module exists so internal callers can keep
their `import Anim.Internal.Unit as InternalUnit` aliases without coupling
to the public API surface.

`CssUnitAxes` is the unresolved per-axis unit override carried through the
builder pipeline. `ResolvedCssUnitAxes` is the resolved record stored on a
`ProcessedAnimationConfig` after defaults and global overrides are merged.

-}

import Anim.Unit as Unit exposing (Unit)


default : Unit
default =
    Unit.Px


toCssSuffix : Unit -> String
toCssSuffix =
    Unit.toCssSuffix


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
