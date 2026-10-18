module Specs.ToSpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "the Translate property writes transform components and omits untouched axes across timing profiles"
    , testCases =
        TD.buildPropertyCases "transform" NoTiming propertyCases
            ++ TD.buildPropertyCases "transform" (DelayMs 500) propertyCases
            ++ TD.buildPropertyCases "transform" (DurationMs 500) propertyCases
    }


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "toX writes X, and omits untouched YZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.end
      , expected = "translateX(10px)"
      , notExpected = [ "translateY", "translateZ" ]
      }
    , { description = "toY writes Y, and omits untouched XZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toY 20
                >> Translate.end
      , expected = "translateY(20px)"
      , notExpected = [ "translateX", "translateZ" ]
      }
    , { description = "toZ writes Z, and omits untouched XY"
      , propertyPipeline =
            Translate.begin
                >> Translate.toZ 30
                >> Translate.end
      , expected = "translateZ(30px)"
      , notExpected = [ "translateX", "translateY" ]
      }
    , { description = "toXY writes XY and omits untouched Z"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXY 10 20
                >> Translate.end
      , expected = "translateX(10px) translateY(20px)"
      , notExpected = [ "translateZ" ]
      }
    , { description = "toXZ writes XZ and omits untouched Y"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXZ 10 30
                >> Translate.end
      , expected = "translateX(10px) translateZ(30px)"
      , notExpected = [ "translateY" ]
      }
    , { description = "toYZ writes YZ and omits untouched X"
      , propertyPipeline =
            Translate.begin
                >> Translate.toYZ 20 30
                >> Translate.end
      , expected = "translateY(20px) translateZ(30px)"
      , notExpected = [ "translateX" ]
      }
    , { description = "toXYZ writes XYZ promoted to translate3d"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXYZ 10 20 30
                >> Translate.end
      , expected = "translate3d(10px, 20px, 30px)"
      , notExpected = [ "translateX", "translateY", "translateZ" ]
      }
    , { description = "toX last write wins for duplicate toX calls"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.toX 11
                >> Translate.end
      , expected = "translateX(11px)"
      , notExpected = [ "translateY", "translateZ" ]
      }
    , { description = "toX writes 0 and omits untouched YZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 0
                >> Translate.end
      , expected = "translateX(0px)"
      , notExpected = [ "translateY", "translateZ" ]
      }
    , { description = "toY writes 0 and omits untouched XZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toY 0
                >> Translate.end
      , expected = "translateY(0px)"
      , notExpected = [ "translateX", "translateZ" ]
      }
    , { description = "toZ writes 0 and omits untouched XY"
      , propertyPipeline =
            Translate.begin
                >> Translate.toZ 0
                >> Translate.end
      , expected = "translateZ(0px)"
      , notExpected = [ "translateX", "translateY" ]
      }
    ]
