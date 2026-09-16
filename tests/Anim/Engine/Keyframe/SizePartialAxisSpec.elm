module Anim.Engine.Keyframe.SizePartialAxisSpec exposing (suite)

{-| Render-level and keyframe-CSS assertions for partial-axis size animations
in `Anim.Engine.Keyframe`.

These tests lock the expected behavior before any engine changes:

  - First-use `toH` should not materialize width bookkeeping.
  - First-use `toW` should not materialize height bookkeeping.
  - Once an axis has been animated by the group, subsequent single-axis
    updates may keep emitting that previously-owned axis.

-}

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Size as Size
import Expect
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


rendered : Keyframe.AnimState -> Query.Single msg
rendered state =
    Html.div (Keyframe.attributes "el" state) []
        |> Query.fromHtml


cssFor : Keyframe.AnimState -> String
cssFor state =
    Keyframe.maybeString "el" state
        |> Maybe.withDefault ""


suite : Test
suite =
    describe "Anim.Engine.Keyframe size partial-axis styles"
        [ test "first-use Size.toH emits height and omits width" <|
            \_ ->
                let
                    state =
                        Keyframe.init []
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toH 240
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    css =
                        cssFor state
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "height: 240px;"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "width: 0px;"
                            |> Expect.equal False
                    , \_ ->
                        rendered state
                            |> Query.has [ Selector.style "will-change" "height" ]
                    ]
                    ()
        , test "first-use Size.toW emits width and omits height" <|
            \_ ->
                let
                    state =
                        Keyframe.init []
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toW 360
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    css =
                        cssFor state
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "width: 360px;"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "height: 0px;"
                            |> Expect.equal False
                    , \_ ->
                        rendered state
                            |> Query.has [ Selector.style "will-change" "width" ]
                    ]
                    ()
        , test "after Size.toHW, Size.toH keeps previously-owned width" <|
            \_ ->
                let
                    state =
                        Keyframe.init []
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toHW 120 300
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toH 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    css =
                        cssFor state
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "width: 300px;"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "height: 80px;"
                            |> Expect.equal True
                    , \_ ->
                        rendered state
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        , test "after Size.toHW, Size.toW keeps previously-owned height" <|
            \_ ->
                let
                    state =
                        Keyframe.init []
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toHW 120 300
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toW 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    css =
                        cssFor state
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "width: 80px;"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "height: 120px;"
                            |> Expect.equal True
                    , \_ ->
                        rendered state
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        , test "after Size.toH, Size.toW keeps previously-owned height" <|
            \_ ->
                let
                    state =
                        Keyframe.init []
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toH 120
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toW 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    css =
                        cssFor state
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "width: 80px;"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "height: 120px;"
                            |> Expect.equal True
                    , \_ ->
                        rendered state
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        , test "after Size.toW, Size.toH keeps previously-owned width" <|
            \_ ->
                let
                    state =
                        Keyframe.init []
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toW 80
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )
                            |> (\s ->
                                    Keyframe.animate s
                                        (Keyframe.for "el"
                                            >> Size.begin
                                            >> Size.toH 120
                                            >> Size.duration 500
                                            >> Size.end
                                        )
                               )

                    css =
                        cssFor state
                in
                Expect.all
                    [ \_ ->
                        css
                            |> String.contains "width: 80px;"
                            |> Expect.equal True
                    , \_ ->
                        css
                            |> String.contains "height: 120px;"
                            |> Expect.equal True
                    , \_ ->
                        rendered state
                            |> Query.has [ Selector.style "will-change" "width, height" ]
                    ]
                    ()
        ]
