module Specs.InitSpec.TestData.PerspectiveOrigin exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "PerspectiveOrigin.init tests"
    , testCases =
        List.map PropertyTest
            [ { description = "PerspectiveOrigin.initX writes X, and defaults Y to 50%"
              , initFuncs = [ PerspectiveOrigin.initX animGroup 10 ]
              , expected = [ NameValuePair "perspective-origin" "10% 50%" ]
              }
            , { description = "PerspectiveOrigin.initY writes Y, and defaults X to 50%"
              , initFuncs = [ PerspectiveOrigin.initY animGroup 20 ]
              , expected = [ NameValuePair "perspective-origin" "50% 20%" ]
              }
            , { description = "PerspectiveOrigin.initXY writes XY"
              , initFuncs = [ PerspectiveOrigin.initXY animGroup 10 20 ]
              , expected = [ NameValuePair "perspective-origin" "10% 20%" ]
              }
            , { description = "PerspectiveOrigin.initX with custom css unit writes X, and defaults Y to 50%"
              , initFuncs =
                    [ PerspectiveOrigin.initX animGroup 10
                        >> PerspectiveOrigin.initCssUnitX Px
                    ]
              , expected = [ NameValuePair "perspective-origin" "10px 50%" ]
              }
            , { description = "PerspectiveOrigin.initY with custom css unit writes Y, and defaults X to 50%"
              , initFuncs =
                    [ PerspectiveOrigin.initY animGroup 20
                        >> PerspectiveOrigin.initCssUnitY Px
                    ]
              , expected = [ NameValuePair "perspective-origin" "50% 20px" ]
              }
            , { description = "PerspectiveOrigin.initXY with custom css unit writes XY"
              , initFuncs =
                    [ PerspectiveOrigin.initXY animGroup 10 20
                        >> PerspectiveOrigin.initCssUnit Px
                    ]
              , expected = [ NameValuePair "perspective-origin" "10px 20px" ]
              }
            , { description = "PerspectiveOrigin.initX prefers axis-specific unit when applied after global unit, and untouched Y inherits global unit"
              , initFuncs =
                    [ PerspectiveOrigin.initX animGroup 10
                        >> PerspectiveOrigin.initCssUnit Em
                        >> PerspectiveOrigin.initCssUnitX Px
                    ]
              , expected = [ NameValuePair "perspective-origin" "10px 50em" ]
              }
            , { description = "PerspectiveOrigin.initX uses global unit when applied after axis-specific unit, including untouched Y"
              , initFuncs =
                    [ PerspectiveOrigin.initX animGroup 10
                        >> PerspectiveOrigin.initCssUnitX Px
                        >> PerspectiveOrigin.initCssUnit Em
                    ]
              , expected = [ NameValuePair "perspective-origin" "10em 50em" ]
              }
            , { description = "PerspectiveOrigin.initX last write wins for duplicate initX calls"
              , initFuncs =
                    [ PerspectiveOrigin.initX animGroup 10
                        >> PerspectiveOrigin.initX animGroup 15
                    ]
              , expected = [ NameValuePair "perspective-origin" "15% 50%" ]
              }
            ]
    }
