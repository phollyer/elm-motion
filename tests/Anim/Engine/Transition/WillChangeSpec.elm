module Anim.Engine.Transition.WillChangeSpec exposing (suite)

{-| Verifies the Transition engine emits a `will-change` declaration
covering the properties currently animating. The Transition engine
renders transforms as the modern individual CSS properties
(`translate:` / `scale:`) and falls back to the composite `transform:`
for rotate / skew, so `will-change` mirrors that distinction.

The clearing-on-complete branch piggybacks on the same `AnimGroup.isComplete`
gate used for `discreteExitAttrs`; that gate is covered indirectly by
the existing discrete-exit tests.

-}

import Anim.Engine.Transition as Transition
import Anim.Property.Custom as Custom
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
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
    describe "Transition will-change"
        [ test "translate uses the individual translate name" <|
            \_ ->
                Transition.init [ Translate.initXY "el" 0 0 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 100 0
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "translate" ]
        , test "scale uses the individual scale name" <|
            \_ ->
                Transition.init [ Scale.init "el" 1 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Scale.begin
                                    >> Scale.to 1.5
                                    >> Scale.duration 500
                                    >> Scale.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "scale" ]
        , test "rotate falls back to transform" <|
            \_ ->
                Transition.init [ Rotate.initZ "el" 0 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Rotate.begin
                                    >> Rotate.toZ 90
                                    >> Rotate.duration 500
                                    >> Rotate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "transform" ]
        , test "rotate + skew collapse to a single transform entry" <|
            \_ ->
                Transition.init
                    [ Rotate.initZ "el" 0
                    , Skew.initXY "el" 0 0
                    ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Rotate.begin
                                    >> Rotate.toZ 45
                                    >> Rotate.duration 500
                                    >> Rotate.end
                                )
                                |> (\s ->
                                        Transition.animate s
                                            (Transition.for "el"
                                                >> Skew.begin
                                                >> Skew.toXY 10 5
                                                >> Skew.duration 500
                                                >> Skew.end
                                            )
                                   )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "transform" ]
        , test "opacity + translate stay separate" <|
            \_ ->
                Transition.init
                    [ Opacity.init "el" 0
                    , Translate.initXY "el" 0 0
                    ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Opacity.begin
                                    >> Opacity.to 1
                                    >> Opacity.duration 500
                                    >> Opacity.end
                                )
                                |> (\s ->
                                        Transition.animate s
                                            (Transition.for "el"
                                                >> Translate.begin
                                                >> Translate.toXY 100 0
                                                >> Translate.duration 500
                                                >> Translate.end
                                            )
                                   )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "opacity, translate" ]
        , test "size emits width and height" <|
            \_ ->
                Transition.init [ Size.initHW "el" 100 100 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Size.begin
                                    >> Size.toHW 200 150
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "width, height" ]
        , test "perspective-origin uses its CSS name" <|
            \_ ->
                Transition.init [ PerspectiveOrigin.initXY "el" 50 50 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> PerspectiveOrigin.begin
                                    >> PerspectiveOrigin.toXY 90 10
                                    >> PerspectiveOrigin.duration 500
                                    >> PerspectiveOrigin.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "perspective-origin" ]
        , test "custom property uses its CSS name" <|
            \_ ->
                Transition.init [ Custom.init "el" (Custom.BorderRadius Unit.Px) 0 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "el"
                                    >> Custom.begin (Custom.BorderRadius Unit.Px)
                                    >> Custom.to 10
                                    >> Custom.duration 500
                                    >> Custom.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "border-radius" ]
        ]
