module Specs.InitSpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Translate.init* tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Translate.initX writes X, and omits untouched YZ"
              , initFuncs = [ Translate.initX animGroup 10 ]
              , expected = [ NameValuePair "transform" "translateX(10px)" ]
              }
            , { description = "Translate.initY writes Y, and omits untouched XZ"
              , initFuncs = [ Translate.initY animGroup 20 ]
              , expected = [ NameValuePair "transform" "translateY(20px)" ]
              }
            , { description = "Translate.initZ writes Z, and omits untouched XY"
              , initFuncs = [ Translate.initZ animGroup 30 ]
              , expected = [ NameValuePair "transform" "translateZ(30px)" ]
              }
            , { description = "Translate.initXY writes XY and omits untouched Z"
              , initFuncs = [ Translate.initXY animGroup 10 20 ]
              , expected = [ NameValuePair "transform" "translateX(10px) translateY(20px)" ]
              }
            , { description = "Translate.initXZ writes XZ and omits untouched Y"
              , initFuncs = [ Translate.initXZ animGroup 10 30 ]
              , expected = [ NameValuePair "transform" "translateX(10px) translateZ(30px)" ]
              }
            , { description = "Translate.initYZ writes YZ and omits untouched X"
              , initFuncs = [ Translate.initYZ animGroup 20 30 ]
              , expected = [ NameValuePair "transform" "translateY(20px) translateZ(30px)" ]
              }
            , { description = "Translate.initXYZ writes XYZ promoted to translate3d"
              , initFuncs = [ Translate.initXYZ animGroup 10 20 30 ]
              , expected = [ NameValuePair "transform" "translate3d(10px, 20px, 30px)" ]
              }
            , { description = "Translate.initX with custom CSS unit writes X, and omits untouched YZ"
              , initFuncs =
                    [ Translate.initX animGroup 10
                        >> Translate.initCssUnitX Em
                    ]
              , expected = [ NameValuePair "transform" "translateX(10em)" ]
              }
            , { description = "Translate.initY with custom CSS unit writes Y, and omits untouched XZ"
              , initFuncs =
                    [ Translate.initY animGroup 20
                        >> Translate.initCssUnitY Em
                    ]
              , expected = [ NameValuePair "transform" "translateY(20em)" ]
              }
            , { description = "Translate.initZ with custom CSS unit writes Z, and omits untouched XY"
              , initFuncs =
                    [ Translate.initZ animGroup 30
                        >> Translate.initCssUnitZ Em
                    ]
              , expected = [ NameValuePair "transform" "translateZ(30em)" ]
              }
            , { description = "Translate.initXY with custom CSS unit writes XY and omits untouched Z"
              , initFuncs =
                    [ Translate.initXY animGroup 10 20
                        >> Translate.initCssUnitX Em
                        >> Translate.initCssUnitY Em
                    ]
              , expected = [ NameValuePair "transform" "translateX(10em) translateY(20em)" ]
              }
            , { description = "Translate.initXZ with custom CSS unit writes XZ and omits untouched Y"
              , initFuncs =
                    [ Translate.initXZ animGroup 10 30
                        >> Translate.initCssUnitX Em
                        >> Translate.initCssUnitZ Em
                    ]
              , expected = [ NameValuePair "transform" "translateX(10em) translateZ(30em)" ]
              }
            , { description = "Translate.initYZ with custom CSS unit writes YZ and omits untouched X"
              , initFuncs =
                    [ Translate.initYZ animGroup 20 30
                        >> Translate.initCssUnitY Em
                        >> Translate.initCssUnitZ Em
                    ]
              , expected = [ NameValuePair "transform" "translateY(20em) translateZ(30em)" ]
              }
            , { description = "Translate.initXYZ with custom CSS unit writes XYZ promoted to translate3d"
              , initFuncs =
                    [ Translate.initXYZ animGroup 10 20 30
                        >> Translate.initCssUnit Em
                    ]
              , expected = [ NameValuePair "transform" "translate3d(10em, 20em, 30em)" ]
              }
            , { description = "Translate.initX prefers axis-specific unit when applied after global unit"
              , initFuncs =
                    [ Translate.initX animGroup 10
                        >> Translate.initCssUnit Em
                        >> Translate.initCssUnitX Px
                    ]
              , expected = [ NameValuePair "transform" "translateX(10px)" ]
              }
            , { description = "Translate.initX uses global unit when applied after axis-specific unit"
              , initFuncs =
                    [ Translate.initX animGroup 10
                        >> Translate.initCssUnitX Px
                        >> Translate.initCssUnit Em
                    ]
              , expected = [ NameValuePair "transform" "translateX(10em)" ]
              }
            , { description = "Translate.initX last write wins for duplicate initX calls"
              , initFuncs =
                    [ Translate.initX animGroup 10
                        >> Translate.initX animGroup 11
                    ]
              , expected = [ NameValuePair "transform" "translateX(11px)" ]
              }
            ]
    }
