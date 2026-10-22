module Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData.Init exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData as TD exposing (InitCase, TestCase(..), TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "initialized output with discreteEntry"
    , testCases =
        TD.buildInitTests NoTiming entryCases
            ++ TD.buildInitTests (DurationMs 500) entryCases
            ++ TD.buildInitTests (DelayMs 500) entryCases
    }


entryCases : List InitCase
entryCases =
    [ { description = "discreteEntry of `display:block` is configured in init"
      , discreteProperty = "display"
      , discreteValue = "block"
      }
    , { description = "discreteEntry of `display:flex` is configured in init"
      , discreteProperty = "display"
      , discreteValue = "flex"
      }
    , { description = "discreteEntry of `visibility:hidden` is configured in init"
      , discreteProperty = "visibility"
      , discreteValue = "hidden"
      }
    ]
