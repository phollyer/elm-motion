module Specs.InitSpec.TestData.Opacity exposing (testData)

import Anim.Unit exposing (Unit(..))
import Factories.Properties.Opacity exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.Runner exposing (..)


testData : Factory a b -> TestData (a -> a)
testData factory =
    { description = "Opacity.init tests"
    , testCases =
        List.map GeneralTest
            [ { description = "Opacity.init writes the opacity inline style"
              , initFuncs = factory.init animGroup 0.5
              , expected = NameValuePair "opacity" "0.5"
              }
            ]
    }
