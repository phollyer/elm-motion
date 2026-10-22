module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Scale exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Scale output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "Scale.toX still writes transform while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> Scale.initX animGroup 1 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Scale.begin
                        >> Scale.toX 2
                        >> Scale.duration 500
                        >> Scale.end
            , expected = [ NameValuePair "transform" "scaleX(2)" ]
            , notExpected = [ "scaleY", "scaleZ" ]
            }
        ]
    }
