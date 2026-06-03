module Anim.Engine.WAAPI.TranslateUnitSpec exposing (suite)

{-| Verifies that the WAAPI translate encoder emits a `unit` field reflecting
the length unit configured via `Translate.cssUnit`. The JS companion uses this
field to build `translate3d(...)` keyframe strings with the matching CSS unit
(`px`, `%`, `vw`/`vh`, dynamic-viewport `dvw`/`dvh`/`svw`/`svh`/`lvw`/`lvh`,
`rem`, `em`, container-query `cqi`/`cqb`/`cqw`/`cqh`/`cqmin`/`cqmax`); without
it the JS hardcoded `px` suffix and ignored any non-default unit chosen on the
Elm side.
-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Dict
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI translate encoder unit"
        [ unitTest "defaults to px when length is not set" Nothing "px"
        , unitTest "emits px when Unit.Px is set" (Just Unit.Px) "px"
        , unitTest "emits % when Unit.Percent is set" (Just Unit.Percent) "%"
        , unitTest "emits vw when Unit.Vw is set" (Just Unit.Vw) "vw"
        , unitTest "emits vh when Unit.Vh is set" (Just Unit.Vh) "vh"
        , unitTest "emits dvw when Unit.Dvw is set" (Just Unit.Dvw) "dvw"
        , unitTest "emits dvh when Unit.Dvh is set" (Just Unit.Dvh) "dvh"
        , unitTest "emits svw when Unit.Svw is set" (Just Unit.Svw) "svw"
        , unitTest "emits svh when Unit.Svh is set" (Just Unit.Svh) "svh"
        , unitTest "emits lvw when Unit.Lvw is set" (Just Unit.Lvw) "lvw"
        , unitTest "emits lvh when Unit.Lvh is set" (Just Unit.Lvh) "lvh"
        , unitTest "emits rem when Unit.Rem is set" (Just Unit.Rem) "rem"
        , unitTest "emits em when Unit.Em is set" (Just Unit.Em) "em"
        , unitTest "emits cqi when Unit.Cqi is set" (Just Unit.Cqi) "cqi"
        , unitTest "emits cqb when Unit.Cqb is set" (Just Unit.Cqb) "cqb"
        , unitTest "emits cqw when Unit.Cqw is set" (Just Unit.Cqw) "cqw"
        , unitTest "emits cqh when Unit.Cqh is set" (Just Unit.Cqh) "cqh"
        , unitTest "emits cqmin when Unit.Cqmin is set" (Just Unit.Cqmin) "cqmin"
        , unitTest "emits cqmax when Unit.Cqmax is set" (Just Unit.Cqmax) "cqmax"
        ]


unitTest : String -> Maybe Unit.Unit -> String -> Test
unitTest description maybeUnit expected =
    test description <|
        \_ ->
            let
                animGroups =
                    AnimGroups.init
                        |> AnimGroups.insert "ball" AnimGroup.init

                translateBuilder =
                    Translate.for "ball"
                        >> Translate.toY 62
                        >> Translate.duration 500
                        >> Translate.build

                initStep b =
                    case maybeUnit of
                        Nothing ->
                            b |> Translate.initY "ball" 0

                        Just unit ->
                            b
                                |> Translate.initY "ball" 0
                                |> Translate.cssUnit unit

                processed =
                    Builder.init [ initStep, translateBuilder ] |> Builder.process

                json =
                    Encoder.encode animGroups Dict.empty processed |> Encode.encode 0
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
