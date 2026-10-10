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
    List.map (\( ctor, cssName ) -> ( ( ctor Px, 10 ), ( cssName, "10px" ) )) unitProperties
        ++ [ ( ( LineHeight Unitless, 1.2 ), ( "line-height", "1.2" ) )
           , ( ( FlexGrow, 2 ), ( "flex-grow", "2" ) )
           , ( ( FlexShrink, 1 ), ( "flex-shrink", "1" ) )
           , ( ( Cx, 10 ), ( "cx", "10" ) )
           , ( ( Cy, 10 ), ( "cy", "10" ) )
           , ( ( R, 10 ), ( "r", "10" ) )
           , ( ( Rx, 10 ), ( "rx", "10" ) )
           , ( ( Ry, 10 ), ( "ry", "10" ) )
           , ( ( StrokeDashOffset, 10 ), ( "stroke-dashoffset", "10" ) )
           , ( ( StrokeWidth, 10 ), ( "stroke-width", "10" ) )
           , ( ( Custom "my-custom-property" "unit", 10 ), ( "my-custom-property", "10unit" ) )
           ]


unitProperties : List ( Unit -> Property, String )
unitProperties =
    [ ( BorderBottomLeftRadius, "border-bottom-left-radius" )
    , ( BorderBottomRightRadius, "border-bottom-right-radius" )
    , ( BorderBottomWidth, "border-bottom-width" )
    , ( BorderLeftWidth, "border-left-width" )
    , ( BorderRadius, "border-radius" )
    , ( BorderRightWidth, "border-right-width" )
    , ( BorderTopLeftRadius, "border-top-left-radius" )
    , ( BorderTopRightRadius, "border-top-right-radius" )
    , ( BorderTopWidth, "border-top-width" )
    , ( BorderWidth, "border-width" )
    , ( Bottom, "bottom" )
    , ( ColumnGap, "column-gap" )
    , ( ColumnWidth, "column-width" )
    , ( FontSize, "font-size" )
    , ( Gap, "gap" )
    , ( Inset, "inset" )
    , ( Left, "left" )
    , ( LetterSpacing, "letter-spacing" )
    , ( Margin, "margin" )
    , ( MarginBottom, "margin-bottom" )
    , ( MarginLeft, "margin-left" )
    , ( MarginRight, "margin-right" )
    , ( MarginTop, "margin-top" )
    , ( MaxHeight, "max-height" )
    , ( MaxWidth, "max-width" )
    , ( MinHeight, "min-height" )
    , ( MinWidth, "min-width" )
    , ( OutlineOffset, "outline-offset" )
    , ( OutlineWidth, "outline-width" )
    , ( Padding, "padding" )
    , ( PaddingBottom, "padding-bottom" )
    , ( PaddingLeft, "padding-left" )
    , ( PaddingRight, "padding-right" )
    , ( PaddingTop, "padding-top" )
    , ( Perspective, "perspective" )
    , ( Right, "right" )
    , ( RowGap, "row-gap" )
    , ( TabSize, "tab-size" )
    , ( TextIndent, "text-indent" )
    , ( Top, "top" )
    , ( WordSpacing, "word-spacing" )
    , ( FlexBasis, "flex-basis" )
    ]
