module Anim.Engine.ViewTimeline.SizeUnitSpec exposing (suite)

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Size as Size
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ViewTimeline size encoder unit"
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
                            b |> Size.initHW "card" 0 0

                        Just unit ->
                            b
                                |> Size.initHW "card" 0 0
                                |> Size.initCssUnit unit

                sizeBuilder =
                    Builder.for "card"
                        >> Size.begin
                        >> Size.toHW 100 200
                        >> Size.end
            in
            encodeView [ initStep, sizeBuilder ]
                |> decodeSizeUnit "card"
                |> Expect.equal (Just expected)


encodeView : List (Builder.AnimBuilder Builder.ForView -> Builder.AnimBuilder Builder.ForView) -> String
encodeView steps =
    Builder.init steps
        |> Encoder.encodeView
        |> Encode.encode 0


decodeSizeUnit : String -> String -> Maybe String
decodeSizeUnit animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\ty ->
                        if ty == "size" then
                            Decode.field "unitWidth" Decode.string

                        else
                            Decode.fail "not size"
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
