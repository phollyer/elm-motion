module Specs.InitSpec.TestData.Skew exposing (testData)

import Factories.Properties.Skew exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.Runner exposing (..)


testData : Factory a -> TestData (a -> a)
testData factory =
    { description = "Skew.init* tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Skew.initX writes skewX, and omits untouched Y"
              , initFuncs = factory.initX animGroup 10
              , expected = NameValuePair "transform" "skewX(10deg)"
              }
            , { description = "Skew.initX with 0 writes only skewX, and omits untouched Y"
              , initFuncs = factory.initX animGroup 0
              , expected = NameValuePair "transform" "skewX(0deg)"
              }
            , { description = "Skew.initY writes skewY, and omits untouched X"
              , initFuncs = factory.initY animGroup 20
              , expected = NameValuePair "transform" "skewY(20deg)"
              }
            , { description = "Skew.initY with 0 writes only skewY, and omits untouched X"
              , initFuncs = factory.initY animGroup 0
              , expected = NameValuePair "transform" "skewY(0deg)"
              }
            , { description = "Skew.initXY writes skewX and skewY"
              , initFuncs = factory.initXY animGroup 10 20
              , expected = NameValuePair "transform" "skewX(10deg) skewY(20deg)"
              }
            ]
    }
