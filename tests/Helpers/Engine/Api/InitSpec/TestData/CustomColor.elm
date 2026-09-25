module Helpers.Engine.Api.InitSpec.TestData.CustomColor exposing (..)

import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty)
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias CustomColorInitFactory builder =
    { init : String -> ColorProperty -> Color -> builder }


customColorTestData : CustomColorInitFactory (a -> a) -> TestData (a -> a)
customColorTestData factory =
    { description = "Custom color tests"
    , testCases =
        List.map GeneralTest
            [ { description = "CustomColor.init writes the background color"
              , initFuncs = factory.init animGroup CustomColor.BackgroundColor (Color.rgb 255 0 0)
              , expected = NameValuePair "background-color" "rgb(255, 0, 0)"
              }
            , { description = "CustomColor.init writes the border-color"
              , initFuncs = factory.init animGroup CustomColor.BorderColor (Color.rgb 0 255 0)
              , expected = NameValuePair "border-color" "rgb(0, 255, 0)"
              }
            , { description = "CustomColor.init writes the custom property color"
              , initFuncs = factory.init animGroup (CustomColor.Custom "my-custom-property") (Color.rgb 0 0 0)
              , expected = NameValuePair "my-custom-property" "rgb(0, 0, 0)"
              }
            ]
    }
