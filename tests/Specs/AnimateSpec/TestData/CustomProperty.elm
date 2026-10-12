module Specs.AnimateSpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property exposing (Property)
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (TimingProfile(..))
import Specs.Shared.CustomProperty as Custom


testData : TestData (AnimBuilder eng)
testData =
    { description = "the Custom property writes supported numeric CSS properties across timing profiles"
    , testCases =
        buildPropertyCases NoTiming
            ++ buildPropertyCases (DelayMs 500)
            ++ buildPropertyCases (DurationMs 500)
    }


buildPropertyCases : TimingProfile -> List (TestCase (AnimBuilder eng))
buildPropertyCases timing =
    List.map
        (\( ( property, value ), ( cssProp, expected ) ) ->
            TD.buildPropertyCase cssProp timing <|
                buildPropertyCase property value cssProp expected
        )
        Custom.all


buildPropertyCase : Property -> Float -> String -> String -> PropertyCase (AnimBuilder eng)
buildPropertyCase property value propertyName expected =
    { description = "`to` writes the " ++ propertyName ++ " with a value of " ++ expected
    , propertyPipeline =
        Property.begin property
            >> Property.to value
            >> Property.end
    , expected = expected
    , notExpected = []
    }
