module Specs.InitSpec.TestData.Skew exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Skew.init* tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Skew.initX writes skewX, and omits untouched Y"
              , initFuncs = [ Skew.initX animGroup 10 ]
              , expected = [ NameValuePair "transform" "skewX(10deg)" ]
              }
            , { description = "Skew.initX with 0 writes only skewX, and omits untouched Y"
              , initFuncs = [ Skew.initX animGroup 0 ]
              , expected = [ NameValuePair "transform" "skewX(0deg)" ]
              }
            , { description = "Skew.initY writes skewY, and omits untouched X"
              , initFuncs = [ Skew.initY animGroup 20 ]
              , expected = [ NameValuePair "transform" "skewY(20deg)" ]
              }
            , { description = "Skew.initY with 0 writes only skewY, and omits untouched X"
              , initFuncs = [ Skew.initY animGroup 0 ]
              , expected = [ NameValuePair "transform" "skewY(0deg)" ]
              }
            , { description = "Skew.initXY writes skewX and skewY"
              , initFuncs = [ Skew.initXY animGroup 10 20 ]
              , expected = [ NameValuePair "transform" "skewX(10deg) skewY(20deg)" ]
              }
            ]
    }
