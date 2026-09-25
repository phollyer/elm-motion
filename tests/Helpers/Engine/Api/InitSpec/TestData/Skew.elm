module Helpers.Engine.Api.InitSpec.TestData.Skew exposing (..)

import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias SkewInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    }


skewTestData : SkewInitFactory (a -> a) -> TestData (a -> a)
skewTestData factory =
    { description = "Skew.init* tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Skew.initX writes skewX, and omits untouched Y"
              , initFuncs = factory.initX animGroup 10
              , expected = NameValuePair "transform" "skewX(10deg)"
              }
            , { description = "Skew.initY writes skewY, and omits untouched X"
              , initFuncs = factory.initY animGroup 20
              , expected = NameValuePair "transform" "skewY(20deg)"
              }
            , { description = "Skew.initXY writes skewX and skewY"
              , initFuncs = factory.initXY animGroup 10 20
              , expected = NameValuePair "transform" "skewX(10deg) skewY(20deg)"
              }
            ]
    }
