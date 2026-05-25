module Anim.Engine.Sub.WillChangeSpec exposing (suite)

{-| Verifies the Sub engine emits a `will-change` declaration covering
the properties currently animating. The Sub engine renders all
transforms via the composite `transform:` property, so every
transform-family property collapses to a single `transform` entry.

The clearing-on-complete branch piggybacks on the same `AnimGroup.isComplete`
gate used elsewhere; infinite-loop animations never reach `isComplete`
and so retain `will-change` indefinitely.

-}

import Anim.Engine.Sub as Sub
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


rendered : Sub.AnimState -> Query.Single msg
rendered state =
    Html.div (Sub.attributes "el" state) []
        |> Query.fromHtml


suite : Test
suite =
    describe "Sub will-change"
        [ test "translate collapses to transform" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Translate.for "el"
                                    >> Translate.toXY 100 0
                                    >> Translate.duration 500
                                    >> Translate.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "transform" ]
        , test "scale collapses to transform" <|
            \_ ->
                Sub.init [ Scale.init "el" 1 ]
                    |> (\state ->
                            Sub.animate state
                                (Scale.for "el"
                                    >> Scale.to 1.5
                                    >> Scale.duration 500
                                    >> Scale.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "transform" ]
        , test "translate + rotate + scale + skew all collapse to a single transform" <|
            \_ ->
                Sub.init
                    [ Translate.initXY "el" 0 0
                    , Rotate.initZ "el" 0
                    , Scale.init "el" 1
                    , Skew.initXY "el" 0 0
                    ]
                    |> (\state ->
                            Sub.animate state
                                (Translate.for "el"
                                    >> Translate.toXY 100 0
                                    >> Translate.duration 500
                                    >> Translate.build
                                    >> Rotate.for "el"
                                    >> Rotate.toZ 45
                                    >> Rotate.duration 500
                                    >> Rotate.build
                                    >> Scale.for "el"
                                    >> Scale.to 1.5
                                    >> Scale.duration 500
                                    >> Scale.build
                                    >> Skew.for "el"
                                    >> Skew.toXY 10 5
                                    >> Skew.duration 500
                                    >> Skew.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "transform" ]
        , test "opacity + translate produce opacity, transform" <|
            \_ ->
                Sub.init
                    [ Opacity.init "el" 0
                    , Translate.initXY "el" 0 0
                    ]
                    |> (\state ->
                            Sub.animate state
                                (Opacity.for "el"
                                    >> Opacity.to 1
                                    >> Opacity.duration 500
                                    >> Opacity.build
                                    >> Translate.for "el"
                                    >> Translate.toXY 100 0
                                    >> Translate.duration 500
                                    >> Translate.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "opacity, transform" ]
        , test "size emits width and height" <|
            \_ ->
                Sub.init [ Size.initHW "el" 100 100 ]
                    |> (\state ->
                            Sub.animate state
                                (Size.for "el"
                                    >> Size.toHW 200 150
                                    >> Size.duration 500
                                    >> Size.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "width, height" ]
        , test "perspective-origin uses its CSS name" <|
            \_ ->
                Sub.init [ PerspectiveOrigin.initXY "el" 50 50 ]
                    |> (\state ->
                            Sub.animate state
                                (PerspectiveOrigin.for "el"
                                    >> PerspectiveOrigin.cssUnit Unit.Percent
                                    >> PerspectiveOrigin.toXY 90 10
                                    >> PerspectiveOrigin.duration 500
                                    >> PerspectiveOrigin.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "perspective-origin" ]
        , test "custom property uses its CSS name" <|
            \_ ->
                Sub.init [ Custom.init "el" (Custom.BorderRadius Unit.Px) 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Custom.for "el" (Custom.BorderRadius Unit.Px)
                                    >> Custom.to 10
                                    >> Custom.duration 500
                                    >> Custom.build
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "will-change" "border-radius" ]
        ]
