module Helpers.Engine.Api.InitSpec.TestData.PerspectiveOrigin exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias PerspectiveOriginInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initCssUnitX : Unit -> builder
    , initCssUnitY : Unit -> builder
    , initCssUnit : Unit -> builder
    }


perspectiveOriginTestData : PerspectiveOriginInitFactory (a -> a) -> TestData (a -> a)
perspectiveOriginTestData factory =
    { description = "PerspectiveOrigin.init tests"
    , testCases =
        List.map GeneralTest
            [ { description = "PerspectiveOrigin.initX writes X, and defaults Y to 50%"
              , initFuncs = factory.initX animGroup 10
              , expected = NameValuePair "perspective-origin" "10% 50%"
              }
            , { description = "PerspectiveOrigin.initY writes Y, and defaults X to 50%"
              , initFuncs = factory.initY animGroup 20
              , expected = NameValuePair "perspective-origin" "50% 20%"
              }
            , { description = "PerspectiveOrigin.initXY writes XY"
              , initFuncs = factory.initXY animGroup 10 20
              , expected = NameValuePair "perspective-origin" "10% 20%"
              }
            , { description = "PerspectiveOrigin.initX with custom css unit writes X, and defaults Y to 50%"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initCssUnitX Px
              , expected = NameValuePair "perspective-origin" "10px 50%"
              }
            , { description = "PerspectiveOrigin.initY with custom css unit writes Y, and defaults X to 50%"
              , initFuncs =
                    factory.initY animGroup 20
                        >> factory.initCssUnitY Px
              , expected = NameValuePair "perspective-origin" "50% 20px"
              }
            , { description = "PerspectiveOrigin.initXY with custom css unit writes XY"
              , initFuncs =
                    factory.initXY animGroup 10 20
                        >> factory.initCssUnit Px
              , expected = NameValuePair "perspective-origin" "10px 20px"
              }
            , { description = "PerspectiveOrigin.initX prefers axis-specific unit when applied after global unit, and untouched Y inherits global unit"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initCssUnit Em
                        >> factory.initCssUnitX Px
              , expected = NameValuePair "perspective-origin" "10px 50em"
              }
            , { description = "PerspectiveOrigin.initX uses global unit when applied after axis-specific unit, including untouched Y"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initCssUnitX Px
                        >> factory.initCssUnit Em
              , expected = NameValuePair "perspective-origin" "10em 50em"
              }
            , { description = "PerspectiveOrigin.initX last write wins for duplicate initX calls"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initX animGroup 15
              , expected = NameValuePair "perspective-origin" "15% 50%"
              }
            ]
    }
