module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Init exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (InitCase, TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "initialized output ignores discreteExit until animate configures it"
    , testCases =
        TD.buildInitTests NoTiming exitCases
            ++ TD.buildInitTests (DurationMs 500) exitCases
            ++ TD.buildInitTests (DelayMs 500) exitCases
    }


exitCases : List InitCase
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
