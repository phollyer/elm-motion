module Anim.Engine.Shared.UnitMatrix exposing (UnitCase, all)

import Anim.Unit as Unit


type alias UnitCase =
    { name : String
    , unit : Unit.Unit
    , css : String
    }


all : List UnitCase
all =
    [ unitCase "Cap" Unit.Cap "cap"
    , unitCase "Ch" Unit.Ch "ch"
    , unitCase "Cm" Unit.Cm "cm"
    , unitCase "Cqb" Unit.Cqb "cqb"
    , unitCase "Cqh" Unit.Cqh "cqh"
    , unitCase "Cqi" Unit.Cqi "cqi"
    , unitCase "Cqmax" Unit.Cqmax "cqmax"
    , unitCase "Cqmin" Unit.Cqmin "cqmin"
    , unitCase "Cqw" Unit.Cqw "cqw"
    , unitCase "Dvb" Unit.Dvb "dvb"
    , unitCase "Dvh" Unit.Dvh "dvh"
    , unitCase "Dvi" Unit.Dvi "dvi"
    , unitCase "Dvmax" Unit.Dvmax "dvmax"
    , unitCase "Dvmin" Unit.Dvmin "dvmin"
    , unitCase "Dvw" Unit.Dvw "dvw"
    , unitCase "Em" Unit.Em "em"
    , unitCase "Ex" Unit.Ex "ex"
    , unitCase "Ic" Unit.Ic "ic"
    , unitCase "In" Unit.In "in"
    , unitCase "Lh" Unit.Lh "lh"
    , unitCase "Lvb" Unit.Lvb "lvb"
    , unitCase "Lvh" Unit.Lvh "lvh"
    , unitCase "Lvi" Unit.Lvi "lvi"
    , unitCase "Lvmax" Unit.Lvmax "lvmax"
    , unitCase "Lvmin" Unit.Lvmin "lvmin"
    , unitCase "Lvw" Unit.Lvw "lvw"
    , unitCase "Mm" Unit.Mm "mm"
    , unitCase "Pc" Unit.Pc "pc"
    , unitCase "Percent" Unit.Percent "%"
    , unitCase "Pt" Unit.Pt "pt"
    , unitCase "Px" Unit.Px "px"
    , unitCase "Q" Unit.Q "Q"
    , unitCase "Rcap" Unit.Rcap "rcap"
    , unitCase "Rch" Unit.Rch "rch"
    , unitCase "Rem" Unit.Rem "rem"
    , unitCase "Rex" Unit.Rex "rex"
    , unitCase "Ric" Unit.Ric "ric"
    , unitCase "Rlh" Unit.Rlh "rlh"
    , unitCase "Svb" Unit.Svb "svb"
    , unitCase "Svh" Unit.Svh "svh"
    , unitCase "Svi" Unit.Svi "svi"
    , unitCase "Svmax" Unit.Svmax "svmax"
    , unitCase "Svmin" Unit.Svmin "svmin"
    , unitCase "Svw" Unit.Svw "svw"
    , unitCase "Vb" Unit.Vb "vb"
    , unitCase "Vh" Unit.Vh "vh"
    , unitCase "Vi" Unit.Vi "vi"
    , unitCase "Vmax" Unit.Vmax "vmax"
    , unitCase "Vmin" Unit.Vmin "vmin"
    , unitCase "Vw" Unit.Vw "vw"
    , unitCase "Unitless" Unit.Unitless ""
    ]


unitCase : String -> Unit.Unit -> String -> UnitCase
unitCase name unit css =
    { name = name
    , unit = unit
    , css = css
    }
