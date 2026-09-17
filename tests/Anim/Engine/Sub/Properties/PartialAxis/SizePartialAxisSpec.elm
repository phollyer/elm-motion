module Anim.Engine.Sub.Properties.PartialAxis.SizePartialAxisSpec exposing (suite)

{-| Render-level assertions for partial-axis size animations in
`Anim.Engine.Sub`.

These tests lock the intended behavior before refactoring:

  - First-use `toH` should not emit width.
  - First-use `toW` should not emit height.
  - Once an axis has been animated by the group, subsequent single-axis
    updates may keep emitting that previously-owned axis.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Size as Size
import Expect
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


rendered : Sub.AnimState -> Query.Single msg
rendered state =
    Html.div (Sub.attributes "el" state) []
        |> Query.fromHtml


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


suite : Test
suite =
    describe "Anim.Engine.Sub size partial-axis styles"
        [ test "first-use Size.toH emits height and omits width" <|
            \_ ->
                let
                    runningState =
                        Sub.init []
                            |> (\state ->
                                    Sub.animate state
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toH 240
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    settledState =
                        runningState
                            |> step 500
                in
                Expect.all
                    [ \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "height" "240px" ]
                    , \_ ->
                        rendered settledState
                            |> Query.hasNot [ Selector.style "width" "0px" ]
                    , \_ ->
                        rendered runningState
                            |> Query.has [ Selector.style "will-change" "height" ]
                    ]
                    ()
        , test "first-use Size.toW emits width and omits height" <|
            \_ ->
                let
                    runningState =
                        Sub.init []
                            |> (\state ->
                                    Sub.animate state
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toW 360
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    settledState =
                        runningState
                            |> step 500
                in
                Expect.all
                    [ \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "width" "360px" ]
                    , \_ ->
                        rendered settledState
                            |> Query.hasNot [ Selector.style "height" "0px" ]
                    , \_ ->
                        rendered runningState
                            |> Query.has [ Selector.style "will-change" "width" ]
                    ]
                    ()
        , test "after Size.toHW, Size.toH keeps previously-owned width" <|
            \_ ->
                let
                    runningState =
                        Sub.init []
                            |> (\s ->
                                    Sub.animate s
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toHW 120 300
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> step 500
                            |> (\s ->
                                    Sub.animate s
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toH 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    settledState =
                        runningState
                            |> step 500
                in
                Expect.all
                    [ \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "width" "300px" ]
                    , \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "height" "80px" ]
                    , \_ ->
                        rendered runningState
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        , test "after Size.toHW, Size.toW keeps previously-owned height" <|
            \_ ->
                let
                    runningState =
                        Sub.init []
                            |> (\s ->
                                    Sub.animate s
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toHW 120 300
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> step 500
                            |> (\s ->
                                    Sub.animate s
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toW 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    settledState =
                        runningState
                            |> step 500
                in
                Expect.all
                    [ \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "width" "80px" ]
                    , \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "height" "120px" ]
                    , \_ ->
                        rendered runningState
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        , test "after Size.toH, Size.toW keeps previously-owned height" <|
            \_ ->
                let
                    runningState =
                        Sub.init []
                            |> (\state ->
                                    Sub.animate state
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toH 120
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> step 500
                            |> (\state ->
                                    Sub.animate state
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toW 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    settledState =
                        runningState
                            |> step 500
                in
                Expect.all
                    [ \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "width" "80px" ]
                    , \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "height" "120px" ]
                    , \_ ->
                        rendered runningState
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        , test "after Size.toW, Size.toH keeps previously-owned width" <|
            \_ ->
                let
                    runningState =
                        Sub.init []
                            |> (\state ->
                                    Sub.animate state
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toW 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> step 500
                            |> (\state ->
                                    Sub.animate state
                                        (Sub.for "el"
                                            >> Size.begin
                                            >> Size.toH 120
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    settledState =
                        runningState
                            |> step 500
                in
                Expect.all
                    [ \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "width" "80px" ]
                    , \_ ->
                        rendered settledState
                            |> Query.has [ Selector.style "height" "120px" ]
                    , \_ ->
                        rendered runningState
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        ]
