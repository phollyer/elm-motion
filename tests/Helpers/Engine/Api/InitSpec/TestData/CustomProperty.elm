module Helpers.Engine.Api.InitSpec.TestData.CustomProperty exposing (..)

import Anim.Property.Custom as Property exposing (Property)
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias CustomPropertyInitFactory builder =
    { init : String -> Property -> Float -> builder }


customPropertyTestData : CustomPropertyInitFactory (a -> a) -> TestData (a -> a)
customPropertyTestData factory =
    { description = "Custom property tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Custom.init writes the border-radius"
              , initFuncs = factory.init animGroup (Property.BorderRadius Em) 20
              , expected = NameValuePair "border-radius" "20em"
              }
            , { description = "Custom.init writes the border-width"
              , initFuncs = factory.init animGroup (Property.BorderWidth Px) 1
              , expected = NameValuePair "border-width" "1px"
              }
            , { description = "Custom.init writes the custom property"
              , initFuncs = factory.init animGroup (Property.Custom "my-custom-property" "unit") 10
              , expected = NameValuePair "my-custom-property" "10unit"
              }
            , { description = "Custom.init writes a unitless property without suffix"
              , initFuncs = factory.init animGroup (Property.LineHeight Unitless) 1.2
              , expected = NameValuePair "line-height" "1.2"
              }
            ]
    }
