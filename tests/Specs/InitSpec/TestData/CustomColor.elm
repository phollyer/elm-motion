module Specs.InitSpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.CustomColor as CustomColor


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom color tests"
    , testCases =
        List.map
            (\( colorProperty, propertyName, colorValue ) ->
                PropertyTest
                    { description = "CustomColor.init writes the " ++ propertyName
                    , initFuncs =
                        case Color.fromString colorValue of
                            Just color ->
                                [ CustomColor.init animGroup colorProperty color ]

                            Nothing ->
                                []
                    , expected = [ NameValuePair propertyName colorValue ]
                    , notExpected = []
                    }
            )
            CustomColor.all
    }
