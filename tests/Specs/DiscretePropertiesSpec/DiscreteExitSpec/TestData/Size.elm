module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Size output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "Size.toW still writes width while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> Size.initW animGroup 1 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Size.begin
                        >> Size.toW 200
                        >> Size.duration 500
                        >> Size.end
            , expected = [ NameValuePair "width" "200px" ]
            , notExpected = [ "height" ]
            }
        ]
    }
