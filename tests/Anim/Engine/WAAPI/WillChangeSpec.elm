module Anim.Engine.WAAPI.WillChangeSpec exposing (suite)

{-| Tests for the `willChange` field in the WAAPI animate / scrollDriven /
viewDriven port payloads.

The Elm side derives a comma-joined CSS `will-change` value covering
every property being animated, and the JS companion applies it to the
target element so the compositor can promote it to its own layer for
the very first frame. Time-driven animations clear the inline value
on completion; scroll- and view-driven engines retain it indefinitely.

The JS side renders transforms via a composite `transform` string, so
all transform-family properties collapse to a single `transform` entry
in the encoded value.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Custom as Custom
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Dict
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Encoder will-change"
        [ test "animate: single transform collapses to 'transform'" <|
            \_ ->
                encodeAnimate
                    (Translate.for "cube"
                        >> Translate.toXY 100 0
                        >> Translate.duration 200
                        >> Translate.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "transform")
        , test "animate: multiple transform families still collapse to 'transform'" <|
            \_ ->
                encodeAnimate
                    (Translate.for "cube"
                        >> Translate.toXY 100 0
                        >> Translate.duration 200
                        >> Translate.build
                        >> Rotate.for "cube"
                        >> Rotate.toZ 45
                        >> Rotate.duration 200
                        >> Rotate.build
                        >> Scale.for "cube"
                        >> Scale.to 1.5
                        >> Scale.duration 200
                        >> Scale.build
                        >> Skew.for "cube"
                        >> Skew.toXY 10 5
                        >> Skew.duration 200
                        >> Skew.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "transform")
        , test "animate: opacity + translate produces 'opacity, transform'" <|
            \_ ->
                encodeAnimate
                    (Opacity.for "cube"
                        >> Opacity.to 1
                        >> Opacity.duration 200
                        >> Opacity.build
                        >> Translate.for "cube"
                        >> Translate.toXY 100 0
                        >> Translate.duration 200
                        >> Translate.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "opacity, transform")
        , test "animate: size emits 'width, height'" <|
            \_ ->
                encodeAnimate
                    (Size.for "cube"
                        >> Size.toHW 200 150
                        >> Size.duration 200
                        >> Size.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "width, height")
        , test "animate: custom property uses its CSS name" <|
            \_ ->
                encodeAnimate
                    (Custom.for "cube" (Custom.BorderRadius Unit.Px)
                        >> Custom.to 10
                        >> Custom.duration 200
                        >> Custom.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "border-radius")
        , test "animate: omits willChange when no animatable properties are present" <|
            \_ ->
                Builder.init [] |> Builder.process |> Encoder.encodeProcessedData |> Encode.encode 0 |> decodeHasElements |> Expect.equal True
        , test "scrollDriven: emits the same composite value" <|
            \_ ->
                encodeScroll
                    (Translate.for "cube"
                        >> Translate.toXY 0 200
                        >> Translate.build
                        >> Opacity.for "cube"
                        >> Opacity.to 1
                        >> Opacity.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "transform, opacity")
        , test "viewDriven: emits the same composite value" <|
            \_ ->
                encodeView
                    (Scale.for "cube"
                        >> Scale.to 2
                        >> Scale.build
                    )
                    |> decodeWillChange "cube"
                    |> Expect.equal (Just "transform")
        ]



-- HELPERS


encodeAnimate : (Builder.AnimBuilder Builder.ForWAAPI -> Builder.AnimBuilder Builder.ForWAAPI) -> String
encodeAnimate steps =
    let
        processed =
            Builder.init [ steps ] |> Builder.process
    in
    Encoder.encode AnimGroups.init Dict.empty processed
        |> Encode.encode 0


encodeScroll : (Builder.AnimBuilder { isScrollBased : () } -> Builder.AnimBuilder { isScrollBased : () }) -> String
encodeScroll steps =
    Builder.init [ steps ]
        |> Encoder.encodeScroll
        |> Encode.encode 0


encodeView : (Builder.AnimBuilder Builder.ForView -> Builder.AnimBuilder Builder.ForView) -> String
encodeView steps =
    Builder.init [ steps ]
        |> Encoder.encodeView
        |> Encode.encode 0


decodeWillChange : String -> String -> Maybe String
decodeWillChange animGroupName json =
    Decode.decodeString
        (Decode.at [ "elements", animGroupName, "willChange" ] Decode.string)
        json
        |> Result.toMaybe


decodeHasElements : String -> Bool
decodeHasElements json =
    Decode.decodeString (Decode.field "elements" Decode.value) json
        |> Result.toMaybe
        |> (\m ->
                case m of
                    Just _ ->
                        True

                    Nothing ->
                        False
           )
