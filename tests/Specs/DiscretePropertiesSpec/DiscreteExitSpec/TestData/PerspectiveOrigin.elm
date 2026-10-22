module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.PerspectiveOrigin exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "PerspectiveOrigin output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "PerspectiveOrigin.toX still writes perspective-origin while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> PerspectiveOrigin.initX animGroup 50 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> PerspectiveOrigin.begin
                        >> PerspectiveOrigin.toX 10
                        >> PerspectiveOrigin.duration 500
                        >> PerspectiveOrigin.end
            , expected = [ NameValuePair "perspective-origin" "10% 50%" ]
            , notExpected = []
            }
        ]
    }
