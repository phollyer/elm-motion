module Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData.Animate exposing (testData)

import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData as TD exposing (EntryConfig, TestCase(..), TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData
testData =
    { description = "animated output with discreteEntry"
    , testCases =
        TD.buildTests NoTiming entryCases
            ++ TD.buildTests (DurationMs 500) entryCases
            ++ TD.buildTests (DelayMs 500) entryCases
    }


entryCases : List EntryConfig
entryCases =
    [ { description = "discreteEntry of `display:block` is configured in animate"
      , discreteProperty = "display"
      , discreteValue = "block"
      }
    , { description = "discreteEntry of `display:flex` is configured in animate"
      , discreteProperty = "display"
      , discreteValue = "flex"
      }
    , { description = "discreteEntry of `visibility:hidden` is configured in animate"
      , discreteProperty = "visibility"
      , discreteValue = "hidden"
      }
    ]
