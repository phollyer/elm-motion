module Specs.AnimateSpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Specs.AnimateSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Opacity tests"
    , testCases =
        [ PropertyTest
            { description = "Opacity.to writes the opacity value"
            , propertyName = "opacity"
            , propertyPipeline =
                Opacity.begin
                    >> Opacity.to 0.5
                    >> Opacity.end
            , expected = [ NameValuePair "opacity" "0.5" ]
            }
        ]
    }
