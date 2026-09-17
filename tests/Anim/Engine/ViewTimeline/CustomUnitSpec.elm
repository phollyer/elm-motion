module Anim.Engine.ViewTimeline.CustomUnitSpec exposing (suite)

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Custom as Custom
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ViewTimeline custom encoder unit"
        (List.map
            (\unitCase ->
                unitTest
                    ("emits " ++ unitSuffixLabel unitCase.css ++ " when Unit." ++ unitCase.name ++ " is set")
                    unitCase.unit
                    unitCase.css
            )
            UnitMatrix.all
        )


unitSuffixLabel : String -> String
unitSuffixLabel css =
    if css == "" then
        "an empty suffix"

    else
        css


unitTest : String -> Unit.Unit -> String -> Test
unitTest description unit expected =
    test description <|
        \_ ->
            let
                initStep =
                    Custom.init "card" (Custom.BorderRadius unit) 0

                customBuilder =
                    Builder.for "card"
                        >> Custom.begin (Custom.BorderRadius unit)
                        >> Custom.to 16
                        >> Custom.end
            in
            encodeView [ initStep, customBuilder ]
                |> decodeCustomUnit "card"
                |> Expect.equal (Just expected)


encodeView : List (Builder.AnimBuilder Builder.ForView -> Builder.AnimBuilder Builder.ForView) -> String
encodeView steps =
    Builder.init steps
        |> Encoder.encodeView
        |> Encode.encode 0


decodeCustomUnit : String -> String -> Maybe String
decodeCustomUnit animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\ty ->
                        if ty == "customProperty" then
                            Decode.map2 Tuple.pair
                                (Decode.field "cssProperty" Decode.string)
                                (Decode.field "unit" Decode.string)
                                |> Decode.andThen
                                    (\( cssProperty, unit ) ->
                                        if cssProperty == "border-radius" then
                                            Decode.succeed unit

                                        else
                                            Decode.fail "other custom property"
                                    )

                        else
                            Decode.fail "not customProperty"
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
