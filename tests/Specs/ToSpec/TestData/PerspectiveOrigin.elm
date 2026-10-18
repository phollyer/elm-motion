module Specs.ToSpec.TestData.PerspectiveOrigin exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "the PerspectiveOrigin property writes expected XY values with untouched axes defaulting to 50% across timing profiles"
    , testCases =
        TD.buildPropertyCases "perspective-origin" NoTiming propertyCases
            ++ TD.buildPropertyCases "perspective-origin" (DelayMs 500) propertyCases
            ++ TD.buildPropertyCases "perspective-origin" (DurationMs 500) propertyCases
    }


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "toX writes X, and defaults Y to 50%"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toX 10
                >> PerspectiveOrigin.end
      , expected = "10% 50%"
      , notExpected = []
      }
    , { description = "toY writes Y, and defaults X to 50%"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toY 20
                >> PerspectiveOrigin.end
      , expected = "50% 20%"
      , notExpected = []
      }
    , { description = "toXY writes XY"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toXY 10 20
                >> PerspectiveOrigin.end
      , expected = "10% 20%"
      , notExpected = []
      }
    , { description = "toX last write wins for multiple toX calls"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toX 10
                >> PerspectiveOrigin.toX 15
                >> PerspectiveOrigin.end
      , expected = "15% 50%"
      , notExpected = []
      }
    ]
