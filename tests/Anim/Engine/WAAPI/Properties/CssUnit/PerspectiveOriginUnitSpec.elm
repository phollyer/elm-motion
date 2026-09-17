module Anim.Engine.WAAPI.Properties.CssUnit.PerspectiveOriginUnitSpec exposing (suite)

{-| Verifies that the WAAPI perspective-origin encoder emits a `unit` field
reflecting the length unit configured via `PerspectiveOrigin.cssUnit`. The JS
companion uses this field to build `perspective-origin: <x> <y>` keyframe
strings with the matching CSS unit.
-}

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI perspective-origin encoder unit"
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
                animGroups =
                    AnimGroups.init
                        |> AnimGroups.insert "card" AnimGroup.init

                originBuilder =
                    Builder.for "card"
                        >> PerspectiveOrigin.begin
                        >> PerspectiveOrigin.toXY 25 75
                        >> PerspectiveOrigin.duration 500
                        >> PerspectiveOrigin.end

                initStep b =
                    case maybeUnit of
                        Nothing ->
                            b |> PerspectiveOrigin.initXY "card" 0 0

                        Just unit ->
                            b
                                |> PerspectiveOrigin.initXY "card" 0 0
                                |> PerspectiveOrigin.initCssUnit unit

                processed =
                    Builder.init [ initStep, originBuilder ] |> Builder.process

                json =
                    Encoder.encode animGroups processed |> Encode.encode 0
            in
            json
                |> decodePerspectiveOriginUnit "card"
                |> Expect.equal (Just expected)


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
