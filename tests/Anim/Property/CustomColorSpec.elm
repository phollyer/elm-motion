module Anim.Property.CustomColorSpec exposing (suite)

{-| Public-API tests for `Anim.Property.CustomColor`, exercising the
`ColorProperty` to CSS-property-name mapping and colour rendering through the
Transition engine's `attributes`. The Transition engine renders the target
colour as the element's inline style, so the emitted CSS value is
deterministic and can be queried directly.
-}

import Anim.Engine.Transition as Transition
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


rendered : Transition.AnimState -> Query.Single msg
rendered state =
    Html.div (Transition.attributes "el" state) []
        |> Query.fromHtml


animateColor : ColorProperty -> Color -> Transition.AnimState -> Transition.AnimState
animateColor property target state =
    Transition.animate state
        (Transition.for "el"
            >> CustomColor.begin property
            >> CustomColor.to target
            >> CustomColor.duration 500
            >> CustomColor.end
        )


suite : Test
suite =
    describe "Anim.Property.CustomColor public API"
        [ test "BackgroundColor renders the end colour as background-color" <|
            \_ ->
                Transition.init [ CustomColor.init "el" BackgroundColor (Color.rgb 0 0 0) ]
                    |> animateColor BackgroundColor (Color.rgb 255 0 0)
                    |> rendered
                    |> Query.has [ Selector.style "background-color" "rgb(255, 0, 0)" ]
        , test "OutlineColor maps to the outline-color CSS property" <|
            \_ ->
                Transition.init [ CustomColor.init "el" OutlineColor (Color.rgb 0 0 0) ]
                    |> animateColor OutlineColor (Color.rgb 0 128 255)
                    |> rendered
                    |> Query.has [ Selector.style "outline-color" "rgb(0, 128, 255)" ]
        , test "the Custom escape hatch renders an arbitrary colour property" <|
            \_ ->
                Transition.init [ CustomColor.init "el" (Custom "caret-color") (Color.rgb 0 0 0) ]
                    |> animateColor (Custom "caret-color") (Color.rgb 10 20 30)
                    |> rendered
                    |> Query.has [ Selector.style "caret-color" "rgb(10, 20, 30)" ]
        ]
