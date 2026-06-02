module Anim.Engine.Sub.OnResizeSizeTest exposing (suite)

{-| Tests for the size path of `Sub.onResize`. The math reuses the same
property-agnostic `Resize.applyAxis` helper as Translate / Scale, so this
suite focuses on verifying the wiring (group-wide default, single-axis,
both-axes, settled animation, and multi-group dispatch).
-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Size as Size
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


initialState : Sub.AnimState
initialState =
    Sub.init
        [ Size.initHW groupName 100 200
        ]


sizeWH : Float -> Float -> Sub.EngineBuilder -> Sub.EngineBuilder
sizeWH width height =
    Size.for groupName
        >> Size.toHW height width
        >> Size.duration 1000
        >> Size.easing Linear
        >> Size.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


runPast : Float -> Sub.AnimState -> Sub.AnimState
runPast durationMs initial =
    List.foldl (\_ acc -> step 50 acc) initial (List.range 1 (ceiling (durationMs / 50)))


currentWH : Sub.AnimState -> { width : Float, height : Float }
currentWH state =
    Sub.getSizeCurrent groupName state
        |> Maybe.withDefault { width = -1, height = -1 }


endWH : Sub.AnimState -> { width : Float, height : Float }
endWH state =
    Sub.getSizeEnd groupName state
        |> Maybe.withDefault { width = -1, height = -1 }


within : Float -> Float -> Float -> Expect.Expectation
within tolerance expected actual =
    if abs (actual - expected) <= tolerance then
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


suite : Test
suite =
    describe "Anim.Engine.Sub.onResize - size"
        [ test "Proportional remaps a mid-flight one-shot size into the new range" <|
            \_ ->
                let
                    -- 100 -> 500 width, 200 -> 600 height, 1000ms linear.
                    state =
                        initialState
                            |> (\s -> Sub.animate s (sizeWH 500 600))
                            |> step 500

                    -- After 500ms: width=300, height=400.
                    bounds =
                        { width = Just { min = 0, max = 1000 }
                        , height = Just { min = 0, max = 1200 }
                        }

                    resized =
                        Sub.onResize state <|
                            Size.bounds groupName bounds

                    cur =
                        currentWH resized
                in
                Expect.all
                    -- Old width leg [100..500], current=300, ratio=(300-100)/400=0.5
                    -- New leg [0..1000] -> 0 + 0.5 * 1000 = 500.
                    [ \_ -> cur.width |> within 0.001 500

                    -- Old height leg [200..600], current=400, ratio=0.5
                    -- New leg [0..1200] -> 0 + 0.5 * 1200 = 600.
                    , \_ -> cur.height |> within 0.001 600
                    ]
                    ()
        , test "Empty bounds (both Nothing) is a no-op" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (sizeWH 500 600))
                            |> step 500

                    before =
                        currentWH state

                    resized =
                        Sub.onResize state <|
                            Size.bounds groupName
                                { width = Nothing, height = Nothing }

                    after =
                        currentWH resized
                in
                Expect.all
                    [ \_ -> after.width |> within 0.001 before.width
                    , \_ -> after.height |> within 0.001 before.height
                    ]
                    ()
        , test "settled one-shot adopts the new endpoint on both axes" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (sizeWH 500 600))
                            |> runPast 1500

                    bounds =
                        { width = Just { min = 0, max = 250 }
                        , height = Just { min = 0, max = 300 }
                        }

                    resized =
                        Sub.onResize state <|
                            Size.bounds groupName bounds

                    cur =
                        currentWH resized

                    e =
                        endWH resized
                in
                Expect.all
                    [ \_ -> cur.width |> within 0.001 250
                    , \_ -> cur.height |> within 0.001 300
                    , \_ -> e.width |> within 0.001 250
                    , \_ -> e.height |> within 0.001 300
                    ]
                    ()
        , test "single-axis bounds leaves the unspecified axis untouched" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (sizeWH 500 600))
                            |> runPast 1500

                    -- Only resize width; leave height alone.
                    bounds =
                        { width = Just { min = 0, max = 1000 }
                        , height = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Size.bounds groupName bounds

                    cur =
                        currentWH resized
                in
                Expect.all
                    [ \_ -> cur.width |> within 0.001 1000
                    , \_ -> cur.height |> within 0.001 600
                    ]
                    ()
        , test "single onResize call updates two anim groups independently" <|
            \_ ->
                let
                    secondGroup =
                        "card"

                    state =
                        Sub.init
                            [ Size.initHW groupName 100 200
                            , Size.initHW secondGroup 100 200
                            ]
                            |> (\s ->
                                    Sub.animate s
                                        (Size.for groupName
                                            >> Size.toHW 600 500
                                            >> Size.duration 1000
                                            >> Size.easing Linear
                                            >> Size.build
                                            >> Size.for secondGroup
                                            >> Size.toHW 600 500
                                            >> Size.duration 1000
                                            >> Size.easing Linear
                                            >> Size.build
                                        )
                               )
                            |> runPast 1500

                    boxBounds =
                        { width = Just { min = 0, max = 250 }
                        , height = Just { min = 0, max = 300 }
                        }

                    cardBounds =
                        { width = Just { min = 0, max = 750 }
                        , height = Just { min = 0, max = 900 }
                        }

                    resized =
                        Sub.onResize state <|
                            Size.bounds groupName boxBounds
                                >> Size.bounds secondGroup cardBounds

                    boxC =
                        Sub.getSizeCurrent groupName resized
                            |> Maybe.withDefault { width = -1, height = -1 }

                    cardC =
                        Sub.getSizeCurrent secondGroup resized
                            |> Maybe.withDefault { width = -1, height = -1 }
                in
                Expect.all
                    [ \_ -> boxC.width |> within 0.001 250
                    , \_ -> boxC.height |> within 0.001 300
                    , \_ -> cardC.width |> within 0.001 750
                    , \_ -> cardC.height |> within 0.001 900
                    ]
                    ()
        ]
