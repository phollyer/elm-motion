module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Translate output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "Translate.toX still writes transform while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> Translate.initX animGroup 0 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Translate.begin
                        >> Translate.toX 10
                        >> Translate.duration 500
                        >> Translate.end
            , expected = [ NameValuePair "transform" "translateX(10px)" ]
            , notExpected = [ "translateY", "translateZ" ]
            }
        ]
    }
