module Specs.AnimateSpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Translate.init* tests"
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
    [ { description = "Translate.toX writes X, and omits untouched YZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.end
      , expected = "translateX(10px)"
      }
    , { description = "Translate.toY writes Y, and omits untouched XZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toY 20
                >> Translate.end
      , expected = "translateY(20px)"
      }
    , { description = "Translate.toZ writes Z, and omits untouched XY"
      , propertyPipeline =
            Translate.begin
                >> Translate.toZ 30
                >> Translate.end
      , expected = "translateZ(30px)"
      }
    , { description = "Translate.toXY writes XY and omits untouched Z"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXY 10 20
                >> Translate.end
      , expected = "translateX(10px) translateY(20px)"
      }
    , { description = "Translate.toXZ writes XZ and omits untouched Y"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXZ 10 30
                >> Translate.end
      , expected = "translateX(10px) translateZ(30px)"
      }
    , { description = "Translate.toYZ writes YZ and omits untouched X"
      , propertyPipeline =
            Translate.begin
                >> Translate.toYZ 20 30
                >> Translate.end
      , expected = "translateY(20px) translateZ(30px)"
      }
    , { description = "Translate.toXYZ writes XYZ promoted to translate3d"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXYZ 10 20 30
                >> Translate.end
      , expected = "translate3d(10px, 20px, 30px)"
      }
    , { description = "Translate.toX with custom CSS unit writes X, and omits untouched YZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.cssUnitX Em
                >> Translate.end
      , expected = "translateX(10em)"
      }
    , { description = "Translate.toY with custom CSS unit writes Y, and omits untouched XZ"
      , propertyPipeline =
            Translate.begin
                >> Translate.toY 20
                >> Translate.cssUnitY Em
                >> Translate.end
      , expected = "translateY(20em)"
      }
    , { description = "Translate.toZ with custom CSS unit writes Z, and omits untouched XY"
      , propertyPipeline =
            Translate.begin
                >> Translate.toZ 30
                >> Translate.cssUnitZ Em
                >> Translate.end
      , expected = "translateZ(30em)"
      }
    , { description = "Translate.toXY with custom CSS unit writes XY and omits untouched Z"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXY 10 20
                >> Translate.cssUnitX Em
                >> Translate.cssUnitY Em
                >> Translate.end
      , expected = "translateX(10em) translateY(20em)"
      }
    , { description = "Translate.toXZ with custom CSS unit writes XZ and omits untouched Y"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXZ 10 30
                >> Translate.cssUnitX Em
                >> Translate.cssUnitZ Em
                >> Translate.end
      , expected = "translateX(10em) translateZ(30em)"
      }
    , { description = "Translate.toYZ with custom CSS unit writes YZ and omits untouched X"
      , propertyPipeline =
            Translate.begin
                >> Translate.toYZ 20 30
                >> Translate.cssUnitY Em
                >> Translate.cssUnitZ Em
                >> Translate.end
      , expected = "translateY(20em) translateZ(30em)"
      }
    , { description = "Translate.toXYZ with custom CSS unit writes XYZ promoted to translate3d"
      , propertyPipeline =
            Translate.begin
                >> Translate.toXYZ 10 20 30
                >> Translate.cssUnit Em
                >> Translate.end
      , expected = "translate3d(10em, 20em, 30em)"
      }
    , { description = "Translate.toX prefers axis-specific unit when applied after general unit"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.cssUnit Em
                >> Translate.cssUnitX Px
                >> Translate.end
      , expected = "translateX(10px)"
      }
    , { description = "Translate.toX uses general unit when applied after axis-specific unit"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.cssUnitX Px
                >> Translate.cssUnit Em
                >> Translate.end
      , expected = "translateX(10em)"
      }
    , { description = "Translate.toX last write wins for duplicate toX calls"
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.toX 11
                >> Translate.end
      , expected = "translateX(11px)"
      }
    ]
