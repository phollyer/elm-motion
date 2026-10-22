module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)
import Specs.Shared.CustomProperty as Custom


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Custom property output with discreteExit"
    , testCases =
        List.map
            (\( ( property, value ), ( propertyName, expected ) ) ->
                PropertyTest
                    { description = "Custom.to writes " ++ propertyName ++ " while discreteExit is configured"
                    , animGroup = animGroup
                    , initFuncs = [ \_ -> Property.init animGroup property value ]
                    , propertyPipeline =
                        \fns ->
                            fns.discreteExit "display" "block" "none"
                                >> Property.begin property
                                >> Property.to value
                                >> Property.duration 500
                                >> Property.end
                    , expected = [ NameValuePair propertyName expected ]
                    , notExpected = []
                    }
            )
            Custom.all
    }
