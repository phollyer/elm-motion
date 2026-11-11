module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.RetargetIsolation exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData as TD exposing (ExitIsolationConfig, TestData)
import Specs.Shared.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "cross-group retarget preserves discreteExit state"
    , testCases =
        TD.buildRetargetIsolationTests NoTiming exitCases
            ++ TD.buildRetargetIsolationTests (DurationMs 500) exitCases
            ++ TD.buildRetargetIsolationTests (DelayMs 500) exitCases
    }


exitCases : List ExitIsolationConfig
exitCases =
    [ { description = "retargeting a bystander group preserves the subject group's discreteExit output"
      , subjectGroup = animGroup
      , bystanderGroup = otherAnimGroup
      , discreteProperty = "display"
      , fromValue = "block"
      , toValue = "none"
      }
    ]

