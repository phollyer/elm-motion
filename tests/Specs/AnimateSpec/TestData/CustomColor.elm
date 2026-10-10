module Specs.AnimateSpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor
import Specs.AnimateSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom color tests"
    , testCases =
        List.map
            (\( colorProp, cssProp, colorValue ) ->
                PropertyTest
                    { description = "CustomColor.to writes the " ++ cssProp
                    , propertyName = cssProp
                    , propertyPipeline =
                        case Color.fromString colorValue of
                            Just color ->
                                CustomColor.begin colorProp
                                    >> CustomColor.to color
                                    >> CustomColor.end

                            Nothing ->
                                identity
                    , expected = [ NameValuePair cssProp colorValue ]
                    , notExpected = []
                    }
            )
            colorProperties
    }


colorProperties : List ( CustomColor.ColorProperty, String, String )
colorProperties =
    [ ( CustomColor.BackgroundColor, "background-color", "rgb(255, 0, 0)" )
    , ( CustomColor.BorderColor, "border-color", "rgb(0, 255, 0)" )
    , ( CustomColor.Custom "my-custom-color-property", "my-custom-color-property", "rgb(0, 0, 0)" )
    ]
