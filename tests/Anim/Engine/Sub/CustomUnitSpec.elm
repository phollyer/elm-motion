module Anim.Engine.Sub.CustomUnitSpec exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Custom as Custom
import Anim.Unit as Unit
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
    describe "Sub custom property unit rendering"
        [ test "typed Unit values render for Custom properties" <|
            \_ ->
                Sub.init
                    [ Custom.init "el" (Custom.BorderRadius Unit.Vw) 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Custom.for "el" (Custom.BorderRadius Unit.Vw)
                                    >> Custom.to 20
                                    >> Custom.duration 1000
                                    >> Custom.easing Linear
                                    >> Custom.build
                                )
                       )
                    |> step 500
                    |> rendered
                    |> Query.has [ Selector.style "border-radius" "10vw" ]
        , test "free-form unit strings render for Custom escape hatch" <|
            \_ ->
                Sub.init
                    [ Custom.init "el" (Custom.Custom "letter-spacing" "ch") 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Custom.for "el" (Custom.Custom "letter-spacing" "ch")
                                    >> Custom.to 2
                                    >> Custom.duration 1000
                                    >> Custom.easing Linear
                                    >> Custom.build
                                )
                       )
                    |> step 500
                    |> rendered
                    |> Query.has [ Selector.style "letter-spacing" "1ch" ]
        ]
