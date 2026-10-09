module Specs.AnimateSpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property exposing (Property(..))
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom property tests"
    , testCases =
        List.map
            (\( ( property, value ), ( cssProp, expected ) ) ->
                PropertyTest
                    { description = "Custom writes the " ++ cssProp ++ " property value"
                    , propertyName = cssProp
                    , propertyPipeline =
                        Property.begin property
                            >> Property.to value
                            >> Property.end
                    , expected = [ NameValuePair cssProp expected ]
                    }
            )
            properties
    }


properties : List ( ( Property, Float ), ( String, String ) )
properties =
    [ ( ( Property.BorderRadius Em, 20 ), ( "border-radius", "20em" ) )
    , ( ( Property.BorderWidth Px, 1 ), ( "border-width", "1px" ) )
    , ( ( Property.LineHeight Unitless, 1.2 ), ( "line-height", "1.2" ) )
    , ( ( Property.Custom "my-custom-property" "unit", 10 ), ( "my-custom-property", "10unit" ) )
    ]
