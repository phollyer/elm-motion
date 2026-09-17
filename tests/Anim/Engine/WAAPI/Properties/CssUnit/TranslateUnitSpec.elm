module Anim.Engine.WAAPI.Properties.CssUnit.TranslateUnitSpec exposing (suite)

{-| Verifies that the WAAPI translate encoder emits a `unit` field reflecting
the length unit configured via `Translate.cssUnit`. The JS companion uses this
field to build `translate3d(...)` keyframe strings with the matching CSS unit
(`px`, `%`, `vw`/`vh`, dynamic-viewport `dvw`/`dvh`/`svw`/`svh`/`lvw`/`lvh`,
`rem`, `em`, container-query `cqi`/`cqb`/`cqw`/`cqh`/`cqmin`/`cqmax`); without
it the JS hardcoded `px` suffix and ignored any non-default unit chosen on the
Elm side.
-}

import Anim.Engine.Shared.UnitMatrix as UnitMatrix
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI translate encoder unit"
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
                animGroups =
                    AnimGroups.init
                        |> AnimGroups.insert "ball" AnimGroup.init

                translateBuilder =
                    Builder.for "ball"
                        >> Translate.begin
                        >> Translate.toY 62
                        >> Translate.duration 500
                        >> Translate.end

                initStep b =
                    case maybeUnit of
                        Nothing ->
                            b |> Translate.initY "ball" 0

                        Just unit ->
                            b
                                |> Translate.initY "ball" 0
                                |> Translate.initCssUnit unit

                processed =
                    Builder.init [ initStep, translateBuilder ] |> Builder.process

                json =
                    Encoder.encode animGroups processed |> Encode.encode 0
            in
            json
                |> decodeTranslateUnit "ball"
                |> Expect.equal (Just expected)


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
