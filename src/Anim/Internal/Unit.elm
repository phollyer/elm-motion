module Anim.Internal.Unit exposing
    ( default
    , toCssSuffix
    )

{-| Internal helpers for `Anim.Unit.Unit`.
-}

import Anim.Unit exposing (Unit(..))


default : Unit
default =
    Px


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
