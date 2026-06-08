module Anim.Internal.Builder.TransformOrderDualModeTest exposing (suite)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Expect
import Test exposing (Test, describe, test)


globalOrder : List TransformProperty
globalOrder =
    [ Translate, Rotate, Skew, Scale ]


groupOrderA : List TransformProperty
groupOrderA =
    [ Scale, Rotate, Translate, Skew ]


groupOrderB : List TransformProperty
groupOrderB =
    [ Rotate, Skew, Scale, Translate ]


suite : Test
suite =
    describe "Builder.transformOrder dual mode"
        [ test "writes global default when no group is selected" <|
            \_ ->
                Builder.init []
                    |> Builder.transformOrder globalOrder
                    |> Builder.getTransformOrder "unknown-group"
                    |> Expect.equal (Just globalOrder)
        , test "writes group transformOrder when a group is selected" <|
            \_ ->
                Builder.init []
                    |> Builder.for "el"
                    |> Builder.transformOrder groupOrderA
                    |> Builder.getTransformOrder "el"
                    |> Expect.equal (Just groupOrderA)
        , test "group transformOrder overrides global for the selected group" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.transformOrder globalOrder
                            |> Builder.for "el"
                            |> Builder.transformOrder groupOrderA
                in
                builder
                    |> Builder.getCurrentAnimGroupConfig
                    |> .transformOrder
                    |> Expect.equal (Just groupOrderA)
        , test "current group config falls back to global when group has no explicit transformOrder" <|
            \_ ->
                Builder.init []
                    |> Builder.transformOrder globalOrder
                    |> Builder.for "el"
                    |> Builder.getCurrentAnimGroupConfig
                    |> .transformOrder
                    |> Expect.equal (Just globalOrder)
        , test "multiple groups keep independent transformOrder values" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.for "el-1"
                            |> Builder.transformOrder groupOrderA
                            |> Builder.for "el-2"
                            |> Builder.transformOrder groupOrderB
                in
                ( builder |> Builder.getTransformOrder "el-1"
                , builder |> Builder.getTransformOrder "el-2"
                )
                    |> Expect.equal ( Just groupOrderA, Just groupOrderB )
        ]
