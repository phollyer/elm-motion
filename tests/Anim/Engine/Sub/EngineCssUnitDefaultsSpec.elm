module Anim.Engine.Sub.EngineCssUnitDefaultsSpec exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Expect
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


suite : Test
suite =
    describe "Sub engine-level cssUnit defaults"
        [ test "engine-level cssUnit axis defaults apply to translate" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Sub.cssUnitX Unit.Vw
                                    >> Sub.cssUnitY Unit.Vh
                                    >> Translate.for "el"
                                    >> Translate.toXY 100 50
                                    >> Translate.duration 1000
                                    >> Translate.easing Linear
                                    >> Translate.build
                                )
                       )
                    |> step 500
                    |> rendered
                    |> Query.has [ Selector.style "transform" "translate3d(50vw, 25vh, 0px)" ]
        , test "engine-level cssUnit axis defaults apply to size" <|
            \_ ->
                Sub.init [ Size.initHW "el" 100 200 ]
                    |> (\state ->
                            Sub.animate state
                                (Sub.cssUnitX Unit.Vw
                                    >> Sub.cssUnitY Unit.Vh
                                    >> Size.for "el"
                                    >> Size.toHW 200 400
                                    >> Size.duration 1000
                                    >> Size.easing Linear
                                    >> Size.build
                                )
                       )
                    |> step 500
                    |> rendered
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "300vw" ]
                        , Query.has [ Selector.style "height" "150vh" ]
                        ]
        , test "engine-level cssUnit axis defaults apply to perspective-origin" <|
            \_ ->
                Sub.init [ PerspectiveOrigin.initXY "el" 50 50 ]
                    |> (\state ->
                            Sub.animate state
                                (Sub.cssUnitX Unit.Vw
                                    >> Sub.cssUnitY Unit.Vh
                                    >> PerspectiveOrigin.for "el"
                                    >> PerspectiveOrigin.toXY 90 10
                                    >> PerspectiveOrigin.duration 1000
                                    >> PerspectiveOrigin.easing Linear
                                    >> PerspectiveOrigin.build
                                )
                       )
                    |> step 500
                    |> rendered
                    |> Query.has [ Selector.style "perspective-origin" "70vw 30vh" ]
        ]
