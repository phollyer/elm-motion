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
        , suffixTest "Cm maps to cm" Unit.Cm "cm"
        , suffixTest "Mm maps to mm" Unit.Mm "mm"
        , suffixTest "Q maps to Q" Unit.Q "Q"
        , suffixTest "In maps to in" Unit.In "in"
        , suffixTest "Pt maps to pt" Unit.Pt "pt"
        , suffixTest "Pc maps to pc" Unit.Pc "pc"
        , suffixTest "Percent maps to %" Unit.Percent "%"
        , suffixTest "Cap maps to cap" Unit.Cap "cap"
        , suffixTest "Ch maps to ch" Unit.Ch "ch"
        , suffixTest "Ex maps to ex" Unit.Ex "ex"
        , suffixTest "Ic maps to ic" Unit.Ic "ic"
        , suffixTest "Lh maps to lh" Unit.Lh "lh"
        , suffixTest "Vw maps to vw" Unit.Vw "vw"
        , suffixTest "Vh maps to vh" Unit.Vh "vh"
        , suffixTest "Vi maps to vi" Unit.Vi "vi"
        , suffixTest "Vb maps to vb" Unit.Vb "vb"
        , suffixTest "Vmin maps to vmin" Unit.Vmin "vmin"
        , suffixTest "Vmax maps to vmax" Unit.Vmax "vmax"
        , suffixTest "Dvw maps to dvw" Unit.Dvw "dvw"
        , suffixTest "Dvh maps to dvh" Unit.Dvh "dvh"
        , suffixTest "Dvi maps to dvi" Unit.Dvi "dvi"
        , suffixTest "Dvb maps to dvb" Unit.Dvb "dvb"
        , suffixTest "Dvmin maps to dvmin" Unit.Dvmin "dvmin"
        , suffixTest "Dvmax maps to dvmax" Unit.Dvmax "dvmax"
        , suffixTest "Svw maps to svw" Unit.Svw "svw"
        , suffixTest "Svh maps to svh" Unit.Svh "svh"
        , suffixTest "Svi maps to svi" Unit.Svi "svi"
        , suffixTest "Svb maps to svb" Unit.Svb "svb"
        , suffixTest "Svmin maps to svmin" Unit.Svmin "svmin"
        , suffixTest "Svmax maps to svmax" Unit.Svmax "svmax"
        , suffixTest "Lvw maps to lvw" Unit.Lvw "lvw"
        , suffixTest "Lvh maps to lvh" Unit.Lvh "lvh"
        , suffixTest "Lvi maps to lvi" Unit.Lvi "lvi"
        , suffixTest "Lvb maps to lvb" Unit.Lvb "lvb"
        , suffixTest "Lvmin maps to lvmin" Unit.Lvmin "lvmin"
        , suffixTest "Lvmax maps to lvmax" Unit.Lvmax "lvmax"
        , suffixTest "Rem maps to rem" Unit.Rem "rem"
        , suffixTest "Em maps to em" Unit.Em "em"
        , suffixTest "Rcap maps to rcap" Unit.Rcap "rcap"
        , suffixTest "Rch maps to rch" Unit.Rch "rch"
        , suffixTest "Rex maps to rex" Unit.Rex "rex"
        , suffixTest "Ric maps to ric" Unit.Ric "ric"
        , suffixTest "Rlh maps to rlh" Unit.Rlh "rlh"
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
