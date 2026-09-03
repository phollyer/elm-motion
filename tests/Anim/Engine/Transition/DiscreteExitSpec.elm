module Anim.Engine.Transition.DiscreteExitSpec exposing (..)

{-| Render-level assertions for discrete exit behavior in
`Anim.Engine.Transition`.

These tests assert the inline styles emitted by `Transition.attributes`,
ensuring that the start value remains inline while the animation is running.

-}

import Anim.Engine.Transition as Transition
import Anim.Property.Opacity as Opacity
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
    describe "Anim.Engine.Transition discrete exit behavior"
        [ test "global discrete exit keeps the start value inline while the animation is running" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state <|
                                Transition.discreteExit "display" "block" "none"
                                    >> Transition.for "el"
                                    >> Opacity.begin
                                    >> Opacity.to 0
                                    >> Opacity.duration 500
                                    >> Opacity.end
                       )
                    |> rendered
                    |> Query.has [ Selector.style "display" "block" ]
        , test "local discrete exit keeps the start value inline while the animation is running" <|
            \_ ->
                Transition.init []
                    |> (\state ->
                            Transition.animate state <|
                                Transition.for "el"
                                    >> Transition.discreteExit "display" "block" "none"
                                    >> Opacity.begin
                                    >> Opacity.to 0
                                    >> Opacity.duration 500
                                    >> Opacity.end
                       )
                    |> rendered
                    |> Query.has [ Selector.style "display" "block" ]
        , test "inherited global discrete entry does not force non-entry groups into stylesheet mode" <|
            \_ ->
                Transition.init
                    [ Transition.discreteEntry "display" "block"
                        >> Opacity.init "line" 1
                    ]
                    |> (\state ->
                            Transition.animate state <|
                                Transition.for "line"
                                    >> Opacity.begin
                                    >> Opacity.to 0
                                    >> Opacity.duration 500
                                    >> Opacity.end
                       )
                    |> (\state ->
                            Html.div (Transition.attributes "line" state) []
                                |> Query.fromHtml
                       )
                    |> Query.has [ Selector.style "opacity" "0" ]
        , test "a preceding init entry is not treated as discrete when a later init entry sets discrete entry" <|
            \_ ->
                Transition.init
                    [ Opacity.init "line" 1
                    , Transition.discreteEntry "display" "block"
                        >> Opacity.init "button" 1
                    ]
                    |> (\state ->
                            Transition.animate state <|
                                Transition.for "line"
                                    >> Opacity.begin
                                    >> Opacity.to 0
                                    >> Opacity.duration 500
                                    >> Opacity.end
                       )
                    |> (\state ->
                            Html.div (Transition.attributes "line" state) []
                                |> Query.fromHtml
                       )
                    |> Query.hasNot [ Selector.style "display" "block" ]
        ]
