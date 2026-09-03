module Anim.Engine.Transition.SequentialUnitSwitchSpec exposing (suite)

{-| Render-level assertions for sequential css unit switching in
`Anim.Engine.Transition`.

These tests assert the inline styles emitted by `Transition.attributes`,
ensuring that a second animate call on the same group/property immediately
uses the new unit.

-}

import Anim.Engine.Transition as Transition
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
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
    describe "Anim.Engine.Transition sequential unit switching"
        [ test "mid-stream translate animate uses the second phase unit" <|
            \_ ->
                Transition.init [ Translate.initXY "el" 0 0 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.cssUnitX Cqw
                                    >> Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 88
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.cssUnitX Vw
                                    >> Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 20
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> rendered
                    |> Query.has [ Selector.style "translate" "20vw 0px 0px" ]
        , test "second size animate uses the new unit for width and height" <|
            \_ ->
                Transition.init [ Size.initHW "el" 80 120 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.cssUnit Cqmin
                                    >> Transition.for "el"
                                    >> Size.begin
                                    >> Size.toHW 80 120
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.cssUnit Vh
                                    >> Transition.for "el"
                                    >> Size.begin
                                    >> Size.toHW 40 60
                                    >> Size.duration 500
                                    >> Size.end
                                )
                       )
                    |> rendered
                    |> Query.has
                        [ Selector.style "width" "60vh"
                        , Selector.style "height" "40vh"
                        ]
        ]
