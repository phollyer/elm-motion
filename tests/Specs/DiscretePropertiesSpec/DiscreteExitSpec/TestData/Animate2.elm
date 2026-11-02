module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Animate2 exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (ExitConfig, TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "repeated animate output with unchanged discreteExit values"
    , testCases =
        TD.buildAnimate2Tests (DurationMs 500) exitCases
            ++ TD.buildAnimate2Tests (DelayMs 500) exitCases
    }


exitCases : List ExitConfig
exitCases =
    [ { description = "re-applying `display:block->none` with unchanged animated values keeps the exit value"
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    ]
