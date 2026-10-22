module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Opacity output with discreteExit"
    , testCases =
        [ PropertyTest
            { description = "Opacity.to still writes opacity while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs = [ \_ -> Opacity.init animGroup 1 ]
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Opacity.begin
                        >> Opacity.to 0.5
                        >> Opacity.duration 500
                        >> Opacity.end
            , expected = [ NameValuePair "opacity" "0.5" ]
            , notExpected = []
            }
        , PropertyTest
            { description = "no-duration discreteExit applies display:none immediately"
            , animGroup = animGroup
            , initFuncs = []
            , propertyPipeline =
                \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Opacity.begin
                        >> Opacity.to 0
                        >> Opacity.end
            , expected = [ NameValuePair "display" "none" ]
            , notExpected = []
            }
        ]
    }
