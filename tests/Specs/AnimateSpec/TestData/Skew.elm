module Specs.AnimateSpec.TestData.Skew exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew
import Specs.AnimateSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData, TimingProfile(..))


testData : TestData (AnimBuilder eng)
testData =
    { description = "Skew tests"
    , testCases =
        TD.buildPropertyCases "transform" TD.NoTiming propertyCases
            ++ TD.buildPropertyCases "transform" (TD.DelayMs 500) propertyCases
            ++ TD.buildPropertyCases "transform" (TD.DurationMs 500) propertyCases
    }


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "Skew.toX writes X, and omits untouched Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toX 10
                >> Skew.end
      , expected = "skewX(10deg)"
      , notExpected = [ "skewY" ]
      }
    , { description = "Skew.toX with 0 writes only X, and omits untouched Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toX 0
                >> Skew.end
      , expected = "skewX(0deg)"
      , notExpected = [ "skewY" ]
      }
    , { description = "Skew.toY writes Y, and omits untouched X"
      , propertyPipeline =
            Skew.begin
                >> Skew.toY 20
                >> Skew.end
      , expected = "skewY(20deg)"
      , notExpected = [ "skewX" ]
      }
    , { description = "Skew.toY with 0 writes only Y, and omits untouched X"
      , propertyPipeline =
            Skew.begin
                >> Skew.toY 0
                >> Skew.end
      , expected = "skewY(0deg)"
      , notExpected = [ "skewX" ]
      }
    , { description = "Skew.toXY writes X and Y"
      , propertyPipeline =
            Skew.begin
                >> Skew.toXY 10 20
                >> Skew.end
      , expected = "skewX(10deg) skewY(20deg)"
      , notExpected = []
      }
    ]
