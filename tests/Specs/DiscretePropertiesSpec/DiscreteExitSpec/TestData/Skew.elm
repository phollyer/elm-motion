module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Skew exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Skew output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "Skew.toX still writes transform while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> Skew.initX animGroup 0 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Skew.begin
                        >> Skew.toX 5
                        >> Skew.duration 500
                        >> Skew.end
            , expected = [ NameValuePair "transform" "skewX(5deg)" ]
            , notExpected = [ "skewY" ]
            }
        ]
    }
