module Anim.Engine.Transition.SizePartialAxisSpec exposing (suite)

{-| Render-level assertions for partial-axis size animations in
`Anim.Engine.Transition`.

These tests lock the intended behavior before refactoring:

  - First-use `toH` should not emit width.
  - First-use `toW` should not emit height.
  - Once an axis has been animated by the group, subsequent single-axis
    updates may keep emitting that previously-owned axis.

-}

import Anim.Engine.Transition as Transition
import Anim.Property.Size as Size
import Expect
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


rendered : Transition.AnimState -> Query.Single msg
rendered state =
    Html.div (Transition.attributes "el" state) []
        |> Query.fromHtml


suite : Test
suite =
    describe "Anim.Engine.Transition size partial-axis styles"
        [ test "first-use Size.toH emits height and omits width" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toH 240
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "height" "240px" ]
                        , Query.hasNot [ Selector.style "width" "0px" ]
                        , Query.has [ Selector.style "will-change" "height" ]
                        , Query.has [ Selector.style "transition" "height 500ms ease-in-out 0ms" ]
                        ]
        , test "first-use Size.toW emits width and omits height" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toW 360
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "360px" ]
                        , Query.hasNot [ Selector.style "height" "0px" ]
                        , Query.has [ Selector.style "will-change" "width" ]
                        , Query.has [ Selector.style "transition" "width 500ms ease-in-out 0ms" ]
                        ]
        , test "after Size.toHW, Size.toH keeps previously-owned width" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toHW 120 300
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toH 80
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "300px" ]
                        , Query.has [ Selector.style "height" "80px" ]
                        , Query.has [ Selector.style "will-change" "width, height" ]
                        , Query.has [ Selector.style "transition" "width 500ms ease-in-out 0ms, height 500ms ease-in-out 0ms" ]
                        ]
        , test "after Size.toHW, Size.toW keeps previously-owned height" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toHW 120 300
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toW 200
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "200px" ]
                        , Query.has [ Selector.style "height" "120px" ]
                        ]
        , test "after Size.toH, Size.toW keeps previously-owned height" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toH 120
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toW 200
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "200px" ]
                        , Query.has [ Selector.style "height" "120px" ]
                        ]
        , test "after Size.toW, Size.toH keeps previously-owned width" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toW 300
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toH 120
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "300px" ]
                        , Query.has [ Selector.style "height" "120px" ]
                        ]
        ]
