module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.AnimateComplete exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (AnimateCompleteCase, TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "completed animated output with discreteExit"
    , testCases =
        TD.buildAnimateCompleteTests (DurationMs 500) exitCases
            ++ TD.buildAnimateCompleteTests (DelayMs 500) exitCases
    }


exitCases : List AnimateCompleteCase
exitCases =
    [ { description = "discreteExit of `display:block->none` flips to exit value on completion"
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    , { description = "discreteExit of `display:flex->none` flips to exit value on completion"
      , discreteProperty = "display"
      , fromValue = "flex"
      , toValue = "none"
      }
    , { description = "discreteExit of `visibility:visible->hidden` flips to exit value on completion"
      , discreteProperty = "visibility"
      , fromValue = "visible"
      , toValue = "hidden"
      }
    ]
