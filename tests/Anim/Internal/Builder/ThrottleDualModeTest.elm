module Anim.Internal.Builder.ThrottleDualModeTest exposing (suite)

import Anim.Internal.Builder as Builder
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Builder throttle dual mode"
        [ test "writes global throttle when no group is selected" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.setUpdateThrottle 33
                in
                ( builder |> Builder.getUpdateThrottle
                , builder |> Builder.getUpdateThrottleFor "other"
                )
                    |> Expect.equal ( 33, 33 )
        , test "group throttle overrides global throttle" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.setUpdateThrottle 33
                            |> Builder.for "hero"
                            |> Builder.setUpdateThrottle 0
                in
                ( builder |> Builder.getUpdateThrottleFor "hero"
                , builder |> Builder.getUpdateThrottleFor "other"
                )
                    |> Expect.equal ( 0, 33 )
        , test "multiple groups keep independent throttle overrides" <|
            \_ ->
                let
                    builder =
                        Builder.init []
                            |> Builder.setUpdateThrottle 40
                            |> Builder.for "hero"
                            |> Builder.setUpdateThrottle 0
                            |> Builder.for "background"
                            |> Builder.setUpdateThrottle 80
                in
                ( builder |> Builder.getUpdateThrottleFor "hero"
                , builder |> Builder.getUpdateThrottleFor "background"
                , builder |> Builder.getUpdateThrottleFor "other"
                )
                    |> Expect.equal ( 0, 80, 40 )
        ]
