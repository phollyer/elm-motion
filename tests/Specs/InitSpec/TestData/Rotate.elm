module Specs.InitSpec.TestData.Rotate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Rotate.init* tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Rotate.initX writes X, and omits untouched YZ"
              , initFuncs = [ Rotate.initX animGroup 10 ]
              , expected = [ NameValuePair "transform" "rotateX(10deg)" ]
              }
            , { description = "Rotate.initY writes Y, and omits untouched XZ"
              , initFuncs = [ Rotate.initY animGroup 20 ]
              , expected = [ NameValuePair "transform" "rotateY(20deg)" ]
              }
            , { description = "Rotate.initZ writes Z, and omits untouched XY"
              , initFuncs = [ Rotate.initZ animGroup 30 ]
              , expected = [ NameValuePair "transform" "rotateZ(30deg)" ]
              }
            , { description = "Rotate.initXY writes XY and omits untouched Z"
              , initFuncs = [ Rotate.initXY animGroup 10 20 ]
              , expected = [ NameValuePair "transform" "rotateX(10deg) rotateY(20deg)" ]
              }
            , { description = "Rotate.initXZ writes XZ and omits untouched Y"
              , initFuncs = [ Rotate.initXZ animGroup 10 30 ]
              , expected = [ NameValuePair "transform" "rotateX(10deg) rotateZ(30deg)" ]
              }
            , { description = "Rotate.initYZ writes YZ and omits untouched X"
              , initFuncs = [ Rotate.initYZ animGroup 20 30 ]
              , expected = [ NameValuePair "transform" "rotateY(20deg) rotateZ(30deg)" ]
              }
            , { description = "Rotate.initXYZ writes XYZ"
              , initFuncs = [ Rotate.initXYZ animGroup 10 20 30 ]
              , expected = [ NameValuePair "transform" "rotateX(10deg) rotateY(20deg) rotateZ(30deg)" ]
              }
            ]
    }
