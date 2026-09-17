module Anim.Engine.ScrollTimeline.Properties.CssUnit.TranslateUnitSpec exposing (suite)

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ScrollTimeline translate encoder unit"
        (unitTest "defaults to px when length is not set" Nothing "px"
            :: List.map
                (\unitCase ->
                    unitTest
                        ("emits " ++ unitCase.css ++ " when Unit." ++ unitCase.name ++ " is set")
                        (Just unitCase.unit)
                        unitCase.css
                )
                UnitMatrix.all
        )


unitTest : String -> Maybe Unit.Unit -> String -> Test
unitTest description maybeUnit expected =
    test description <|
        \_ ->
            let
                initStep b =
                    case maybeUnit of
                        Nothing ->
                            b |> Translate.initY "dot" 0

                        Just unit ->
                            b
                                |> Translate.initY "dot" 0
                                |> Translate.initCssUnit unit

                translateBuilder =
                    Builder.for "dot"
                        >> Translate.begin
                        >> Translate.toY 62
                        >> Translate.end
            in
            encodeScroll [ initStep, translateBuilder ]
                |> decodeTranslateUnit "dot"
                |> Expect.equal (Just expected)


encodeScroll : List (Builder.AnimBuilder eng -> Builder.AnimBuilder eng) -> String
encodeScroll steps =
    Builder.init steps
        |> Builder.setScrollSource "document"
        |> Encoder.encodeScroll
        |> Encode.encode 0


decodeTranslateUnit : String -> String -> Maybe String
decodeTranslateUnit animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\ty ->
                        if ty == "translate" then
                            Decode.field "unitY" Decode.string

                        else
                            Decode.fail "not translate"
                    )
    in
    Decode.decodeString
        (Decode.at [ "elements", animGroupName, "properties" ]
            (Decode.list (Decode.maybe propertyDecoder)
                |> Decode.map (List.filterMap identity >> List.head)
            )
        )
        json
        |> Result.toMaybe
        |> Maybe.andThen identity
