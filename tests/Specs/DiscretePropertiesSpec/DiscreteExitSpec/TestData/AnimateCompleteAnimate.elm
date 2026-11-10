module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.AnimateCompleteAnimate exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (ExitConfig, TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "repeated animate after the first exit transition has completed"
    , testCases =
        TD.buildAnimateCompleteAnimateTests NoTiming exitCases
            ++ TD.buildAnimateCompleteAnimateTests (DurationMs 500) exitCases
            ++ TD.buildAnimateCompleteAnimateTests (DelayMs 500) exitCases
    }


exitCases : List ExitConfig
exitCases =
    [ { description = "re-applying `display:block->none` with unchanged animated values settles on the exit value"
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    ]
