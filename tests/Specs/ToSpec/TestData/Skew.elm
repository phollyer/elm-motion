module Specs.ToSpec.TestData.Skew exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "the Skew property writes transform components and omits untouched axes across timing profiles"
    , testCases =
        TD.buildPropertyCases "transform" NoTiming propertyCases
            ++ TD.buildPropertyCases "transform" (DelayMs 500) propertyCases
            ++ TD.buildPropertyCases "transform" (DurationMs 500) propertyCases
    }


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "toX writes X, and omits untouched Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toX 10
                >> Skew.end
      , expected = "skewX(10deg)"
      , notExpected = [ "skewY" ]
      }
    , { description = "toY writes Y, and omits untouched X"
      , propertyPipeline =
            Skew.begin
                >> Skew.toY 20
                >> Skew.end
      , expected = "skewY(20deg)"
      , notExpected = [ "skewX" ]
      }
    , { description = "toXY writes X and Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toXY 10 20
                >> Skew.end
      , expected = "skewX(10deg) skewY(20deg)"
      , notExpected = []
      }
    , { description = "toX with 0 writes only X, and omits untouched Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toX 0
                >> Skew.end
      , expected = "skewX(0deg)"
      , notExpected = [ "skewY" ]
      }
    , { description = "toY with 0 writes only Y, and omits untouched X"
      , propertyPipeline =
            Skew.begin
                >> Skew.toY 0
                >> Skew.end
      , expected = "skewY(0deg)"
      , notExpected = [ "skewX" ]
      }
    , { description = "toXY with 0 writes both X and Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toXY 0 0
                >> Skew.end
      , expected = "skewX(0deg) skewY(0deg)"
      , notExpected = []
      }
    ]
