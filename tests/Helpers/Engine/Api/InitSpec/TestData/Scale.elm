module Helpers.Engine.Api.InitSpec.TestData.Scale exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias ScaleInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initZ : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initXZ : String -> Float -> Float -> builder
    , initYZ : String -> Float -> Float -> builder
    , initXYZ : String -> Float -> Float -> Float -> builder
    }


scaleTestData : ScaleInitFactory (a -> a) -> TestData (a -> a)
scaleTestData factory =
    { description = "Scale.init* tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Scale.initX writes X, and omits untouched YZ"
              , initFuncs = factory.initX animGroup 10
              , expected = NameValuePair "transform" "scaleX(10)"
              }
            , { description = "Scale.initY writes Y, and omits untouched XZ"
              , initFuncs = factory.initY animGroup 20
              , expected = NameValuePair "transform" "scaleY(20)"
              }
            , { description = "Scale.initZ writes Z, and omits untouched XY"
              , initFuncs = factory.initZ animGroup 30
              , expected = NameValuePair "transform" "scaleZ(30)"
              }
            , { description = "Scale.initXY writes XY and omits untouched Z"
              , initFuncs = factory.initXY animGroup 10 20
              , expected = NameValuePair "transform" "scaleX(10) scaleY(20)"
              }
            , { description = "Scale.initXZ writes XZ and omits untouched Y"
              , initFuncs = factory.initXZ animGroup 10 30
              , expected = NameValuePair "transform" "scaleX(10) scaleZ(30)"
              }
            , { description = "Scale.initYZ writes YZ and omits untouched X"
              , initFuncs = factory.initYZ animGroup 20 30
              , expected = NameValuePair "transform" "scaleY(20) scaleZ(30)"
              }
            , { description = "Scale.initXYZ writes XYZ"
              , initFuncs = factory.initXYZ animGroup 10 20 30
              , expected = NameValuePair "transform" "scaleX(10) scaleY(20) scaleZ(30)"
              }
            ]
    }
