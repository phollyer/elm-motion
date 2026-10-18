module Specs.ToSpec.TestData.Scale exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "the Scale property writes transform components and omits untouched axes across timing profiles"
    , testCases =
        TD.buildPropertyCases "transform" NoTiming propertyCases
            ++ TD.buildPropertyCases "transform" (DelayMs 500) propertyCases
            ++ TD.buildPropertyCases "transform" (DurationMs 500) propertyCases
    }


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "toX writes X, and omits untouched YZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toX 10
                >> Scale.end
      , expected = "scaleX(10)"
      , notExpected = [ "scaleY", "scaleZ" ]
      }
    , { description = "toY writes Y, and omits untouched XZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toY 20
                >> Scale.end
      , expected = "scaleY(20)"
      , notExpected = [ "scaleX", "scaleZ" ]
      }
    , { description = "toZ writes Z, and omits untouched XY"
      , propertyPipeline =
            Scale.begin
                >> Scale.toZ 30
                >> Scale.end
      , expected = "scaleZ(30)"
      , notExpected = [ "scaleX", "scaleY" ]
      }
    , { description = "toXY writes XY and omits untouched Z"
      , propertyPipeline =
            Scale.begin
                >> Scale.toXY 10 20
                >> Scale.end
      , expected = "scaleX(10) scaleY(20)"
      , notExpected = [ "scaleZ" ]
      }
    , { description = "toXZ writes XZ and omits untouched Y"
      , propertyPipeline =
            Scale.begin
                >> Scale.toXZ 10 30
                >> Scale.end
      , expected = "scaleX(10) scaleZ(30)"
      , notExpected = [ "scaleY" ]
      }
    , { description = "toYZ writes YZ and omits untouched X"
      , propertyPipeline =
            Scale.begin
                >> Scale.toYZ 20 30
                >> Scale.end
      , expected = "scaleY(20) scaleZ(30)"
      , notExpected = [ "scaleX" ]
      }
    , { description = "toXYZ writes XYZ promoted to scale3d"
      , propertyPipeline =
            Scale.begin
                >> Scale.toXYZ 10 20 30
                >> Scale.end
      , expected = "scale3d(10, 20, 30)"
      , notExpected = []
      }
    , { description = "toX writes 1 and omits untouched YZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toX 1
                >> Scale.end
      , expected = "scaleX(1)"
      , notExpected = [ "scaleY", "scaleZ" ]
      }
    , { description = "toY writes 1 and omits untouched XZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toY 1
                >> Scale.end
      , expected = "scaleY(1)"
      , notExpected = [ "scaleX", "scaleZ" ]
      }
    , { description = "toZ writes 1 and omits untouched XY"
      , propertyPipeline =
            Scale.begin
                >> Scale.toZ 1
                >> Scale.end
      , expected = "scaleZ(1)"
      , notExpected = [ "scaleX", "scaleY" ]
      }
    ]
