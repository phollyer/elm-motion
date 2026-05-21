module Anim.Internal.Property.TestSize exposing (suite)

import Anim.Internal.Property.Size as Size
import Anim.Unit as Unit
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.Size"
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
        [ test "default is zero size" <|
            \_ ->
                Size.default
                    |> Size.toTuple
                    |> Expect.equal ( 0, 0 )
        , test "fromTuple stores width and height" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toTuple
                    |> Expect.equal ( 100, 200 )
        , test "fromRecord stores width and height" <|
            \_ ->
                Size.fromRecord { width = 50, height = 75 }
                    |> Size.toTuple
                    |> Expect.equal ( 50, 75 )
        ]



-- ACCESSORS


accessors : Test
accessors =
    describe "Accessors"
        [ test "w returns width" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.getW
                    |> Expect.equal 100
        , test "h returns height" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.getH
                    |> Expect.equal 200
        ]



-- CONVERSIONS


conversions : Test
conversions =
    describe "Conversions"
        [ test "toRecord returns width and height" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toRecord
                    |> Expect.equal { width = 100, height = 200 }
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "Distance (Euclidean)"
        [ test "same size has zero distance" <|
            \_ ->
                Size.distance
                    (Size.fromTuple ( 100, 200 ))
                    (Size.fromTuple ( 100, 200 ))
                    |> Expect.equal 0
        , test "horizontal distance only" <|
            \_ ->
                Size.distance
                    (Size.fromTuple ( 0, 0 ))
                    (Size.fromTuple ( 3, 0 ))
                    |> Expect.within (Expect.Absolute 0.001) 3
        , test "diagonal distance uses Euclidean formula" <|
            \_ ->
                Size.distance
                    (Size.fromTuple ( 0, 0 ))
                    (Size.fromTuple ( 3, 4 ))
                    |> Expect.within (Expect.Absolute 0.001) 5
        , test "is symmetric" <|
            \_ ->
                let
                    a =
                        Size.fromTuple ( 10, 20 )

                    b =
                        Size.fromTuple ( 30, 60 )
                in
                Expect.within (Expect.Absolute 0.001)
                    (Size.distance a b)
                    (Size.distance b a)
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "Interpolation"
        [ test "t=0 returns start" <|
            \_ ->
                Size.interpolate 0
                    (Size.fromTuple ( 0, 0 ))
                    (Size.fromTuple ( 100, 200 ))
                    |> Size.toTuple
                    |> Expect.equal ( 0, 0 )
        , test "t=1 returns end" <|
            \_ ->
                Size.interpolate 1
                    (Size.fromTuple ( 0, 0 ))
                    (Size.fromTuple ( 100, 200 ))
                    |> Size.toTuple
                    |> Expect.equal ( 100, 200 )
        , test "t=0.5 returns midpoint" <|
            \_ ->
                Size.interpolate 0.5
                    (Size.fromTuple ( 0, 0 ))
                    (Size.fromTuple ( 100, 200 ))
                    |> Size.toTuple
                    |> Expect.equal ( 50, 100 )
        , test "same start and end returns that value" <|
            \_ ->
                Size.interpolate 0.75
                    (Size.fromTuple ( 42, 42 ))
                    (Size.fromTuple ( 42, 42 ))
                    |> Size.toTuple
                    |> Expect.equal ( 42, 42 )
        ]



-- CSS OUTPUT


cssOutput : Test
cssOutput =
    describe "CSS Output"
        [ test "toCssString produces width and height" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toCssString { x = Unit.Px, y = Unit.Px, z = Unit.Px }
                    |> Expect.equal "width: 100px; height: 200px"
        , test "widthToCssString produces width value" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.widthToCssString { x = Unit.Px, y = Unit.Px, z = Unit.Px }
                    |> Expect.equal "100px"
        , test "heightToCssString produces height value" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.heightToCssString { x = Unit.Px, y = Unit.Px, z = Unit.Px }
                    |> Expect.equal "200px"
        , test "toCssString renders Percent unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toCssString { x = Unit.Percent, y = Unit.Percent, z = Unit.Percent }
                    |> Expect.equal "width: 100%; height: 200%"
        , test "toCssString renders Vw unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toCssString { x = Unit.Vw, y = Unit.Vw, z = Unit.Vw }
                    |> Expect.equal "width: 100vw; height: 200vw"
        , test "toCssString renders Vh unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toCssString { x = Unit.Vh, y = Unit.Vh, z = Unit.Vh }
                    |> Expect.equal "width: 100vh; height: 200vh"
        , test "toCssString renders Rem unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toCssString { x = Unit.Rem, y = Unit.Rem, z = Unit.Rem }
                    |> Expect.equal "width: 100rem; height: 200rem"
        , test "toCssString renders Em unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.toCssString { x = Unit.Em, y = Unit.Em, z = Unit.Em }
                    |> Expect.equal "width: 100em; height: 200em"
        , test "widthToCssString renders Vw unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.widthToCssString { x = Unit.Vw, y = Unit.Vw, z = Unit.Vw }
                    |> Expect.equal "100vw"
        , test "heightToCssString renders Vh unit suffix" <|
            \_ ->
                Size.fromTuple ( 100, 200 )
                    |> Size.heightToCssString { x = Unit.Vh, y = Unit.Vh, z = Unit.Vh }
                    |> Expect.equal "200vh"
        ]
