module Specs.AnimateSpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property exposing (Property(..))
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData, TimingProfile(..))


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom property tests"
    , testCases =
        buildPropertyCases NoTiming properties
            ++ buildPropertyCases (DelayMs 500) properties
            ++ buildPropertyCases (DurationMs 500) properties
    }


buildPropertyCases : TimingProfile -> List ( ( Property, Float ), ( String, String ) ) -> List (TestCase (AnimBuilder eng))
buildPropertyCases timing =
    List.map
        (\( ( property, value ), ( cssProp, expected ) ) ->
            TD.buildPropertyCase cssProp timing <|
                buildPropertyCase property value cssProp expected
        )


buildPropertyCase : Property -> Float -> String -> String -> PropertyCase (AnimBuilder eng)
buildPropertyCase property value propertyName expected =
    { description = "Custom.to writes the " ++ propertyName ++ " property value"
    , propertyPipeline =
        Property.begin property
            >> Property.to value
            >> Property.end
    , expected = expected
    , notExpected = []
    }


properties : List ( ( Property, Float ), ( String, String ) )
properties =
    [ ( ( Property.BorderRadius Em, 20 ), ( "border-radius", "20em" ) )
    , ( ( Property.BorderWidth Px, 1 ), ( "border-width", "1px" ) )
    , ( ( Property.LineHeight Unitless, 1.2 ), ( "line-height", "1.2" ) )
    , ( ( Property.Custom "my-custom-property" "unit", 10 ), ( "my-custom-property", "10unit" ) )
    ]
