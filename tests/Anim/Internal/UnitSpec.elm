module Anim.Internal.UnitSpec exposing (suite)

{-| Verifies that every `Anim.Unit.Unit` constructor maps to the correct CSS
suffix string. The mapping is what every Engine relies on to render
length-bearing transform values, so a regression here silently corrupts every
animation that uses a non-default unit.
-}

import Anim.Internal.Unit as InternalUnit
import Anim.Unit as Unit
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Internal.Unit.toCssSuffix"
        [ suffixTest "Px maps to px" Unit.Px "px"
        , suffixTest "Percent maps to %" Unit.Percent "%"
        , suffixTest "Vw maps to vw" Unit.Vw "vw"
        , suffixTest "Vh maps to vh" Unit.Vh "vh"
        , suffixTest "Dvw maps to dvw" Unit.Dvw "dvw"
        , suffixTest "Dvh maps to dvh" Unit.Dvh "dvh"
        , suffixTest "Svw maps to svw" Unit.Svw "svw"
        , suffixTest "Svh maps to svh" Unit.Svh "svh"
        , suffixTest "Lvw maps to lvw" Unit.Lvw "lvw"
        , suffixTest "Lvh maps to lvh" Unit.Lvh "lvh"
        , suffixTest "Rem maps to rem" Unit.Rem "rem"
        , suffixTest "Em maps to em" Unit.Em "em"
        , suffixTest "Cqi maps to cqi" Unit.Cqi "cqi"
        , suffixTest "Cqb maps to cqb" Unit.Cqb "cqb"
        , suffixTest "Cqw maps to cqw" Unit.Cqw "cqw"
        , suffixTest "Cqh maps to cqh" Unit.Cqh "cqh"
        , suffixTest "Cqmin maps to cqmin" Unit.Cqmin "cqmin"
        , suffixTest "Cqmax maps to cqmax" Unit.Cqmax "cqmax"
        ]


suffixTest : String -> Unit.Unit -> String -> Test
suffixTest description unit expected =
    test description <|
        \_ ->
            InternalUnit.toCssSuffix unit
                |> Expect.equal expected
