module Specs.AnimateSpec.TestData.Scale exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Specs.AnimateSpec.TestData exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Scale tests"
    , testCases =
        List.map
            (\c ->
                PropertyTest
                    { description = c.description
                    , propertyName = "transform"
                    , propertyPipeline = c.propertyPipeline
                    , expected = [ NameValuePair "transform" c.expected ]
                    }
            )
            propertyCases
    }


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "Scale.toX writes X, and omits untouched YZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toX 10
                >> Scale.end
      , expected = "scaleX(10)"
      }
    , { description = "Scale.initY writes Y, and omits untouched XZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toY 20
                >> Scale.end
      , expected = "scaleY(20)"
      }
    , { description = "Scale.initZ writes Z, and omits untouched XY"
      , propertyPipeline =
            Scale.begin
                >> Scale.toZ 30
                >> Scale.end
      , expected = "scaleZ(30)"
      }
    , { description = "Scale.initXY writes XY and omits untouched Z"
      , propertyPipeline =
            Scale.begin
                >> Scale.toXY 10 20
                >> Scale.end
      , expected = "scaleX(10) scaleY(20)"
      }
    , { description = "Scale.initXZ writes XZ and omits untouched Y"
      , propertyPipeline =
            Scale.begin
                >> Scale.toXZ 10 30
                >> Scale.end
      , expected = "scaleX(10) scaleZ(30)"
      }
    , { description = "Scale.initYZ writes YZ and omits untouched X"
      , propertyPipeline =
            Scale.begin
                >> Scale.toYZ 20 30
                >> Scale.end
      , expected = "scaleY(20) scaleZ(30)"
      }
    , { description = "Scale.initXYZ writes XYZ"
      , propertyPipeline =
            Scale.begin
                >> Scale.toXYZ 10 20 30
                >> Scale.end
      , expected = "scaleX(10) scaleY(20) scaleZ(30)"
      }
    ]
