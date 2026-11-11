module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.NoOpAfterComplete exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (ExitIsolationConfig, TestData)
import Specs.Shared.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "no-op discreteExit animate after completion remains settled"
    , testCases =
        TD.buildNoOpAfterCompleteTests NoTiming exitCases
            ++ TD.buildNoOpAfterCompleteTests (DurationMs 500) exitCases
            ++ TD.buildNoOpAfterCompleteTests (DelayMs 500) exitCases
    }


exitCases : List ExitIsolationConfig
exitCases =
    [ { description = "re-applying identical discreteExit output after completion stays settled"
      , subjectGroup = animGroup
      , bystanderGroup = otherAnimGroup
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    ]

