module Specs.AnimateSpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty)
import Specs.AnimateSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared.CustomColor as Custom
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData (AnimBuilder eng)
testData =
    { description = "the CustomColor property writes supported color properties across timing profiles"
    , testCases =
        buildPropertyCases NoTiming Custom.all
            ++ buildPropertyCases (DelayMs 500) Custom.all
            ++ buildPropertyCases (DurationMs 500) Custom.all
    }


buildPropertyCases : TimingProfile -> List ( ColorProperty, String, String ) -> List (TestCase (AnimBuilder eng))
buildPropertyCases timing =
    List.map
        (\( colorProp, propertyName, colorValue ) ->
            TD.buildPropertyCase propertyName timing <|
                buildPropertyCase colorProp propertyName colorValue
        )


buildPropertyCase : ColorProperty -> String -> String -> PropertyCase (AnimBuilder eng)
buildPropertyCase colorProp propertyName colorValue =
    { description = "`to` writes the " ++ propertyName ++ " color " ++ colorValue
    , propertyPipeline =
        case Color.fromString colorValue of
            Just color ->
                CustomColor.begin colorProp
                    >> CustomColor.to color
                    >> CustomColor.end

            Nothing ->
                identity
    , expected = colorValue
    , notExpected = []
    }
