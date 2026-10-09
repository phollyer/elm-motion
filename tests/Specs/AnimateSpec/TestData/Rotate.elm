module Specs.AnimateSpec.TestData.Rotate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate
import Specs.AnimateSpec.TestData exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Rotate tests"
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
    [ { description = "Rotate.toX writes X, and omits untouched YZ"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toX 10
                >> Rotate.end
      , expected = "rotateX(10deg)"
      }
    , { description = "Rotate.toY writes Y, and omits untouched XZ"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toY 20
                >> Rotate.end
      , expected = "rotateY(20deg)"
      }
    , { description = "Rotate.toZ writes Z, and omits untouched XY"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toZ 30
                >> Rotate.end
      , expected = "rotateZ(30deg)"
      }
    , { description = "Rotate.toXY writes XY and omits untouched Z"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toXY 10 20
                >> Rotate.end
      , expected = "rotateX(10deg) rotateY(20deg)"
      }
    , { description = "Rotate.toXZ writes XZ and omits untouched Y"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toXZ 10 30
                >> Rotate.end
      , expected = "rotateX(10deg) rotateZ(30deg)"
      }
    , { description = "Rotate.toYZ writes YZ and omits untouched X"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toYZ 20 30
                >> Rotate.end
      , expected = "rotateY(20deg) rotateZ(30deg)"
      }
    , { description = "Rotate.toXYZ writes XYZ"
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toXYZ 10 20 30
                >> Rotate.end
      , expected = "rotateX(10deg) rotateY(20deg) rotateZ(30deg)"
      }
    ]
