module Specs.InitSpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Opacity.init tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Opacity.init writes the opacity inline style"
              , initFuncs = [ Opacity.init animGroup 0.5 ]
              , expected = [ NameValuePair "opacity" "0.5" ]
              , notExpected = []
              }
            ]
    }
