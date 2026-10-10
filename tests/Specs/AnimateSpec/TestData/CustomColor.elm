module Specs.AnimateSpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Specs.AnimateSpec.TestData as TD exposing (PropertyCase, TestCase(..), TestData, TimingProfile(..))


testData : TestData (AnimBuilder eng)
testData =
    { description = "Custom color tests"
    , testCases =
        buildPropertyCases NoTiming properties
            ++ buildPropertyCases (DelayMs 500) properties
            ++ buildPropertyCases (DurationMs 500) properties
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
    { description = "CustomColor.to writes the " ++ propertyName ++ " property value"
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


properties : List ( ColorProperty, String, String )
properties =
    [ ( AccentColor, "accent-color", "rgb(255, 0, 0)" )
    , ( BackgroundColor, "background-color", "rgb(255, 0, 0)" )
    , ( BorderBlockColor, "border-block-color", "rgb(255, 0, 0)" )
    , ( BorderBlockEndColor, "border-block-end-color", "rgb(255, 0, 0)" )
    , ( BorderBlockStartColor, "border-block-start-color", "rgb(255, 0, 0)" )
    , ( BorderBottomColor, "border-bottom-color", "rgb(255, 0, 0)" )
    , ( BorderColor, "border-color", "rgb(0, 255, 0)" )
    , ( BorderInlineColor, "border-inline-color", "rgb(255, 0, 0)" )
    , ( BorderInlineEndColor, "border-inline-end-color", "rgb(255, 0, 0)" )
    , ( BorderInlineStartColor, "border-inline-start-color", "rgb(255, 0, 0)" )
    , ( BorderLeftColor, "border-left-color", "rgb(255, 0, 0)" )
    , ( BorderRightColor, "border-right-color", "rgb(255, 0, 0)" )
    , ( BorderTopColor, "border-top-color", "rgb(255, 0, 0)" )
    , ( CaretColor, "caret-color", "rgb(255, 0, 0)" )
    , ( ColumnRuleColor, "column-rule-color", "rgb(255, 0, 0)" )
    , ( Fill, "fill", "rgb(255, 0, 0)" )
    , ( FloodColor, "flood-color", "rgb(255, 0, 0)" )
    , ( LightingColor, "lighting-color", "rgb(255, 0, 0)" )
    , ( OutlineColor, "outline-color", "rgb(255, 0, 0)" )
    , ( StopColor, "stop-color", "rgb(255, 0, 0)" )
    , ( Stroke, "stroke", "rgb(255, 0, 0)" )
    , ( TextColor, "color", "rgb(255, 0, 0)" )
    , ( TextDecorationColor, "text-decoration-color", "rgb(255, 0, 0)" )
    , ( TextEmphasisColor, "text-emphasis-color", "rgb(255, 0, 0)" )
    , ( Custom "my-custom-color-property", "my-custom-color-property", "rgb(0, 0, 0)" )
    ]
