module Anim.Extra.ColorSpec exposing (suite)

{-| Tests for `Anim.Extra.Color`.

The module is a thin façade over `Anim.Internal.Extra.Color`. We do
not unit-test every internal helper here — those are covered by their
own internal tests — but we DO exercise the public surface end-to-end
so that any future re-wiring that breaks a public function shows up in
this spec.

Coverage:

  - Constructors (`rgb`, `rgba`, `hsl`, `hsla`, `hex`, `elmColor`) and
    their `from*` aliases.
  - Lossless roundtrips: RGB→RGB, RGBA→RGBA, HSL→HSL, HSLA→HSLA.
  - Hex parsing and serialisation, including the 3-char shorthand,
    the optional leading `#`, and rejection of invalid strings.
  - `fromString` parsing of `#hex`, `rgb()`, `rgba()`, `hsl()`,
    `hsla()`, and explicit rejection of garbage.
  - Manipulation: `setAlpha`, `brighten`, `darken`, `saturate`,
    `desaturate` produce the expected effect on a known sample.
  - Common colors expose the canonical R/G/B/transparent values.

-}

import Anim.Extra.Color as Color
import Color as ElmColor
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Extra.Color"
        [ constructorTests
        , roundtripTests
        , hexTests
        , fromStringTests
        , manipulationTests
        , commonColorTests
        , elmColorBridgeTests
        ]



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


constructorTests : Test
constructorTests =
    describe "constructors"
        [ test "rgb produces matching toRgb record" <|
            \_ ->
                Color.rgb 255 128 0
                    |> Color.toRgb
                    |> Expect.equal { r = 255, g = 128, b = 0 }
        , test "rgba produces matching toRgba record" <|
            \_ ->
                Color.rgba 255 128 0 0.5
                    |> Color.toRgba
                    |> Expect.equal { r = 255, g = 128, b = 0, a = 0.5 }
        , test "hsl produces matching toHsl record" <|
            \_ ->
                Color.hsl 120 50 50
                    |> Color.toHsl
                    |> Expect.equal { h = 120, s = 50, l = 50 }
        , test "hsla produces matching toHsla record" <|
            \_ ->
                Color.hsla 240 100 50 0.25
                    |> Color.toHsla
                    |> Expect.equal { h = 240, s = 100, l = 50, a = 0.25 }
        , test "fromRgb is an alias for rgb" <|
            \_ ->
                Color.fromRgb { r = 10, g = 20, b = 30 }
                    |> Color.toRgb
                    |> Expect.equal { r = 10, g = 20, b = 30 }
        , test "fromRgba is an alias for rgba" <|
            \_ ->
                Color.fromRgba { r = 10, g = 20, b = 30, a = 0.9 }
                    |> Color.toRgba
                    |> Expect.equal { r = 10, g = 20, b = 30, a = 0.9 }
        ]



-- ============================================================
-- ROUNDTRIPS
-- ============================================================


roundtripTests : Test
roundtripTests =
    describe "roundtrips"
        [ test "rgb -> toRgb is identity" <|
            \_ ->
                let
                    sample =
                        { r = 42, g = 137, b = 200 }
                in
                Color.fromRgb sample |> Color.toRgb |> Expect.equal sample
        , test "hsl -> toHsl is identity" <|
            \_ ->
                let
                    sample =
                        { h = 200, s = 80, l = 40 }
                in
                Color.fromHsl sample |> Color.toHsl |> Expect.equal sample
        , test "hsla -> toHsla is identity" <|
            \_ ->
                let
                    sample =
                        { h = 200, s = 80, l = 40, a = 0.6 }
                in
                Color.fromHsla sample |> Color.toHsla |> Expect.equal sample
        , test "rgba -> toRgba is identity" <|
            \_ ->
                let
                    sample =
                        { r = 1, g = 2, b = 3, a = 0.4 }
                in
                Color.fromRgba sample |> Color.toRgba |> Expect.equal sample
        ]



-- ============================================================
-- HEX
-- ============================================================


hexTests : Test
hexTests =
    describe "hex parsing"
        [ test "hex accepts leading #" <|
            \_ ->
                Color.hex "#ff0000"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal (Just { r = 255, g = 0, b = 0 })
        , test "hex accepts no leading #" <|
            \_ ->
                Color.hex "00ff00"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal (Just { r = 0, g = 255, b = 0 })
        , test "hex accepts 3-char shorthand" <|
            \_ ->
                Color.hex "#f00"
                    |> Expect.notEqual Nothing
        , test "hex accepts 8-char with alpha" <|
            \_ ->
                Color.hex "#ff000080"
                    |> Expect.notEqual Nothing
        , test "hex rejects empty string" <|
            \_ ->
                Color.hex "" |> Expect.equal Nothing
        , test "hex rejects non-hex chars" <|
            \_ ->
                Color.hex "#xyz123" |> Expect.equal Nothing
        , test "hex rejects 5-char input" <|
            \_ ->
                Color.hex "#abcde" |> Expect.equal Nothing
        , test "fromHex is an alias for hex" <|
            \_ ->
                Color.fromHex "#abc"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal
                        (Color.hex "#abc" |> Maybe.map Color.toRgb)
        , test "toHex of an rgb color is a hex string" <|
            \_ ->
                Color.rgb 255 0 0
                    |> Color.toHex
                    |> String.toLower
                    |> Expect.equal "#ff0000"
        ]



-- ============================================================
-- fromString
-- ============================================================


fromStringTests : Test
fromStringTests =
    describe "fromString parser"
        [ test "parses #hex" <|
            \_ ->
                Color.fromString "#ff0000"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal (Just { r = 255, g = 0, b = 0 })
        , test "parses rgb()" <|
            \_ ->
                Color.fromString "rgb(255, 128, 0)"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal (Just { r = 255, g = 128, b = 0 })
        , test "parses rgba()" <|
            \_ ->
                Color.fromString "rgba(255, 0, 0, 0.5)"
                    |> Maybe.map Color.toRgba
                    |> Expect.equal (Just { r = 255, g = 0, b = 0, a = 0.5 })
        , test "parses hsl()" <|
            \_ ->
                Color.fromString "hsl(0, 100%, 50%)"
                    |> Maybe.map Color.toHsl
                    |> Expect.equal (Just { h = 0, s = 100, l = 50 })
        , test "parses hsla()" <|
            \_ ->
                Color.fromString "hsla(0, 100%, 50%, 0.5)"
                    |> Maybe.map Color.toHsla
                    |> Expect.equal (Just { h = 0, s = 100, l = 50, a = 0.5 })
        , test "rejects empty" <|
            \_ ->
                Color.fromString "" |> Expect.equal Nothing
        , test "rejects garbage" <|
            \_ ->
                Color.fromString "not a color" |> Expect.equal Nothing
        ]



-- ============================================================
-- MANIPULATION
-- ============================================================


manipulationTests : Test
manipulationTests =
    describe "manipulation"
        [ test "setAlpha replaces the alpha channel" <|
            \_ ->
                Color.rgba 100 100 100 1.0
                    |> Color.setAlpha 0.25
                    |> Color.toRgba
                    |> .a
                    |> Expect.within (Expect.Absolute 1.0e-9) 0.25
        , test "setAlpha clamps above 1 to 1" <|
            \_ ->
                Color.rgba 0 0 0 0.5
                    |> Color.setAlpha 5
                    |> Color.toRgba
                    |> .a
                    |> Expect.within (Expect.Absolute 1.0e-9) 1
        , test "setAlpha clamps below 0 to 0" <|
            \_ ->
                Color.rgba 0 0 0 0.5
                    |> Color.setAlpha -1
                    |> Color.toRgba
                    |> .a
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "brighten increases lightness" <|
            \_ ->
                let
                    base =
                        Color.hsl 0 50 40

                    brighter =
                        Color.brighten 0.2 base
                in
                (Color.toHsl brighter |> .l)
                    |> Expect.greaterThan (Color.toHsl base |> .l)
        , test "darken decreases lightness" <|
            \_ ->
                let
                    base =
                        Color.hsl 0 50 60

                    darker =
                        Color.darken 0.2 base
                in
                (Color.toHsl darker |> .l)
                    |> Expect.lessThan (Color.toHsl base |> .l)
        , test "saturate increases saturation" <|
            \_ ->
                let
                    base =
                        Color.hsl 0 40 50
                in
                (Color.saturate 0.2 base |> Color.toHsl |> .s)
                    |> Expect.greaterThan (Color.toHsl base |> .s)
        , test "desaturate decreases saturation" <|
            \_ ->
                let
                    base =
                        Color.hsl 0 80 50
                in
                (Color.desaturate 0.3 base |> Color.toHsl |> .s)
                    |> Expect.lessThan (Color.toHsl base |> .s)
        , test "brighten clamps at 100" <|
            \_ ->
                Color.hsl 0 50 90
                    |> Color.brighten 5
                    |> Color.toHsl
                    |> .l
                    |> Expect.within (Expect.Absolute 1.0e-9) 100
        , test "darken clamps at 0" <|
            \_ ->
                Color.hsl 0 50 10
                    |> Color.darken 5
                    |> Color.toHsl
                    |> .l
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        ]



-- ============================================================
-- COMMON COLORS
-- ============================================================


commonColorTests : Test
commonColorTests =
    describe "common colors"
        [ test "black is (0, 0, 0)" <|
            \_ ->
                Color.black |> Color.toRgb |> Expect.equal { r = 0, g = 0, b = 0 }
        , test "white is (255, 255, 255)" <|
            \_ ->
                Color.white |> Color.toRgb |> Expect.equal { r = 255, g = 255, b = 255 }
        , test "red is (255, 0, 0)" <|
            \_ ->
                Color.red |> Color.toRgb |> Expect.equal { r = 255, g = 0, b = 0 }
        , test "green is (0, 255, 0)" <|
            \_ ->
                Color.green |> Color.toRgb |> Expect.equal { r = 0, g = 255, b = 0 }
        , test "blue is (0, 0, 255)" <|
            \_ ->
                Color.blue |> Color.toRgb |> Expect.equal { r = 0, g = 0, b = 255 }
        , test "transparent has alpha 0" <|
            \_ ->
                Color.transparent
                    |> Color.toRgba
                    |> .a
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        ]



-- ============================================================
-- elm-color bridge
-- ============================================================


elmColorBridgeTests : Test
elmColorBridgeTests =
    describe "elm-color bridge"
        [ test "fromElmColor / toElmColor roundtrip preserves rgb" <|
            \_ ->
                let
                    original =
                        ElmColor.rgb255 200 100 50

                    roundtripped =
                        Color.fromElmColor original |> Color.toElmColor

                    originalRgba =
                        ElmColor.toRgba original

                    roundtrippedRgba =
                        ElmColor.toRgba roundtripped
                in
                Expect.all
                    [ \_ ->
                        roundtrippedRgba.red
                            |> Expect.within (Expect.Absolute 1.0e-6) originalRgba.red
                    , \_ ->
                        roundtrippedRgba.green
                            |> Expect.within (Expect.Absolute 1.0e-6) originalRgba.green
                    , \_ ->
                        roundtrippedRgba.blue
                            |> Expect.within (Expect.Absolute 1.0e-6) originalRgba.blue
                    ]
                    ()
        , test "elmColor constructor is an alias for fromElmColor" <|
            \_ ->
                let
                    e =
                        ElmColor.rgb255 10 20 30
                in
                (Color.elmColor e |> Color.toRgb)
                    |> Expect.equal (Color.fromElmColor e |> Color.toRgb)
        ]
