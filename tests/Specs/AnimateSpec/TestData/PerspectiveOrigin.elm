module Specs.AnimateSpec.TestData.PerspectiveOrigin exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


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
    , { description = "toX with custom css unit writes X, and defaults Y to 50%"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toX 10
                >> PerspectiveOrigin.cssUnitX Px
                >> PerspectiveOrigin.end
      , expected = "10px 50%"
      , notExpected = []
      }
    , { description = "toY with custom css unit writes Y, and defaults X to 50%"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toY 20
                >> PerspectiveOrigin.cssUnitY Px
                >> PerspectiveOrigin.end
      , expected = "50% 20px"
      , notExpected = []
      }
    , { description = "toXY with custom css unit writes XY"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toXY 10 20
                >> PerspectiveOrigin.cssUnit Px
                >> PerspectiveOrigin.end
      , expected = "10px 20px"
      , notExpected = []
      }
    , { description = "toX prefers axis-specific unit when applied after general unit, and untouched Y inherits general unit"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toX 10
                >> PerspectiveOrigin.cssUnit Em
                >> PerspectiveOrigin.cssUnitX Px
                >> PerspectiveOrigin.end
      , expected = "10px 50em"
      , notExpected = []
      }
    , { description = "toX uses general unit when applied after axis-specific unit, including untouched Y"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toX 10
                >> PerspectiveOrigin.cssUnitX Px
                >> PerspectiveOrigin.cssUnit Em
                >> PerspectiveOrigin.end
      , expected = "10em 50em"
      , notExpected = []
      }
    , { description = "toX last write wins for duplicate toX calls"
      , propertyPipeline =
            PerspectiveOrigin.begin
                >> PerspectiveOrigin.toX 10
                >> PerspectiveOrigin.toX 15
                >> PerspectiveOrigin.end
      , expected = "15% 50%"
      , notExpected = []
      }
    ]
