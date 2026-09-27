module Specs.InitSpec.TestData.Translate exposing (..)

import Anim.Unit exposing (Unit(..))
import Factories.Properties.Translate as TranslateFactory
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.Runner exposing (..)


testData : TranslateFactory.Factory a b -> TestData (a -> a)
testData f =
    { description = "Translate.init* tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Translate.initX writes X, and omits untouched YZ"
              , initFuncs = f.initX animGroup 10
              , expected = NameValuePair "transform" "translateX(10px)"
              }
            , { description = "Translate.initY writes Y, and omits untouched XZ"
              , initFuncs = f.initY animGroup 20
              , expected = NameValuePair "transform" "translateY(20px)"
              }
            , { description = "Translate.initZ writes Z, and omits untouched XY"
              , initFuncs = f.initZ animGroup 30
              , expected = NameValuePair "transform" "translateZ(30px)"
              }
            , { description = "Translate.initXY writes XY and omits untouched Z"
              , initFuncs = f.initXY animGroup 10 20
              , expected = NameValuePair "transform" "translateX(10px) translateY(20px)"
              }
            , { description = "Translate.initXZ writes XZ and omits untouched Y"
              , initFuncs = f.initXZ animGroup 10 30
              , expected = NameValuePair "transform" "translateX(10px) translateZ(30px)"
              }
            , { description = "Translate.initYZ writes YZ and omits untouched X"
              , initFuncs = f.initYZ animGroup 20 30
              , expected = NameValuePair "transform" "translateY(20px) translateZ(30px)"
              }
            , { description = "Translate.initXYZ writes XYZ promoted to translate3d"
              , initFuncs = f.initXYZ animGroup 10 20 30
              , expected = NameValuePair "transform" "translate3d(10px, 20px, 30px)"
              }
            , { description = "Translate.initX with custom CSS unit writes X, and omits untouched YZ"
              , initFuncs =
                    f.initX animGroup 10
                        >> f.initCssUnitX Em
              , expected = NameValuePair "transform" "translateX(10em)"
              }
            , { description = "Translate.initY with custom CSS unit writes Y, and omits untouched XZ"
              , initFuncs =
                    f.initY animGroup 20
                        >> f.initCssUnitY Em
              , expected = NameValuePair "transform" "translateY(20em)"
              }
            , { description = "Translate.initZ with custom CSS unit writes Z, and omits untouched XY"
              , initFuncs =
                    f.initZ animGroup 30
                        >> f.initCssUnitZ Em
              , expected = NameValuePair "transform" "translateZ(30em)"
              }
            , { description = "Translate.initXY with custom CSS unit writes XY and omits untouched Z"
              , initFuncs =
                    f.initXY animGroup 10 20
                        >> f.initCssUnitX Em
                        >> f.initCssUnitY Em
              , expected = NameValuePair "transform" "translateX(10em) translateY(20em)"
              }
            , { description = "Translate.initXZ with custom CSS unit writes XZ and omits untouched Y"
              , initFuncs =
                    f.initXZ animGroup 10 30
                        >> f.initCssUnitX Em
                        >> f.initCssUnitZ Em
              , expected = NameValuePair "transform" "translateX(10em) translateZ(30em)"
              }
            , { description = "Translate.initYZ with custom CSS unit writes YZ and omits untouched X"
              , initFuncs =
                    f.initYZ animGroup 20 30
                        >> f.initCssUnitY Em
                        >> f.initCssUnitZ Em
              , expected = NameValuePair "transform" "translateY(20em) translateZ(30em)"
              }
            , { description = "Translate.initXYZ with custom CSS unit writes XYZ promoted to translate3d"
              , initFuncs =
                    f.initXYZ animGroup 10 20 30
                        >> f.initCssUnit Em
              , expected = NameValuePair "transform" "translate3d(10em, 20em, 30em)"
              }
            , { description = "Translate.initX prefers axis-specific unit when applied after global unit"
              , initFuncs =
                    f.initX animGroup 10
                        >> f.initCssUnit Em
                        >> f.initCssUnitX Px
              , expected = NameValuePair "transform" "translateX(10px)"
              }
            , { description = "Translate.initX uses global unit when applied after axis-specific unit"
              , initFuncs =
                    f.initX animGroup 10
                        >> f.initCssUnitX Px
                        >> f.initCssUnit Em
              , expected = NameValuePair "transform" "translateX(10em)"
              }
            , { description = "Translate.initX last write wins for duplicate initX calls"
              , initFuncs =
                    f.initX animGroup 10
                        >> f.initX animGroup 11
              , expected = NameValuePair "transform" "translateX(11px)"
              }
            ]
    }
