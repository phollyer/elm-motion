module Anim.Internal.Unit exposing
    ( default
    , toCssSuffix
    )

{-| Internal re-exports for `Anim.Unit`. The implementation lives in the
public `Anim.Unit` module; this module exists so internal callers can keep
their `import Anim.Internal.Unit as InternalUnit` aliases without coupling
to the public API surface.
-}

import Anim.Unit as Unit exposing (Unit)


default : Unit
default =
    Unit.Px


toCssSuffix : Unit -> String
toCssSuffix =
    Unit.toCssSuffix
