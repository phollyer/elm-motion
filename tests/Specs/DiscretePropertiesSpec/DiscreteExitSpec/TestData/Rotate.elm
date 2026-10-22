module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Rotate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Rotate output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "Rotate.toX still writes transform while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> Rotate.initX animGroup 0 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Rotate.begin
                        >> Rotate.toX 15
                        >> Rotate.duration 500
                        >> Rotate.end
            , expected = [ NameValuePair "transform" "rotateX(15deg)" ]
            , notExpected = [ "rotateY", "rotateZ" ]
            }
        ]
    }
