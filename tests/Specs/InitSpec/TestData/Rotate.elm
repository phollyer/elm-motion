module Specs.InitSpec.TestData.Rotate exposing (..)

import Anim.Unit exposing (Unit(..))
import Factories.Properties.Rotate as RotateFactory
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.Runner exposing (..)


testData : RotateFactory.InitFactory (a -> a) -> TestData (a -> a)
testData factory =
    { description = "Rotate.init* tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Rotate.initX writes X, and omits untouched YZ"
              , initFuncs = factory.initX animGroup 10
              , expected = NameValuePair "transform" "rotateX(10deg)"
              }
            , { description = "Rotate.initY writes Y, and omits untouched XZ"
              , initFuncs = factory.initY animGroup 20
              , expected = NameValuePair "transform" "rotateY(20deg)"
              }
            , { description = "Rotate.initZ writes Z, and omits untouched XY"
              , initFuncs = factory.initZ animGroup 30
              , expected = NameValuePair "transform" "rotateZ(30deg)"
              }
            , { description = "Rotate.initXY writes XY and omits untouched Z"
              , initFuncs = factory.initXY animGroup 10 20
              , expected = NameValuePair "transform" "rotateX(10deg) rotateY(20deg)"
              }
            , { description = "Rotate.initXZ writes XZ and omits untouched Y"
              , initFuncs = factory.initXZ animGroup 10 30
              , expected = NameValuePair "transform" "rotateX(10deg) rotateZ(30deg)"
              }
            , { description = "Rotate.initYZ writes YZ and omits untouched X"
              , initFuncs = factory.initYZ animGroup 20 30
              , expected = NameValuePair "transform" "rotateY(20deg) rotateZ(30deg)"
              }
            , { description = "Rotate.initXYZ writes XYZ"
              , initFuncs = factory.initXYZ animGroup 10 20 30
              , expected = NameValuePair "transform" "rotateX(10deg) rotateY(20deg) rotateZ(30deg)"
              }
            ]
    }
