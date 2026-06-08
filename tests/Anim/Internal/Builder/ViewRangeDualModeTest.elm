module Anim.Internal.Builder.ViewRangeDualModeTest exposing (suite)

import Anim.Internal.Builder as Builder
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Builder view range dual mode"
        [ test "writes global range when no group is selected" <|
            \_ ->
                Builder.init []
                    |> Builder.setViewRangeStart "entry 0%"
                    |> Builder.setViewRangeEnd "exit 100%"
                    |> Builder.getViewRangeStart
                    |> Expect.equal (Just "entry 0%")
        , test "writes group range when a group is selected" <|
            \_ ->
                Builder.init []
                    |> Builder.for "el"
                    |> Builder.setViewRangeStart "entry 10%"
                    |> Builder.setViewRangeEnd "exit 40%"
                    |> Builder.getAnimGroupConfig "el"
                    |> Maybe.map (\config -> ( config.viewRangeStart, config.viewRangeEnd ))
                    |> Expect.equal (Just ( Just "entry 10%", Just "exit 40%" ))
        , test "current group config falls back to the global range when group has no explicit override" <|
            \_ ->
                Builder.init []
                    |> Builder.setViewRangeStart "entry 5%"
                    |> Builder.setViewRangeEnd "exit 95%"
                    |> Builder.for "el"
                    |> Builder.getCurrentAnimGroupConfig
                    |> (\config ->
                            ( config.viewRangeStart, config.viewRangeEnd )
                                |> Expect.equal ( Just "entry 5%", Just "exit 95%" )
                       )
        , test "multiple groups keep independent overrides" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.setViewRangeStart "entry 0%"
                            |> Builder.setViewRangeEnd "exit 100%"
                            |> Builder.for "el-1"
                            |> Builder.setViewRangeStart "entry 10%"
                            |> Builder.setViewRangeEnd "exit 50%"
                            |> Builder.for "el-2"
                            |> Builder.setViewRangeStart "entry 20%"
                            |> Builder.setViewRangeEnd "exit 80%"
                in
                ( Builder.getAnimGroupConfig "el-1" builder
                    |> Maybe.map (\config -> ( config.viewRangeStart, config.viewRangeEnd ))
                , Builder.getAnimGroupConfig "el-2" builder
                    |> Maybe.map (\config -> ( config.viewRangeStart, config.viewRangeEnd ))
                )
                    |> Expect.equal
                        ( Just ( Just "entry 10%", Just "exit 50%" )
                        , Just ( Just "entry 20%", Just "exit 80%" )
                        )
        ]
