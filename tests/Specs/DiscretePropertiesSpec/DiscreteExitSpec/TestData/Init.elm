module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Init exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (ExitConfig, TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "initialized output ignores discreteExit until animate configures it"
    , testCases =
        TD.buildTests NoTiming exitCases
            ++ TD.buildTests (DurationMs 500) exitCases
            ++ TD.buildTests (DelayMs 500) exitCases
    }


exitCases : List ExitConfig
exitCases =
    [ { description = "discreteExit of `display:block->none` set in init does not leak into style output"
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    , { description = "discreteExit of `display:flex->none` set in init does not leak into style output"
      , discreteProperty = "display"
      , fromValue = "flex"
      , toValue = "none"
      }
    , { description = "discreteExit of `visibility:visible->hidden` set in init does not leak into style output"
      , discreteProperty = "visibility"
      , fromValue = "visible"
      , toValue = "hidden"
      }
    ]
