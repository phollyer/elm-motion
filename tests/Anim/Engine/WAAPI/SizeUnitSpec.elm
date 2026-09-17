module Anim.Engine.WAAPI.SizeUnitSpec exposing (suite)

{-| Verifies that the WAAPI size encoder emits a `unit` field reflecting the
cssUnit unit configured via `Size.cssUnit`. The JS companion uses this field to
build `width`/`height` keyframes with the matching CSS unit.
-}

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Size as Size
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI size encoder unit"
        ((unitTest "defaults to px when length is not set" Nothing "px"
            :: List.map
                (\unitCase ->
                    unitTest
                        ("emits " ++ unitCase.css ++ " when Unit." ++ unitCase.name ++ " is set")
                        (Just unitCase.unit)
                        unitCase.css
                )
                UnitMatrix.all
         )
            ++ [ test "property unit targets the group selected before Size.begin" <|
                    \_ ->
                        let
                            initialized =
                                Builder.init
                                    [ Size.initHW "leftLine" 3 0
                                        >> Size.initCssUnitW Unit.Percent
                                    , Size.initHW "rightLine" 3 0
                                        >> Size.initCssUnitW Unit.Percent
                                    ]
                                    |> Builder.mergeBaselines
                                    |> Builder.clearAnimData

                            percentPhase =
                                initialized
                                    |> Builder.for "leftLine"
                                    |> Size.begin
                                    |> Size.toW 100
                                    |> Size.end

                            afterPercentPhase =
                                let
                                    percentProcessed =
                                        Builder.process percentPhase
                                in
                                percentPhase
                                    |> Builder.addAnimationToHistory percentProcessed
                                    |> Builder.mergeBaselines
                                    |> Builder.clearAnimData

                            processed =
                                afterPercentPhase
                                    |> Builder.for "leftLine"
                                    |> Size.begin
                                    |> Size.cssUnitW Unit.Px
                                    |> Size.toW 1
                                    |> Size.end
                                    |> Builder.process

                            json =
                                Encoder.encode AnimGroups.init processed |> Encode.encode 0
                        in
                        json
                            |> decodeSizeUnit "leftLine"
                            |> Expect.equal (Just "px")
               ]
        )


unitTest : String -> Maybe Unit.Unit -> String -> Test
unitTest description maybeUnit expected =
    test description <|
        \_ ->
            let
                animGroups =
                    AnimGroups.init
                        |> AnimGroups.insert "card" AnimGroup.init

                sizeBuilder =
                    Builder.for "card"
                        >> Size.begin
                        >> Size.toHW 100 200
                        >> Size.duration 500
                        >> Size.end

                initStep b =
                    case maybeUnit of
                        Nothing ->
                            b |> Size.initHW "card" 0 0

                        Just unit ->
                            b
                                |> Size.initHW "card" 0 0
                                |> Size.initCssUnit unit

                processed =
                    Builder.init [ initStep, sizeBuilder ] |> Builder.process

                json =
                    Encoder.encode animGroups processed |> Encode.encode 0
            in
            json
                |> decodeSizeUnit "card"
                |> Expect.equal (Just expected)


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
