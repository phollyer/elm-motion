module Helpers.Engine.Api.InitSpec.TestData.Translate exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias TranslateInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initZ : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initXZ : String -> Float -> Float -> builder
    , initYZ : String -> Float -> Float -> builder
    , initXYZ : String -> Float -> Float -> Float -> builder
    , initCssUnit : Unit -> builder
    , initCssUnitX : Unit -> builder
    , initCssUnitY : Unit -> builder
    , initCssUnitZ : Unit -> builder
    }


translateTestData : TranslateInitFactory (a -> a) -> TestData (a -> a)
translateTestData factory =
    { description = "Translate.init* tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Translate.initX writes X, and omits untouched YZ"
              , initFuncs = factory.initX animGroup 10
              , expected = NameValuePair "transform" "translateX(10px)"
              }
            , { description = "Translate.initY writes Y, and omits untouched XZ"
              , initFuncs = factory.initY animGroup 20
              , expected = NameValuePair "transform" "translateY(20px)"
              }
            , { description = "Translate.initZ writes Z, and omits untouched XY"
              , initFuncs = factory.initZ animGroup 30
              , expected = NameValuePair "transform" "translateZ(30px)"
              }
            , { description = "Translate.initXY writes XY and omits untouched Z"
              , initFuncs = factory.initXY animGroup 10 20
              , expected = NameValuePair "transform" "translateX(10px) translateY(20px)"
              }
            , { description = "Translate.initXZ writes XZ and omits untouched Y"
              , initFuncs = factory.initXZ animGroup 10 30
              , expected = NameValuePair "transform" "translateX(10px) translateZ(30px)"
              }
            , { description = "Translate.initYZ writes YZ and omits untouched X"
              , initFuncs = factory.initYZ animGroup 20 30
              , expected = NameValuePair "transform" "translateY(20px) translateZ(30px)"
              }
            , { description = "Translate.initXYZ writes XYZ promoted to translate3d"
              , initFuncs = factory.initXYZ animGroup 10 20 30
              , expected = NameValuePair "transform" "translate3d(10px, 20px, 30px)"
              }
            , { description = "Translate.initX with custom CSS unit writes X, and omits untouched YZ"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initCssUnitX Em
              , expected = NameValuePair "transform" "translateX(10em)"
              }
            , { description = "Translate.initY with custom CSS unit writes Y, and omits untouched XZ"
              , initFuncs =
                    factory.initY animGroup 20
                        >> factory.initCssUnitY Em
              , expected = NameValuePair "transform" "translateY(20em)"
              }
            , { description = "Translate.initZ with custom CSS unit writes Z, and omits untouched XY"
              , initFuncs =
                    factory.initZ animGroup 30
                        >> factory.initCssUnitZ Em
              , expected = NameValuePair "transform" "translateZ(30em)"
              }
            , { description = "Translate.initXY with custom CSS unit writes XY and omits untouched Z"
              , initFuncs =
                    factory.initXY animGroup 10 20
                        >> factory.initCssUnitX Em
                        >> factory.initCssUnitY Em
              , expected = NameValuePair "transform" "translateX(10em) translateY(20em)"
              }
            , { description = "Translate.initXZ with custom CSS unit writes XZ and omits untouched Y"
              , initFuncs =
                    factory.initXZ animGroup 10 30
                        >> factory.initCssUnitX Em
                        >> factory.initCssUnitZ Em
              , expected = NameValuePair "transform" "translateX(10em) translateZ(30em)"
              }
            , { description = "Translate.initYZ with custom CSS unit writes YZ and omits untouched X"
              , initFuncs =
                    factory.initYZ animGroup 20 30
                        >> factory.initCssUnitY Em
                        >> factory.initCssUnitZ Em
              , expected = NameValuePair "transform" "translateY(20em) translateZ(30em)"
              }
            , { description = "Translate.initXYZ with custom CSS unit writes XYZ promoted to translate3d"
              , initFuncs =
                    factory.initXYZ animGroup 10 20 30
                        >> factory.initCssUnit Em
              , expected = NameValuePair "transform" "translate3d(10em, 20em, 30em)"
              }
            , { description = "Translate.initX prefers axis-specific unit when applied after global unit"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initCssUnit Em
                        >> factory.initCssUnitX Px
              , expected = NameValuePair "transform" "translateX(10px)"
              }
            , { description = "Translate.initX uses global unit when applied after axis-specific unit"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initCssUnitX Px
                        >> factory.initCssUnit Em
              , expected = NameValuePair "transform" "translateX(10em)"
              }
            , { description = "Translate.initX last write wins for duplicate initX calls"
              , initFuncs =
                    factory.initX animGroup 10
                        >> factory.initX animGroup 11
              , expected = NameValuePair "transform" "translateX(11px)"
              }
            ]
    }
