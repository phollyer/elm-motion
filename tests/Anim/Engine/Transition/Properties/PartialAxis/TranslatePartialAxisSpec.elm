module Anim.Engine.Transition.Properties.PartialAxis.TranslatePartialAxisSpec exposing (suite)

{-| Render-level assertions for partial-axis translate animations in
`Anim.Engine.Transition`.

These tests lock the intended behavior before implementation:

  - First-use `toX` should not write Y/Z axes.
  - First-use `toY` should not write X/Z axes.
  - First-use `toZ` should not write X/Y axes.
  - First-use `toXY`/`toXZ`/`toYZ` should omit only the untouched axis.
  - Once axes have been animated by the group, subsequent subset updates
    may keep emitting previously-owned axes.

-}

import Anim.Engine.Transition as Transition
import Anim.Property.Translate as Translate
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
    describe "Anim.Engine.Transition translate partial-axis styles"
        [ test "first-use Translate.toX emits only X and omits untouched axes" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 120
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "translate" "120px" ]
                        , Query.hasNot [ Selector.style "translate" "120px 0px 0px" ]
                        ]
        , test "first-use Translate.toY emits only Y and omits untouched axes" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toY 240
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateY(240px)" ]
                        , Query.hasNot [ Selector.style "translate" "0px 240px 0px" ]
                        ]
        , test "first-use Translate.toZ emits only Z and omits untouched axes" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toZ 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateZ(32px)" ]
                        , Query.hasNot [ Selector.style "translate" "0px 0px 32px" ]
                        ]
        , test "first-use Translate.toXY emits XY and omits Z" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 120 240
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "translate" "120px 240px" ]
                        , Query.hasNot [ Selector.style "translate" "120px 240px 0px" ]
                        ]
        , test "first-use Translate.toXZ emits XZ and omits Y" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXZ 120 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateX(120px) translateZ(32px)" ]
                        , Query.hasNot [ Selector.style "translate" "120px 0px 32px" ]
                        ]
        , test "first-use Translate.toYZ emits YZ and omits X" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toYZ 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateY(240px) translateZ(32px)" ]
                        , Query.hasNot [ Selector.style "translate" "0px 240px 32px" ]
                        ]
        , test "first-use Translate.toXYZ emits all axes" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXYZ 120 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "translate" "120px 240px 32px" ]
        , test "after Translate.toXYZ, Translate.toX keeps previously-owned YZ" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXYZ 120 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "translate" "60px 240px 32px" ]
        , test "after Translate.toXYZ, Translate.toY keeps previously-owned XZ" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXYZ 120 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toY 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "translate" "120px 60px 32px" ]
        , test "after Translate.toXYZ, Translate.toZ keeps previously-owned XY" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXYZ 120 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toZ 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "translate" "120px 240px 60px" ]
        , test "after Translate.toXY, Translate.toX keeps previously-owned Y" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 120 240
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "translate" "60px 240px" ]
                        , Query.hasNot [ Selector.style "translate" "60px 240px 0px" ]
                        ]
        , test "after Translate.toXY, Translate.toY keeps previously-owned X, and omits Z" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 120 240
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toY 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "translate" "120px 60px" ]
                        , Query.hasNot [ Selector.style "translate" "120px 60px 0px" ]
                        ]
        , test "after Translate.toXZ, Translate.toX keeps previously-owned Z, and omits Y" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXZ 120 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateX(60px) translateZ(32px)" ]
                        , Query.hasNot [ Selector.style "translate" "60px 0px 32px" ]
                        ]
        , test "after Translate.toXZ, Translate.toZ keeps previously-owned X, and omits Y" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXZ 120 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toZ 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateX(120px) translateZ(60px)" ]
                        , Query.hasNot [ Selector.style "translate" "120px 0px 60px" ]
                        ]
        , test "after Translate.toYZ, Translate.toY keeps previously-owned Z, and omits X" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toYZ 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toY 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateY(60px) translateZ(32px)" ]
                        , Query.hasNot [ Selector.style "translate" "0px 60px 32px" ]
                        ]
        , test "after Translate.toYZ, Translate.toZ keeps previously-owned Y, and omits X" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toYZ 240 32
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toZ 60
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translateY(240px) translateZ(60px)" ]
                        , Query.hasNot [ Selector.style "translate" "0px 240px 60px" ]
                        ]
        ]
