module Anim.Engine.Sub.TransformOrderSpec exposing (suite)

{-| Tests that `Sub.transformOrder` propagates from the public API
through to the inline `transform` style emitted by `Sub.attributes`.

The Sub engine renders an inline `transform` style whose
sub-transforms appear in the order configured by `transformOrder`.
By running an animation halfway and inspecting the rendered style
string, we can confirm the order is honored end-to-end.

-}

import Anim.Engine.Sub as Sub
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Html
import Motion.Easing exposing (Easing(..))
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


animateAll : (Sub.EngineBuilder -> Sub.EngineBuilder) -> Sub.AnimState -> Sub.AnimState
animateAll extra state =
    Sub.animate state
        (extra
            >> Sub.for "el"
            >> Translate.begin
            >> Translate.fromXY 0 0
            >> Translate.toXY 100 50
            >> Translate.duration 1000
            >> Translate.easing Linear
            >> Translate.end
            >> Rotate.begin
            >> Rotate.fromZ 0
            >> Rotate.toZ 90
            >> Rotate.duration 1000
            >> Rotate.easing Linear
            >> Rotate.end
            >> Scale.begin
            >> Scale.fromXY 1 1
            >> Scale.toXY 2 2
            >> Scale.duration 1000
            >> Scale.easing Linear
            >> Scale.end
        )


suite : Test
suite =
    describe "Sub.transformOrder (public API)"
        [ test "default order renders translate3d -> rotateZ -> scaleX/scaleY" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> animateAll identity
                    |> step 500
                    |> rendered
                    |> Query.has
                        [ Selector.style "transform"
                            "translate3d(50px, 25px, 0px) rotateZ(45deg) scaleX(1.5) scaleY(1.5)"
                        ]
        , test "custom order [Scale, Rotate, Translate] renders scale first" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> animateAll (Sub.transformOrder [ Scale, Rotate, Translate ])
                    |> step 500
                    |> rendered
                    |> Query.has
                        [ Selector.style "transform"
                            "scaleX(1.5) scaleY(1.5) rotateZ(45deg) translate3d(50px, 25px, 0px)"
                        ]
        , test "custom order [Rotate, Scale, Translate] renders rotate first" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> animateAll (Sub.transformOrder [ Rotate, Scale, Translate ])
                    |> step 500
                    |> rendered
                    |> Query.has
                        [ Selector.style "transform"
                            "rotateZ(45deg) scaleX(1.5) scaleY(1.5) translate3d(50px, 25px, 0px)"
                        ]
        , test "transformOrder is a valid pipeline element (chains with other setters)" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> animateAll
                        (Sub.transformOrder [ Scale, Translate, Rotate ]
                            >> Sub.easing Linear
                        )
                    |> step 500
                    |> rendered
                    |> Query.has
                        [ Selector.style "transform"
                            "scaleX(1.5) scaleY(1.5) translate3d(50px, 25px, 0px) rotateZ(45deg)"
                        ]
        ]
