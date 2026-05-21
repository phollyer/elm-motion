module Anim.Internal.Unit exposing
    ( LengthAxes
    , ResolvedLengthAxes
    , default
    , emptyLengthAxes
    , resolveLengthAxes
    , setAllLengthAxes
    , setLengthX
    , setLengthY
    , setLengthZ
    , toCssSuffix
    )

{-| Internal re-exports for `Anim.Unit`. The implementation lives in the
public `Anim.Unit` module; this module exists so internal callers can keep
their `import Anim.Internal.Unit as InternalUnit` aliases without coupling
to the public API surface.

`LengthAxes` is the unresolved per-axis unit override carried through the
builder pipeline. `ResolvedLengthAxes` is the resolved record stored on a
`ProcessedAnimationConfig` after defaults and global overrides are merged.

-}

import Anim.Unit as Unit exposing (Unit)


default : Unit
default =
    Unit.Px


toCssSuffix : Unit -> String
toCssSuffix =
    Unit.toCssSuffix


type alias LengthAxes =
    { x : Maybe Unit
    , y : Maybe Unit
    , z : Maybe Unit
    }


type alias ResolvedLengthAxes =
    { x : Unit
    , y : Unit
    , z : Unit
    }


emptyLengthAxes : LengthAxes
emptyLengthAxes =
    { x = Nothing, y = Nothing, z = Nothing }


setAllLengthAxes : Unit -> LengthAxes -> LengthAxes
setAllLengthAxes unit _ =
    { x = Just unit, y = Just unit, z = Just unit }


setLengthX : Unit -> LengthAxes -> LengthAxes
setLengthX unit axes =
    { axes | x = Just unit }


setLengthY : Unit -> LengthAxes -> LengthAxes
setLengthY unit axes =
    { axes | y = Just unit }


setLengthZ : Unit -> LengthAxes -> LengthAxes
setLengthZ unit axes =
    { axes | z = Just unit }


{-| Merge per-axis local overrides over global overrides, falling back to
the property's scalar default if neither is set on a given axis.
-}
resolveLengthAxes : LengthAxes -> LengthAxes -> Unit -> ResolvedLengthAxes
resolveLengthAxes local global default_ =
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
