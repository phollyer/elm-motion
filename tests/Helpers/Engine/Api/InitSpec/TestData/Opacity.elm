module Helpers.Engine.Api.InitSpec.TestData.Opacity exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias OpacityInitFactory builder =
    { init : String -> Float -> builder }


opacityTestData : OpacityInitFactory (a -> a) -> TestData (a -> a)
opacityTestData factory =
    { description = "Opacity.init tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Opacity.init writes the opacity inline style"
              , initFuncs = factory.init animGroup 0.5
              , expected = NameValuePair "opacity" "0.5"
              }
            ]
    }
