module Specs.InitSpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom color tests"
    , testCases =
        List.map PropertyTest
            [ { description = "CustomColor.init writes the background color"
              , initFuncs = [ CustomColor.init animGroup CustomColor.BackgroundColor (Color.rgb 255 0 0) ]
              , expected = [ NameValuePair "background-color" "rgb(255, 0, 0)" ]
              , notExpected = []
              }
            , { description = "CustomColor.init writes the border-color"
              , initFuncs = [ CustomColor.init animGroup CustomColor.BorderColor (Color.rgb 0 255 0) ]
              , expected = [ NameValuePair "border-color" "rgb(0, 255, 0)" ]
              , notExpected = []
              }
            , { description = "CustomColor.init writes the custom property color"
              , initFuncs = [ CustomColor.init animGroup (CustomColor.Custom "my-custom-property") (Color.rgb 0 0 0) ]
              , expected = [ NameValuePair "my-custom-property" "rgb(0, 0, 0)" ]
              , notExpected = []
              }
            ]
    }
