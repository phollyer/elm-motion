module Specs.InitSpec.TestData.Opacity exposing (testData)

import Factories.Properties.Opacity exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.Runner exposing (NameValuePair, TestCase(..), TestData)


testData : Factory a b -> TestData a
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
