module Anim.Engine.Keyframe.Api.InitSpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Keyframe.Properties.Translate.AxisSpec.Helpers exposing (..)
import Anim.Extra.Color as Color
import Anim.Property.Custom as Property
import Anim.Property.CustomColor as CustomColor
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Expect
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "Keyframe.init, writes inline styles, and will-change" <|
        List.map sizeTestCaseTest sizeTestData
            ++ List.map testDataTest testData
            ++ additionalContractTests


otherAnimGroup : String
otherAnimGroup =
    "el2"


renderedAttributes : String -> Keyframe.AnimState -> Query.Single msg
renderedAttributes groupName state =
    Html.div (Keyframe.attributes groupName state) []
        |> Query.fromHtml


additionalContractTests : List Test
additionalContractTests =
    [ test "composed init writes transform + opacity and combines will-change" <|
        \_ ->
            Keyframe.init
                [ Opacity.init animGroup 0.5
                , Translate.initX animGroup 10
                ]
                |> renderedAttributes animGroup
                |> Query.has
                    [ Selector.style "opacity" "0.5"
                    , Selector.style "transform" "translateX(10px)"
                    , Selector.style "will-change" "opacity, transform"
                    ]
    , test "Translate init css unit is isolated per group" <|
        \_ ->
            Keyframe.init
                [ Translate.initX animGroup 10
                    >> Translate.initCssUnitX Em
                , Translate.initX otherAnimGroup 10
                ]
                |> (\state ->
                        Expect.all
                            [ \_ ->
                                renderedAttributes animGroup state
                                    |> Query.has [ Selector.style "transform" "translateX(10em)" ]
                            , \_ ->
                                renderedAttributes otherAnimGroup state
                                    |> Query.has [ Selector.style "transform" "translateX(10px)" ]
                            ]
                            ()
                   )
    , test "Size init css unit is isolated per group" <|
        \_ ->
            Keyframe.init
                [ Size.initH animGroup 10
                    >> Size.initCssUnitH Em
                , Size.initH otherAnimGroup 10
                ]
                |> (\state ->
                        Expect.all
                            [ \_ ->
                                renderedAttributes animGroup state
                                    |> Query.has [ Selector.style "height" "10em" ]
                            , \_ ->
                                renderedAttributes otherAnimGroup state
                                    |> Query.has [ Selector.style "height" "10px" ]
                            ]
                            ()
                   )
    , test "PerspectiveOrigin init css unit is isolated per group" <|
        \_ ->
            Keyframe.init
                [ PerspectiveOrigin.initX animGroup 10
                    >> PerspectiveOrigin.initCssUnitX Px
                , PerspectiveOrigin.initX otherAnimGroup 10
                ]
                |> (\state ->
                        Expect.all
                            [ \_ ->
                                renderedAttributes animGroup state
                                    |> Query.has [ Selector.style "perspective-origin" "10px 50%" ]
                            , \_ ->
                                renderedAttributes otherAnimGroup state
                                    |> Query.has [ Selector.style "perspective-origin" "10% 50%" ]
                            ]
                            ()
                   )
    ]


testDataTest : TestData -> Test
testDataTest td =
    describe td.description <|
        List.map testCaseTest td.testCases


testCaseTest : TestCase -> Test
testCaseTest tc =
    test tc.description <|
        \_ ->
            Keyframe.init [ tc.initAxis ]
                |> (\state ->
                        Html.div (Keyframe.attributes animGroup state) []
                            |> Query.fromHtml
                            |> Query.has
                                [ Selector.style (Tuple.first tc.expected) (Tuple.second tc.expected)
                                , Selector.style "will-change" (Tuple.first tc.expected)
                                ]
                   )


sizeTestCaseTest : SizeTestCase -> Test
sizeTestCaseTest tc =
    test tc.description <|
        \_ ->
            Keyframe.init [ tc.initAxis ]
                |> (\state ->
                        Html.div (Keyframe.attributes animGroup state) []
                            |> Query.fromHtml
                            |> (\query ->
                                    case ( tc.expectedHeight, tc.expectedWidth ) of
                                        ( Just height, Just width ) ->
                                            Query.has
                                                [ Selector.style "height" height
                                                , Selector.style "width" width
                                                , Selector.style "will-change" tc.willChange
                                                ]
                                                query

                                        ( Just height, Nothing ) ->
                                            Query.has
                                                [ Selector.style "height" height
                                                , Selector.style "will-change" tc.willChange
                                                ]
                                                query

                                        ( Nothing, Just width ) ->
                                            Query.has
                                                [ Selector.style "width" width
                                                , Selector.style "will-change" tc.willChange
                                                ]
                                                query

                                        ( Nothing, Nothing ) ->
                                            Query.has [] query
                               )
                   )


testData : List TestData
testData =
    [ customPropertyTestData
    , customColorTestData
    , opacityTestData
    , perspectiveOriginTestData
    , rotateTestData
    , scaleTestData
    , skewTestData
    , translateTestData
    ]


type alias TestData =
    { description : String
    , testCases : List TestCase
    }


type alias TestCase =
    { description : String
    , initAxis : KeyframeBuilderFunction
    , expected : ( String, String )
    }



{-
   ==========================================================

   Custom Property Test Data

   ==========================================================
-}


customPropertyTestData : TestData
customPropertyTestData =
    { description = "Custom property tests"
    , testCases =
        [ { description = "Custom.init writes the border-radius"
          , initAxis = Property.init animGroup (Property.BorderRadius Em) 20
          , expected = ( "border-radius", "20em" )
          }
        , { description = "Custom.init writes the border-width"
          , initAxis = Property.init animGroup (Property.BorderWidth Px) 1
          , expected = ( "border-width", "1px" )
          }
        , { description = "Custom.init writes the custom property"
          , initAxis = Property.init animGroup (Property.Custom "my-custom-property" "unit") 10
          , expected = ( "my-custom-property", "10unit" )
          }
        , { description = "Custom.init writes a unitless property without suffix"
          , initAxis = Property.init animGroup (Property.LineHeight Unitless) 1.2
          , expected = ( "line-height", "1.2" )
          }
        ]
    }



{-
   ==========================================================

   Custom Color Test Data

   ==========================================================
-}


customColorTestData : TestData
customColorTestData =
    { description = "Custom color tests"
    , testCases =
        [ { description = "CustomColor.init writes the background color"
          , initAxis = CustomColor.init animGroup CustomColor.BackgroundColor (Color.rgb 255 0 0)
          , expected = ( "background-color", "rgb(255, 0, 0)" )
          }
        , { description = "CustomColor.init writes the border-color"
          , initAxis = CustomColor.init animGroup CustomColor.BorderColor (Color.rgb 0 255 0)
          , expected = ( "border-color", "rgb(0, 255, 0)" )
          }
        , { description = "CustomColor.init writes the custom property color"
          , initAxis = CustomColor.init animGroup (CustomColor.Custom "my-custom-property") (Color.rgb 0 0 0)
          , expected = ( "my-custom-property", "rgb(0, 0, 0)" )
          }
        ]
    }



{-
   ==========================================================

   Opacity Test Data

   ==========================================================
-}


opacityTestData : TestData
opacityTestData =
    { description = "Opacity.init tests"
    , testCases =
        [ { description = "Opacity.init writes the opacity inline style"
          , initAxis = Opacity.init animGroup 0.5
          , expected = ( "opacity", "0.5" )
          }
        ]
    }



{-
   ==========================================================

   PerspectiveOrigin Test Data

   ==========================================================
-}


perspectiveOriginTestData : TestData
perspectiveOriginTestData =
    { description = "PerspectiveOrigin.init tests"
    , testCases =
        [ { description = "PerspectiveOrigin.initX writes X, and defaults Y to 50%"
          , initAxis = PerspectiveOrigin.initX animGroup 10
          , expected = ( "perspective-origin", "10% 50%" )
          }
        , { description = "PerspectiveOrigin.initY writes Y, and defaults X to 50%"
          , initAxis = PerspectiveOrigin.initY animGroup 20
          , expected = ( "perspective-origin", "50% 20%" )
          }
        , { description = "PerspectiveOrigin.initXY writes XY"
          , initAxis = PerspectiveOrigin.initXY animGroup 10 20
          , expected = ( "perspective-origin", "10% 20%" )
          }
        , { description = "PerspectiveOrigin.initX with custom css unit writes X, and defaults Y to 50%"
          , initAxis =
                PerspectiveOrigin.initX animGroup 10
                    >> PerspectiveOrigin.initCssUnitX Px
          , expected = ( "perspective-origin", "10px 50%" )
          }
        , { description = "PerspectiveOrigin.initY with custom css unit writes Y, and defaults X to 50%"
          , initAxis =
                PerspectiveOrigin.initY animGroup 20
                    >> PerspectiveOrigin.initCssUnitY Px
          , expected = ( "perspective-origin", "50% 20px" )
          }
        , { description = "PerspectiveOrigin.initXY with custom css unit writes XY"
          , initAxis =
                PerspectiveOrigin.initXY animGroup 10 20
                    >> PerspectiveOrigin.initCssUnit Px
          , expected = ( "perspective-origin", "10px 20px" )
          }
        , { description = "PerspectiveOrigin.initX prefers axis-specific unit when applied after global unit, and untouched Y inherits global unit"
          , initAxis =
                PerspectiveOrigin.initX animGroup 10
                    >> PerspectiveOrigin.initCssUnit Em
                    >> PerspectiveOrigin.initCssUnitX Px
          , expected = ( "perspective-origin", "10px 50em" )
          }
        , { description = "PerspectiveOrigin.initX uses global unit when applied after axis-specific unit, including untouched Y"
          , initAxis =
                PerspectiveOrigin.initX animGroup 10
                    >> PerspectiveOrigin.initCssUnitX Px
                    >> PerspectiveOrigin.initCssUnit Em
          , expected = ( "perspective-origin", "10em 50em" )
          }
        , { description = "PerspectiveOrigin.initX last write wins for duplicate initX calls"
          , initAxis =
                PerspectiveOrigin.initX animGroup 10
                    >> PerspectiveOrigin.initX animGroup 15
          , expected = ( "perspective-origin", "15% 50%" )
          }
        ]
    }



{-
   ==========================================================

   Rotate Test Data

   ==========================================================
-}


rotateTestData : TestData
rotateTestData =
    { description = "Rotate.init* tests"
    , testCases =
        [ { description = "Rotate.initX writes X, and omits untouched YZ"
          , initAxis = Rotate.initX animGroup 10
          , expected = ( "transform", "rotateX(10deg)" )
          }
        , { description = "Rotate.initY writes Y, and omits untouched XZ"
          , initAxis = Rotate.initY animGroup 20
          , expected = ( "transform", "rotateY(20deg)" )
          }
        , { description = "Rotate.initZ writes Z, and omits untouched XY"
          , initAxis = Rotate.initZ animGroup 30
          , expected = ( "transform", "rotateZ(30deg)" )
          }
        , { description = "Rotate.initXY writes XY and omits untouched Z"
          , initAxis = Rotate.initXY animGroup 10 20
          , expected = ( "transform", "rotateX(10deg) rotateY(20deg)" )
          }
        , { description = "Rotate.initXZ writes XZ and omits untouched Y"
          , initAxis = Rotate.initXZ animGroup 10 30
          , expected = ( "transform", "rotateX(10deg) rotateZ(30deg)" )
          }
        , { description = "Rotate.initYZ writes YZ and omits untouched X"
          , initAxis = Rotate.initYZ animGroup 20 30
          , expected = ( "transform", "rotateY(20deg) rotateZ(30deg)" )
          }
        , { description = "Rotate.initXYZ writes XYZ"
          , initAxis = Rotate.initXYZ animGroup 10 20 30
          , expected = ( "transform", "rotateX(10deg) rotateY(20deg) rotateZ(30deg)" )
          }
        ]
    }



{-
   ==========================================================

   Scale Test Data

   ==========================================================
-}


scaleTestData : TestData
scaleTestData =
    { description = "Scale.init* tests"
    , testCases =
        [ { description = "Scale.initX writes X, and omits untouched YZ"
          , initAxis = Scale.initX animGroup 10
          , expected = ( "transform", "scaleX(10)" )
          }
        , { description = "Scale.initY writes Y, and omits untouched XZ"
          , initAxis = Scale.initY animGroup 20
          , expected = ( "transform", "scaleY(20)" )
          }
        , { description = "Scale.initZ writes Z, and omits untouched XY"
          , initAxis = Scale.initZ animGroup 30
          , expected = ( "transform", "scaleZ(30)" )
          }
        , { description = "Scale.initXY writes XY and omits untouched Z"
          , initAxis = Scale.initXY animGroup 10 20
          , expected = ( "transform", "scaleX(10) scaleY(20)" )
          }
        , { description = "Scale.initXZ writes XZ and omits untouched Y"
          , initAxis = Scale.initXZ animGroup 10 30
          , expected = ( "transform", "scaleX(10) scaleZ(30)" )
          }
        , { description = "Scale.initYZ writes YZ and omits untouched X"
          , initAxis = Scale.initYZ animGroup 20 30
          , expected = ( "transform", "scaleY(20) scaleZ(30)" )
          }
        , { description = "Scale.initXYZ writes XYZ"
          , initAxis = Scale.initXYZ animGroup 10 20 30
          , expected = ( "transform", "scaleX(10) scaleY(20) scaleZ(30)" )
          }
        ]
    }



{-
   ==========================================================

   Size Test Data

   ==========================================================
-}


type alias SizeTestCase =
    { description : String
    , initAxis : KeyframeBuilderFunction
    , expectedHeight : Maybe String
    , expectedWidth : Maybe String
    , willChange : String
    }


sizeTestData : List SizeTestCase
sizeTestData =
    [ { description = "Size.initH writes height, and omits untouched width"
      , initAxis = Size.initH animGroup 10
      , expectedHeight = Just "10px"
      , expectedWidth = Nothing
      , willChange = "height"
      }
    , { description = "Size.initW writes width, and omits untouched height"
      , initAxis = Size.initW animGroup 20
      , expectedHeight = Nothing
      , expectedWidth = Just "20px"
      , willChange = "width"
      }
    , { description = "Size.initHW writes height and width"
      , initAxis = Size.initHW animGroup 10 20
      , expectedHeight = Just "10px"
      , expectedWidth = Just "20px"
      , willChange = "width, height"
      }
    , { description = "Size.initH with custom CSS unit writes height, and omits untouched width"
      , initAxis =
            Size.initH animGroup 10
                >> Size.initCssUnitH Em
      , expectedHeight = Just "10em"
      , expectedWidth = Nothing
      , willChange = "height"
      }
    , { description = "Size.initW with custom CSS unit writes width, and omits untouched height"
      , initAxis =
            Size.initW animGroup 10
                >> Size.initCssUnitW Em
      , expectedHeight = Nothing
      , expectedWidth = Just "10em"
      , willChange = "width"
      }
    , { description = "Size.initHW with custom CSS unit writes height and width"
      , initAxis =
            Size.initHW animGroup 10 20
                >> Size.initCssUnit Em
      , expectedHeight = Just "10em"
      , expectedWidth = Just "20em"
      , willChange = "width, height"
      }
    , { description = "Size.initH prefers axis-specific unit when applied after global unit"
      , initAxis =
            Size.initH animGroup 10
                >> Size.initCssUnit Em
                >> Size.initCssUnitH Px
      , expectedHeight = Just "10px"
      , expectedWidth = Nothing
      , willChange = "height"
      }
    , { description = "Size.initH uses global unit when applied after axis-specific unit"
      , initAxis =
            Size.initH animGroup 10
                >> Size.initCssUnitH Px
                >> Size.initCssUnit Em
      , expectedHeight = Just "10em"
      , expectedWidth = Nothing
      , willChange = "height"
      }
    , { description = "Size.initH last write wins for duplicate initH calls"
      , initAxis =
            Size.initH animGroup 10
                >> Size.initH animGroup 12
      , expectedHeight = Just "12px"
      , expectedWidth = Nothing
      , willChange = "height"
      }
    ]



{-
   ==========================================================

   Skew Test Data

   ==========================================================
-}


skewTestData : TestData
skewTestData =
    { description = "Skew.init* tests"
    , testCases =
        [ { description = "Skew.initX writes skewX, and omits untouched Y"
          , initAxis = Skew.initX animGroup 10
          , expected = ( "transform", "skewX(10deg)" )
          }
        , { description = "Skew.initY writes skewY, and omits untouched X"
          , initAxis = Skew.initY animGroup 20
          , expected = ( "transform", "skewY(20deg)" )
          }
        , { description = "Skew.initXY writes skewX and skewY"
          , initAxis = Skew.initXY animGroup 10 20
          , expected = ( "transform", "skewX(10deg) skewY(20deg)" )
          }
        ]
    }



{-
   ==========================================================

   Translate Test Data

   ==========================================================
-}


translateTestData : TestData
translateTestData =
    { description = "Translate.init* tests"
    , testCases =
        [ { description = "Translate.initX writes X, and omits untouched YZ"
          , initAxis = Translate.initX animGroup 10
          , expected = ( "transform", "translateX(10px)" )
          }
        , { description = "Translate.initY writes Y, and omits untouched XZ"
          , initAxis = Translate.initY animGroup 20
          , expected = ( "transform", "translateY(20px)" )
          }
        , { description = "Translate.initZ writes Z, and omits untouched XY"
          , initAxis = Translate.initZ animGroup 30
          , expected = ( "transform", "translateZ(30px)" )
          }
        , { description = "Translate.initXY writes XY and omits untouched Z"
          , initAxis = Translate.initXY animGroup 10 20
          , expected = ( "transform", "translateX(10px) translateY(20px)" )
          }
        , { description = "Translate.initXZ writes XZ and omits untouched Y"
          , initAxis = Translate.initXZ animGroup 10 30
          , expected = ( "transform", "translateX(10px) translateZ(30px)" )
          }
        , { description = "Translate.initYZ writes YZ and omits untouched X"
          , initAxis = Translate.initYZ animGroup 20 30
          , expected = ( "transform", "translateY(20px) translateZ(30px)" )
          }
        , { description = "Translate.initXYZ writes XYZ promoted to translate3d"
          , initAxis = Translate.initXYZ animGroup 10 20 30
          , expected = ( "transform", "translate3d(10px, 20px, 30px)" )
          }
        , { description = "Translate.initX with custom CSS unit writes X, and omits untouched YZ"
          , initAxis =
                Translate.initX animGroup 10
                    >> Translate.initCssUnitX Em
          , expected = ( "transform", "translateX(10em)" )
          }
        , { description = "Translate.initY with custom CSS unit writes Y, and omits untouched XZ"
          , initAxis =
                Translate.initY animGroup 20
                    >> Translate.initCssUnitY Em
          , expected = ( "transform", "translateY(20em)" )
          }
        , { description = "Translate.initZ with custom CSS unit writes Z, and omits untouched XY"
          , initAxis =
                Translate.initZ animGroup 30
                    >> Translate.initCssUnitZ Em
          , expected = ( "transform", "translateZ(30em)" )
          }
        , { description = "Translate.initXY with custom CSS unit writes XY and omits untouched Z"
          , initAxis =
                Translate.initXY animGroup 10 20
                    >> Translate.initCssUnitX Em
                    >> Translate.initCssUnitY Em
          , expected = ( "transform", "translateX(10em) translateY(20em)" )
          }
        , { description = "Translate.initXZ with custom CSS unit writes XZ and omits untouched Y"
          , initAxis =
                Translate.initXZ animGroup 10 30
                    >> Translate.initCssUnitX Em
                    >> Translate.initCssUnitZ Em
          , expected = ( "transform", "translateX(10em) translateZ(30em)" )
          }
        , { description = "Translate.initYZ with custom CSS unit writes YZ and omits untouched X"
          , initAxis =
                Translate.initYZ animGroup 20 30
                    >> Translate.initCssUnitY Em
                    >> Translate.initCssUnitZ Em
          , expected = ( "transform", "translateY(20em) translateZ(30em)" )
          }
        , { description = "Translate.initXYZ with custom CSS unit writes XYZ promoted to translate3d"
          , initAxis =
                Translate.initXYZ animGroup 10 20 30
                    >> Translate.initCssUnit Em
          , expected = ( "transform", "translate3d(10em, 20em, 30em)" )
          }
        , { description = "Translate.initX prefers axis-specific unit when applied after global unit"
          , initAxis =
                Translate.initX animGroup 10
                    >> Translate.initCssUnit Em
                    >> Translate.initCssUnitX Px
          , expected = ( "transform", "translateX(10px)" )
          }
        , { description = "Translate.initX uses global unit when applied after axis-specific unit"
          , initAxis =
                Translate.initX animGroup 10
                    >> Translate.initCssUnitX Px
                    >> Translate.initCssUnit Em
          , expected = ( "transform", "translateX(10em)" )
          }
        , { description = "Translate.initX last write wins for duplicate initX calls"
          , initAxis =
                Translate.initX animGroup 10
                    >> Translate.initX animGroup 11
          , expected = ( "transform", "translateX(11px)" )
          }
        ]
    }
