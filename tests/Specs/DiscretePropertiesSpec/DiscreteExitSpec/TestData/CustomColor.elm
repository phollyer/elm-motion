module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as Property
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)
import Specs.Shared.CustomColor as Custom


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "CustomColor output with discreteExit"
    , testCases =
        List.map
            (\( colorProperty, propertyName, colorValue ) ->
                let
                    color =
                        Color.fromString colorValue
                            |> Maybe.withDefault (Color.rgba 0 0 0 0)
                in
                PropertyTest
                    { description = "CustomColor.to writes " ++ propertyName ++ " while discreteExit is configured"
                    , animGroup = animGroup
                    , initFuncs = [ \_ -> Property.init animGroup colorProperty color ]
                    , propertyPipeline =
                        \fns ->
                            fns.discreteExit "display" "block" "none"
                                >> Property.begin colorProperty
                                >> Property.to color
                                >> Property.duration 500
                                >> Property.end
                    , expected = [ NameValuePair propertyName colorValue ]
                    , notExpected = []
                    }
            )
            Custom.all
    }
