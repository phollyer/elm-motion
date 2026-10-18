module Specs.ToSpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "the Opacity property writes opacity values across timing profiles"
    , testCases =
        TD.buildPropertyCases "opacity" NoTiming propertyCases
            ++ TD.buildPropertyCases "opacity" (DelayMs 500) propertyCases
            ++ TD.buildPropertyCases "opacity" (DurationMs 500) propertyCases
    }


propertyCases : List (TD.PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "`to` writes the opacity value"
      , propertyPipeline =
            Opacity.begin
                >> Opacity.to 0.5
                >> Opacity.end
      , expected = "0.5"
      , notExpected = []
      }
    , { description = "`to` writes the opacity value of 0"
      , propertyPipeline =
            Opacity.begin
                >> Opacity.to 0
                >> Opacity.end
      , expected = "0"
      , notExpected = []
      }
    ]
