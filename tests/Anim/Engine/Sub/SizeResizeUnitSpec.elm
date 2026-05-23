module Anim.Engine.Sub.SizeResizeUnitSpec exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Size as Size
import Anim.Resize as Resize
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


current : Sub.AnimState -> { width : Float, height : Float }
current state =
    Sub.getSizeCurrent groupName state
        |> Maybe.withDefault { width = -1, height = -1 }


endValue : Sub.AnimState -> { width : Float, height : Float }
endValue state =
    Sub.getSizeEnd groupName state
        |> Maybe.withDefault { width = -1, height = -1 }


suite : Test
suite =
    describe "Sub Size onResize behavior"
        [ test "px-authored size is unchanged by Resize.bounds" <|
            \_ ->
                let
                    state =
                        Sub.init [ Size.initHW groupName 100 200 ]
                            |> (\s ->
                                    Sub.animate s
                                        (Size.for groupName
                                            >> Size.toHW 200 400
                                            >> Size.duration 1000
                                            >> Size.easing Linear
                                            >> Size.build
                                        )
                               )
                            |> step 500

                    beforeCurrent =
                        current state

                    beforeEnd =
                        endValue state

                    resized =
                        Sub.onResize state <|
                            Resize.bounds groupName
                                { x = Just { min = 0, max = 1000 }
                                , y = Just { min = 0, max = 1000 }
                                , z = Nothing
                                }
                in
                Expect.all
                    [ \_ -> (current resized).width |> within 0.001 beforeCurrent.width
                    , \_ -> (current resized).height |> within 0.001 beforeCurrent.height
                    , \_ -> (endValue resized).width |> within 0.001 beforeEnd.width
                    , \_ -> (endValue resized).height |> within 0.001 beforeEnd.height
                    ]
                    ()
        , test "non-px size units are unchanged by Resize.bounds" <|
            \_ ->
                let
                    state =
                        Sub.init [ Size.initHW groupName 100 200 ]
                            |> (\s ->
                                    Sub.animate s
                                        (Size.for groupName
                                            >> Size.cssUnit Unit.Percent
                                            >> Size.toHW 200 400
                                            >> Size.duration 1000
                                            >> Size.easing Linear
                                            >> Size.build
                                        )
                               )
                            |> step 500

                    beforeCurrent =
                        current state

                    beforeEnd =
                        endValue state

                    resized =
                        Sub.onResize state <|
                            Resize.bounds groupName
                                { x = Just { min = 0, max = 1000 }
                                , y = Just { min = 0, max = 1000 }
                                , z = Nothing
                                }
                in
                Expect.all
                    [ \_ -> (current resized).width |> within 0.001 beforeCurrent.width
                    , \_ -> (current resized).height |> within 0.001 beforeCurrent.height
                    , \_ -> (endValue resized).width |> within 0.001 beforeEnd.width
                    , \_ -> (endValue resized).height |> within 0.001 beforeEnd.height
                    ]
                    ()
        ]
