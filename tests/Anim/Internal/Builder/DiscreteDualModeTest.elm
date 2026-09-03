module Anim.Internal.Builder.DiscreteDualModeTest exposing (suite)

import Anim.Internal.Builder as Builder
import Dict
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Builder discrete entry/exit dual mode"
        [ test "writes global discrete entry/exit settings when no group is selected" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.discreteEntry "display" "block"
                            |> Builder.discreteExit "visibility" "hidden" "visible"
                in
                ( builder |> Builder.getDiscreteEntryPropertiesFor "other"
                , builder |> Builder.getDiscreteExitPropertiesFor "other"
                )
                    |> Expect.equal
                        ( Dict.fromList [ ( "display", "block" ) ]
                        , Dict.fromList [ ( "visibility", { from = "hidden", to = "visible" } ) ]
                        )
        , test "group discrete settings merge with the global defaults" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.discreteEntry "display" "block"
                            |> Builder.discreteExit "visibility" "hidden" "visible"
                            |> Builder.for "el"
                            |> Builder.discreteEntry "visibility" "visible"
                            |> Builder.discreteExit "display" "block" "none"
                in
                ( builder |> Builder.getDiscreteEntryPropertiesFor "el"
                , builder |> Builder.getDiscreteExitPropertiesFor "el"
                )
                    |> Expect.equal
                        ( Dict.fromList
                            [ ( "display", "block" )
                            , ( "visibility", "visible" )
                            ]
                        , Dict.fromList
                            [ ( "display", { from = "block", to = "none" } )
                            , ( "visibility", { from = "hidden", to = "visible" } )
                            ]
                        )
        , test "multiple groups keep independent discrete overrides" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.discreteEntry "display" "block"
                            |> Builder.for "el-1"
                            |> Builder.discreteEntry "visibility" "visible"
                            |> Builder.for "el-2"
                            |> Builder.discreteEntry "display" "inline"
                in
                ( builder |> Builder.getDiscreteEntryPropertiesFor "el-1"
                , builder |> Builder.getDiscreteEntryPropertiesFor "el-2"
                )
                    |> Expect.equal
                        ( Dict.fromList
                            [ ( "display", "block" )
                            , ( "visibility", "visible" )
                            ]
                        , Dict.fromList [ ( "display", "inline" ) ]
                        )
        , test "current group config keeps the global path and preserves per-group overrides" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.discreteEntry "display" "block"
                            |> Builder.discreteEntry "opacity" "1"
                            |> Builder.for "el"
                            |> Builder.discreteEntry "display" "flex"
                in
                ( Builder.getCurrentAnimGroupConfig builder
                    |> .discreteEntryProperties
                , Builder.getDiscreteEntryPropertiesFor "el" builder
                )
                    |> Expect.equal
                        ( Just (Dict.fromList [ ( "display", "flex" ), ( "opacity", "1" ) ])
                        , Dict.fromList [ ( "display", "flex" ), ( "opacity", "1" ) ]
                        )
        , test "init entries do not leak current group selection into the next entry" <|
            \_ ->
                let
                    builder =
                        Builder.init
                            [ Builder.for "top-line-group"
                            , Builder.for "middle-line-group"
                            , Builder.for "bottom-line-group"
                            , Builder.discreteEntry "display" "block"
                                >> Builder.for "phone-menu-button"
                            ]
                in
                Builder.getAnimGroupConfig "bottom-line-group" builder
                    |> Maybe.andThen .discreteEntryProperties
                    |> Expect.equal Nothing
        ]
