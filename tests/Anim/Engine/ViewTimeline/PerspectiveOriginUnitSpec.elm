module Anim.Engine.ViewTimeline.PerspectiveOriginUnitSpec exposing (suite)

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ViewTimeline perspective-origin encoder unit"
        (unitTest "defaults to % when length is not set" Nothing "%"
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
                            b |> PerspectiveOrigin.initXY "hero" 0 0

                        Just unit ->
                            b
                                |> PerspectiveOrigin.initXY "hero" 0 0
                                |> PerspectiveOrigin.initCssUnit unit

                perspectiveBuilder =
                    Builder.for "hero"
                        >> PerspectiveOrigin.begin
                        >> PerspectiveOrigin.toXY 25 75
                        >> PerspectiveOrigin.end
            in
            encodeView [ initStep, perspectiveBuilder ]
                |> decodePerspectiveOriginUnit "hero"
                |> Expect.equal (Just expected)


encodeView : List (Builder.AnimBuilder Builder.ForView -> Builder.AnimBuilder Builder.ForView) -> String
encodeView steps =
    Builder.init steps
        |> Encoder.encodeView
        |> Encode.encode 0


decodePerspectiveOriginUnit : String -> String -> Maybe String
decodePerspectiveOriginUnit animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\ty ->
                        if ty == "perspectiveOrigin" then
                            Decode.field "unitX" Decode.string

                        else
                            Decode.fail "not perspectiveOrigin"
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
