module Anim.Internal.Builder.FreezeDualModeTest exposing (suite)

import Anim.Internal.Builder as Builder
import Dict
import Expect
import Test exposing (Test, describe, test)


translateAxes : Dict.Dict String (List String) -> List String
translateAxes frozenAxes =
    Dict.get "translate" frozenAxes
        |> Maybe.withDefault []


suite : Test
suite =
    describe "Builder.freezeAxes/unfreezeAxes dual mode"
        [ test "writes global frozen axes when no group is selected" <|
            \_ ->
                Builder.init []
                    |> Builder.freezeAxes [ "x" ] [ Builder.FreezeTranslate ]
                    |> Builder.getAllFrozenAxes
                    |> translateAxes
                    |> Expect.equal [ "x" ]
        , test "writes group frozen axes when a group is selected" <|
            \_ ->
                Builder.init []
                    |> Builder.for "el"
                    |> Builder.freezeAxes [ "y" ] [ Builder.FreezeTranslate ]
                    |> Builder.getAllFrozenAxesFor "el"
                    |> translateAxes
                    |> Expect.equal [ "y" ]
        , test "group unfreeze overrides global for the selected group" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.freezeAxes [ "x" ] [ Builder.FreezeTranslate ]
                            |> Builder.for "el"
                            |> Builder.unfreezeAxes [ "x" ] [ Builder.FreezeTranslate ]
                in
                builder
                    |> Builder.getAllFrozenAxesFor "el"
                    |> translateAxes
                    |> Expect.equal []
        , test "group with no explicit freeze override falls back to global" <|
            \_ ->
                Builder.init []
                    |> Builder.freezeAxes [ "x" ] [ Builder.FreezeTranslate ]
                    |> Builder.getAllFrozenAxesFor "other"
                    |> translateAxes
                    |> Expect.equal [ "x" ]
        , test "multiple groups keep independent frozen-axis overrides" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.freezeAxes [ "x" ] [ Builder.FreezeTranslate ]
                            |> Builder.for "el-1"
                            |> Builder.unfreezeAxes [ "x" ] [ Builder.FreezeTranslate ]
                            |> Builder.for "el-2"
                            |> Builder.freezeAxes [ "y" ] [ Builder.FreezeTranslate ]
                in
                ( builder |> Builder.getAllFrozenAxesFor "el-1" |> translateAxes |> List.sort
                , builder |> Builder.getAllFrozenAxesFor "el-2" |> translateAxes |> List.sort
                )
                    |> Expect.equal ( [], [ "x", "y" ] )
        ]
