module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Animate exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (AnimateCase, TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "animated output with discreteExit"
    , testCases =
        TD.buildAnimateTests NoTiming exitCases
            ++ TD.buildAnimateTests (DurationMs 500) exitCases
            ++ TD.buildAnimateTests (DelayMs 500) exitCases
    }


exitCases : List AnimateCase
exitCases =
    [ { description = "discreteExit of `display:block->none` is configured in animate"
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    , { description = "discreteExit of `display:flex->none` is configured in animate"
      , discreteProperty = "display"
      , fromValue = "flex"
      , toValue = "none"
      }
    , { description = "discreteExit of `visibility:visible->hidden` is configured in animate"
      , discreteProperty = "visibility"
      , fromValue = "visible"
      , toValue = "hidden"
      }
    ]
