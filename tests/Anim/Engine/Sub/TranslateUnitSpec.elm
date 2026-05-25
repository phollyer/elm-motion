module Anim.Engine.Sub.TranslateUnitSpec exposing (suite)

{-| Verifies that Sub translate rendering preserves configured CSS units
instead of coercing all axes to px.
-}

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
    describe "Sub length unit rendering"
        [ test "translate initUnit values render in transform style" <|
            \_ ->
                Sub.init
                    [ Translate.initUnitX Unit.Cqw
                        >> Translate.initUnitY Unit.Cqh
                        >> Translate.initXY "el" 40 20
                    ]
                    |> rendered
                    |> Query.has [ Selector.style "transform" "translate3d(40cqw, 20cqh, 0px)" ]
        , test "translate animate cssUnit values render while running" <|
            \_ ->
                Sub.init [ Translate.initXY "el" 0 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Translate.for "el"
                                    >> Translate.cssUnitX Unit.Vw
                                    >> Translate.cssUnitY Unit.Vh
                                    >> Translate.toXY 100 50
                                    >> Translate.duration 1000
                                    >> Translate.easing Linear
                                    >> Translate.build
                                )
                       )
                    |> step 500
                    |> rendered
                    |> Query.has [ Selector.style "transform" "translate3d(50vw, 25vh, 0px)" ]
        , test "size init units render width/height with configured suffixes" <|
            \_ ->
                let
                    q =
                        Sub.init
                            [ Size.initUnitWidth Unit.Cqw
                                >> Size.initUnitHeight Unit.Cqh
                                >> Size.initHW "el" 80 120
                            ]
                            |> rendered
                in
                Expect.all
                    [ \_ -> q |> Query.has [ Selector.style "width" "120cqw" ]
                    , \_ -> q |> Query.has [ Selector.style "height" "80cqh" ]
                    ]
                    ()
        , test "perspective-origin animate cssUnit values render while running" <|
            \_ ->
                Sub.init [ PerspectiveOrigin.initXY "el" 50 50 ]
                    |> (\state ->
                            Sub.animate state
                                (PerspectiveOrigin.for "el"
                                    >> PerspectiveOrigin.cssUnitX Unit.Vw
                                    >> PerspectiveOrigin.cssUnitY Unit.Vh
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
