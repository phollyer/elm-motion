module Specs.InitSpec.TestData.Scale exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Scale.init* tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Scale.initX writes X, and omits untouched YZ"
              , initFuncs = [ Scale.initX animGroup 10 ]
              , expected = [ NameValuePair "transform" "scaleX(10)" ]
              }
            , { description = "Scale.initY writes Y, and omits untouched XZ"
              , initFuncs = [ Scale.initY animGroup 20 ]
              , expected = [ NameValuePair "transform" "scaleY(20)" ]
              }
            , { description = "Scale.initZ writes Z, and omits untouched XY"
              , initFuncs = [ Scale.initZ animGroup 30 ]
              , expected = [ NameValuePair "transform" "scaleZ(30)" ]
              }
            , { description = "Scale.initXY writes XY and omits untouched Z"
              , initFuncs = [ Scale.initXY animGroup 10 20 ]
              , expected = [ NameValuePair "transform" "scaleX(10) scaleY(20)" ]
              }
            , { description = "Scale.initXZ writes XZ and omits untouched Y"
              , initFuncs = [ Scale.initXZ animGroup 10 30 ]
              , expected = [ NameValuePair "transform" "scaleX(10) scaleZ(30)" ]
              }
            , { description = "Scale.initYZ writes YZ and omits untouched X"
              , initFuncs = [ Scale.initYZ animGroup 20 30 ]
              , expected = [ NameValuePair "transform" "scaleY(20) scaleZ(30)" ]
              }
            , { description = "Scale.initXYZ writes XYZ"
              , initFuncs = [ Scale.initXYZ animGroup 10 20 30 ]
              , expected = [ NameValuePair "transform" "scaleX(10) scaleY(20) scaleZ(30)" ]
              }
            ]
    }
