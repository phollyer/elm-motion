module Specs.InitSpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom property tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Custom.init writes the border-radius"
              , initFuncs = [ Property.init animGroup (Property.BorderRadius Em) 20 ]
              , expected = [ NameValuePair "border-radius" "20em" ]
              , notExpected = []
              }
            , { description = "Custom.init writes the border-width"
              , initFuncs = [ Property.init animGroup (Property.BorderWidth Px) 1 ]
              , expected = [ NameValuePair "border-width" "1px" ]
              , notExpected = []
              }
            , { description = "Custom.init writes a unitless property without suffix"
              , initFuncs = [ Property.init animGroup (Property.LineHeight Unitless) 1.2 ]
              , expected = [ NameValuePair "line-height" "1.2" ]
              , notExpected = []
              }
            , { description = "Custom.init writes the custom property"
              , initFuncs = [ Property.init animGroup (Property.Custom "my-custom-property" "unit") 10 ]
              , expected = [ NameValuePair "my-custom-property" "10unit" ]
              , notExpected = []
              }
            ]
    }
