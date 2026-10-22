module Specs.InitSpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)
import Specs.Shared.CustomProperty as Custom


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom property tests"
    , testCases =
        List.map
            (\( ( property, value ), ( propertyName, expected ) ) ->
                PropertyTest
                    { description = "Custom.init writes the " ++ propertyName
                    , initFuncs = [ Property.init animGroup property value ]
                    , expected = [ NameValuePair propertyName expected ]
                    , notExpected = []
                    }
            )
            Custom.all
    }
