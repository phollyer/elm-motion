module Anim.Engine.Sub.PerspectiveOriginResizeUnitSpec exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit as Unit
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "card"


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


within : Float -> Float -> Float -> Expect.Expectation
within tolerance expected actual =
    if abs (expected - actual) <= tolerance then
        Expect.pass

    else
        Expect.fail
            ("Expected "
                ++ String.fromFloat actual
                ++ " to be within "
                ++ String.fromFloat tolerance
                ++ " of "
                ++ String.fromFloat expected
            )


current : Sub.AnimState -> { x : Float, y : Float }
current state =
    Sub.getPerspectiveOriginCurrent groupName state
        |> Maybe.withDefault { x = -1, y = -1 }


endValue : Sub.AnimState -> { x : Float, y : Float }
endValue state =
    Sub.getPerspectiveOriginEnd groupName state
        |> Maybe.withDefault { x = -1, y = -1 }


suite : Test
suite =
    describe "Sub PerspectiveOrigin onResize unit policy"
        [ test "non-px axes are not numerically remapped" <|
            \_ ->
                let
                    state =
                        Sub.init [ PerspectiveOrigin.initXY groupName 50 50 ]
                            |> (\s ->
                                    Sub.animate s
                                        (PerspectiveOrigin.for groupName
                                            >> PerspectiveOrigin.toXY 90 10
                                            >> PerspectiveOrigin.duration 1000
                                            >> PerspectiveOrigin.easing Linear
                                            >> PerspectiveOrigin.build
                                        )
                               )
                            |> step 500

                    beforeCurrent =
                        current state

                    beforeEnd =
                        endValue state

                    resized =
                        Sub.onResize state <|
                            PerspectiveOrigin.bounds groupName
                                { x = Just { min = 0, max = 1000 }
                                , y = Just { min = 0, max = 1000 }
                                , z = Nothing
                                }
                in
                Expect.all
                    [ \_ -> (current resized).x |> within 0.001 beforeCurrent.x
                    , \_ -> (current resized).y |> within 0.001 beforeCurrent.y
                    , \_ -> (endValue resized).x |> within 0.001 beforeEnd.x
                    , \_ -> (endValue resized).y |> within 0.001 beforeEnd.y
                    ]
                    ()
        , test "mixed axes remap only the px-authored axis" <|
            \_ ->
                let
                    state =
                        Sub.init
                            [ PerspectiveOrigin.initUnitX Unit.Percent
                                >> PerspectiveOrigin.initUnitY Unit.Px
                                >> PerspectiveOrigin.initXY groupName 50 50
                            ]
                            |> (\s ->
                                    Sub.animate s
                                        (PerspectiveOrigin.for groupName
                                            >> PerspectiveOrigin.toXY 90 200
                                            >> PerspectiveOrigin.duration 1000
                                            >> PerspectiveOrigin.easing Linear
                                            >> PerspectiveOrigin.build
                                        )
                               )
                            |> step 500

                    beforeCurrent =
                        current state

                    beforeEnd =
                        endValue state

                    resized =
                        Sub.onResize state <|
                            PerspectiveOrigin.bounds groupName
                                { x = Just { min = 0, max = 1000 }
                                , y = Just { min = 0, max = 100 }
                                , z = Nothing
                                }
                in
                Expect.all
                    [ \_ -> (current resized).x |> within 0.001 beforeCurrent.x
                    , \_ -> (endValue resized).x |> within 0.001 beforeEnd.x
                    , \_ -> (current resized).y |> within 0.5 50
                    , \_ -> (endValue resized).y |> within 0.001 100
                    ]
                    ()
        ]
