module Anim.Internal.Property.TestTranslate exposing (suite)

import Anim.Internal.Property.Translate as Translate
import Anim.Unit as Unit
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.Translate"
        [ construction
        , accessors
        , conversions
        , distanceMeasure
        , interpolation
        , cssOutput
        ]



-- CONSTRUCTION


construction : Test
construction =
    describe "Construction"
        [ test "default is origin" <|
            \_ ->
                Translate.default
                    |> Translate.toTriple
                    |> Expect.equal ( 0, 0, 0 )
        , test "fromTriple sets all axes" <|
            \_ ->
                Translate.fromTriple ( 1, 2, 3 )
                    |> Translate.toTriple
                    |> Expect.equal ( 1, 2, 3 )
        , test "fromRecord sets all axes" <|
            \_ ->
                Translate.fromRecord { x = 5, y = 10, z = 15 }
                    |> Translate.toTriple
                    |> Expect.equal ( 5, 10, 15 )
        ]



-- ACCESSORS


accessors : Test
accessors =
    describe "Accessors"
        [ test "x returns x component" <|
            \_ ->
                Translate.fromTriple ( 7, 0, 0 )
                    |> Translate.getX
                    |> Expect.equal 7
        , test "y returns y component" <|
            \_ ->
                Translate.fromTriple ( 0, 8, 0 )
                    |> Translate.getY
                    |> Expect.equal 8
        , test "z returns z component" <|
            \_ ->
                Translate.fromTriple ( 0, 0, 9 )
                    |> Translate.getZ
                    |> Expect.equal 9
        ]



-- CONVERSIONS


conversions : Test
conversions =
    describe "Conversions"
        [ test "toRecord preserves all axes" <|
            \_ ->
                Translate.fromTriple ( 4, 5, 6 )
                    |> Translate.toRecord
                    |> Expect.equal { x = 4, y = 5, z = 6 }
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "Distance (Chebyshev)"
        [ test "same point has zero distance" <|
            \_ ->
                Translate.distance
                    (Translate.fromTriple ( 5, 5, 5 ))
                    (Translate.fromTriple ( 5, 5, 5 ))
                    |> Expect.equal 0
        , test "uses max axis difference" <|
            \_ ->
                Translate.distance
                    (Translate.fromTriple ( 0, 0, 0 ))
                    (Translate.fromTriple ( 3, 7, 5 ))
                    |> Expect.equal 7
        , test "is symmetric" <|
            \_ ->
                let
                    a =
                        Translate.fromTriple ( 1, 2, 3 )

                    b =
                        Translate.fromTriple ( 10, 20, 30 )
                in
                Expect.equal
                    (Translate.distance a b)
                    (Translate.distance b a)
        , test "negative values use absolute difference" <|
            \_ ->
                Translate.distance
                    (Translate.fromTriple ( -10, 0, 0 ))
                    (Translate.fromTriple ( 10, 0, 0 ))
                    |> Expect.equal 20
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "Interpolation"
        [ test "t=0 returns start" <|
            \_ ->
                Translate.interpolate 0
                    (Translate.fromTriple ( 0, 0, 0 ))
                    (Translate.fromTriple ( 100, 200, 300 ))
                    |> Translate.toTriple
                    |> Expect.equal ( 0, 0, 0 )
        , test "t=1 returns end" <|
            \_ ->
                Translate.interpolate 1
                    (Translate.fromTriple ( 0, 0, 0 ))
                    (Translate.fromTriple ( 100, 200, 300 ))
                    |> Translate.toTriple
                    |> Expect.equal ( 100, 200, 300 )
        , test "t=0.5 returns midpoint" <|
            \_ ->
                Translate.interpolate 0.5
                    (Translate.fromTriple ( 0, 0, 0 ))
                    (Translate.fromTriple ( 100, 200, 300 ))
                    |> Translate.toTriple
                    |> Expect.equal ( 50, 100, 150 )
        , test "same start and end returns that value" <|
            \_ ->
                Translate.interpolate 0.5
                    (Translate.fromTriple ( 42, 42, 42 ))
                    (Translate.fromTriple ( 42, 42, 42 ))
                    |> Translate.toTriple
                    |> Expect.equal ( 42, 42, 42 )
        ]



-- CSS OUTPUT


cssOutput : Test
cssOutput =
    describe "CSS Output"
        [ test "toCssString produces translate3d" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssString { x = Unit.Px, y = Unit.Px, z = Unit.Px }
                    |> Expect.equal "translate3d(10px, 20px, 0px)"
        , test "toCssPropertyValue produces space-separated values" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssPropertyValue { x = Unit.Px, y = Unit.Px, z = Unit.Px }
                    |> Expect.equal "10px 20px 0px"
        , test "default produces zero translate3d" <|
            \_ ->
                Translate.default
                    |> Translate.toCssString { x = Unit.Px, y = Unit.Px, z = Unit.Px }
                    |> Expect.equal "translate3d(0px, 0px, 0px)"
        , test "toCssString renders Percent unit suffix" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssString { x = Unit.Percent, y = Unit.Percent, z = Unit.Percent }
                    |> Expect.equal "translate3d(10%, 20%, 0%)"
        , test "toCssString renders Vw unit suffix" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssString { x = Unit.Vw, y = Unit.Vw, z = Unit.Vw }
                    |> Expect.equal "translate3d(10vw, 20vw, 0vw)"
        , test "toCssString renders Vh unit suffix" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssString { x = Unit.Vh, y = Unit.Vh, z = Unit.Vh }
                    |> Expect.equal "translate3d(10vh, 20vh, 0vh)"
        , test "toCssString renders Rem unit suffix" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssString { x = Unit.Rem, y = Unit.Rem, z = Unit.Rem }
                    |> Expect.equal "translate3d(10rem, 20rem, 0rem)"
        , test "toCssString renders Em unit suffix" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssString { x = Unit.Em, y = Unit.Em, z = Unit.Em }
                    |> Expect.equal "translate3d(10em, 20em, 0em)"
        , test "toCssPropertyValue renders Vw unit suffix" <|
            \_ ->
                Translate.fromTriple ( 10, 20, 0 )
                    |> Translate.toCssPropertyValue { x = Unit.Vw, y = Unit.Vw, z = Unit.Vw }
                    |> Expect.equal "10vw 20vw 0vw"
        ]
