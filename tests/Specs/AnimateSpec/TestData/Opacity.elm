module Specs.AnimateSpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Specs.AnimateSpec.TestData as TD exposing (TestCase(..), TestData, TimingProfile(..))
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Opacity tests"
    , testCases =
        TD.buildPropertyCases "opacity" NoTiming propertyCases
            ++ TD.buildPropertyCases "opacity" (DelayMs 500) propertyCases
    }


propertyCases : List (TD.PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "Opacity.to writes the opacity value"
      , propertyPipeline =
            Opacity.begin
                >> Opacity.to 0.5
                >> Opacity.end
      , expected = "0.5"
      , notExpected = []
      }
    ]
