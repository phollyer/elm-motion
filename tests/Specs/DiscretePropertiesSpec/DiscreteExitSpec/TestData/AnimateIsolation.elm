module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.AnimateIsolation exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (ExitIsolationConfig, TestData)
import Specs.Shared.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "cross-group animate preserves discreteExit state"
    , testCases =
        TD.buildAnimateIsolationTests NoTiming exitCases
            ++ TD.buildAnimateIsolationTests (DurationMs 500) exitCases
            ++ TD.buildAnimateIsolationTests (DelayMs 500) exitCases
    }


exitCases : List ExitIsolationConfig
exitCases =
    [ { description = "animating a bystander group preserves the subject group's discreteExit output"
      , subjectGroup = animGroup
      , bystanderGroup = otherAnimGroup
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    ]

