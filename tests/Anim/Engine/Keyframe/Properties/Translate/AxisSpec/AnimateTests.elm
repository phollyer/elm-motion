module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.AnimateTests exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Keyframe.Properties.Translate.AxisSpec.Helpers exposing (..)
import Anim.Property.Translate as Translate
import Expect
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


{-| Animate Tests

Tests the `animate` pipeline for handling translate properties correctly.

Scenarios under test:

  - tests inline style application
      - when animating with zero duration and uninitialised axes
      - when animating with zero duration and initialised axes
      - when animating multiple times with zero duration and uninitialised axes
      - when animating multiple times with zero duration and initialised axes
  - tests keyframe rule generation
      - when animating with uninitialised axes
      - when animating with initialised axes
      - when animating multiple times with uninitialised axes
      - when animating multiple times with initialised axes

-}
suite : List Test
suite =
    [ animateWithZeroDurationAndUninitialisedAxesTests
    , animateWithZeroDurationAndInitialisedAxesTests
    , animateMultipleTimesWithZeroDurationAndUninitialisedAxesTests
    , animateMultipleTimesWithZeroDurationAndInitialisedAxesTests
    , animateWithUninitialisedAxesTests
    , animateWithInitialisedAxesTests
    , animateMultipleTimesWithUninitialisedAxesTests
    , animateMultipleTimesWithInitialisedAxesTests
    ]



{-
   ==========================================================

   Animate With Zero Duration And Uninitialised Axes Tests

   ==========================================================
-}


animateWithZeroDurationAndUninitialisedAxesTests : Test
animateWithZeroDurationAndUninitialisedAxesTests =
    describe "with zero duration and uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> animate tc.axisFunction
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            animateWithZeroDurationAndUninitialisedAxesTestData


type alias AnimateWithZeroDurationAndUninitialisedAxesTestData =
    List
        { description : String
        , axisFunction : KeyframeAxisFunction
        , expected : String
        }


animateWithZeroDurationAndUninitialisedAxesTestData : AnimateWithZeroDurationAndUninitialisedAxesTestData
animateWithZeroDurationAndUninitialisedAxesTestData =
    [ { description = "Translate.toX writes X, and omits untouched YZ"
      , axisFunction = Translate.toX 120
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toY writes Y, and omits untouched XZ"
      , axisFunction = Translate.toY 240
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toZ writes Z, and omits untouched XY"
      , axisFunction = Translate.toZ 360
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toXY writes XY, and omits untouched Z"
      , axisFunction = Translate.toXY 120 240
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXZ writes XZ, and omits untouched Y"
      , axisFunction = Translate.toXZ 120 360
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toYZ writes YZ, and omits untouched X"
      , axisFunction = Translate.toYZ 240 360
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toXYZ writes XYZ"
      , axisFunction = Translate.toXYZ 120 240 360
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Animate With Zero Duration And Initialised Axes Tests

   ==========================================================
-}


animateWithZeroDurationAndInitialisedAxesTests : Test
animateWithZeroDurationAndInitialisedAxesTests =
    describe "with zero duration and initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> animate tc.axisFunction
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            animateWithZeroDurationAndInitialisedAxesTestData


type alias AnimateWithZeroDurationAndInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , axisFunction : KeyframeAxisFunction
        , expected : String
        }


animateWithZeroDurationAndInitialisedAxesTestData : AnimateWithZeroDurationAndInitialisedAxesTestData
animateWithZeroDurationAndInitialisedAxesTestData =
    [ { description = "Initialised X then Translate.toX overwites X and omits untouched YZ"
      , initAxis = Translate.initX animGroup 10
      , axisFunction = Translate.toX 120
      , expected = "translateX(120px)"
      }
    , { description = "Initialised Y then Translate.toX keeps Y and writes X"
      , initAxis = Translate.initY animGroup 20
      , axisFunction = Translate.toX 120
      , expected = "translateX(120px) translateY(20px)"
      }
    , { description = "Initialised Z then Translate.toXY keeps Z and writes XY"
      , initAxis = Translate.initZ animGroup 30
      , axisFunction = Translate.toXY 120 240
      , expected = "translate3d(120px, 240px, 30px)"
      }
    , { description = "Initialised XY then Translate.toZ keeps XY and writes Z"
      , initAxis = Translate.initXY animGroup 10 20
      , axisFunction = Translate.toZ 360
      , expected = "translate3d(10px, 20px, 360px)"
      }
    , { description = "Initialised XYZ then Translate.toX keeps YZ and overwrites X"
      , initAxis = Translate.initXYZ animGroup 10 20 30
      , axisFunction = Translate.toX 120
      , expected = "translate3d(120px, 20px, 30px)"
      }
    ]



{-
   ==========================================================

   Animate Multiple Times With Zero Duration And Uninitialised Axes Tests

   ==========================================================
-}


animateMultipleTimesWithZeroDurationAndUninitialisedAxesTests : Test
animateMultipleTimesWithZeroDurationAndUninitialisedAxesTests =
    describe "with multiple zero duration animations and uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> animateMultiple tc.axesFunctions
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            animateMultipleTimesWithZeroDurationAndUninitialisedAxesTestData


type alias AnimateMultipleTimesWithZeroDurationAndUninitialisedAxesTestData =
    List
        { description : String
        , axesFunctions : List KeyframeAxisFunction
        , expected : String
        }


animateMultipleTimesWithZeroDurationAndUninitialisedAxesTestData : AnimateMultipleTimesWithZeroDurationAndUninitialisedAxesTestData
animateMultipleTimesWithZeroDurationAndUninitialisedAxesTestData =
    [ { description = "Translate.toX then Translate.toX, overwrites X and omits untouched YZ"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toX 100
            ]
      , expected = "translateX(100px)"
      }
    , { description = "Translate.toX then Translate.toY, keeps owned X, writes Y, and omits untouched Z"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toX then Translate.toXY overwrites owned X, writes Y, and omits untouched Z"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toXY 10 240
            ]
      , expected = "translateX(10px) translateY(240px)"
      }
    , { description = "Translate.toX then Translate.toYZ keeps owned X, writes YZ"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toYZ 240 360
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Translate.toX then Translate.toXYZ overwrites owned X, writes YZ"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toXYZ 10 240 360
            ]
      , expected = "translate3d(10px, 240px, 360px)"
      }
    , { description = "Translate.toY then Translate.toZ keeps owned Y, writes Z, and omits untouched X"
      , axesFunctions =
            [ Translate.toY 240
            , Translate.toZ 360
            ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toXY then Translate.toX keeps owned Y, overwrites owned X, and omits untouched Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toX 10
            ]
      , expected = "translateX(10px) translateY(240px)"
      }
    , { description = "Translate.toXY then Translate.toZ keeps owned XY, writes Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toZ 360
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Translate.toXY then Translate.toXY, overwrites owned XY, and omits untouched Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXY 10 20
            ]
      , expected = "translateX(10px) translateY(20px)"
      }
    , { description = "Translate.toXY then Translate.toXZ, keeps owned Y, overwrites owned X, and writes Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXZ 10 360
            ]
      , expected = "translate3d(10px, 240px, 360px)"
      }
    , { description = "Translate.toXY then Translate.toXYZ, overwrites owned XY, and writes Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXYZ 10 20 360
            ]
      , expected = "translate3d(10px, 20px, 360px)"
      }
    , { description = "Translate.toX then Translate.toY then Translate.toZ keeps owned XY, writes Z"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            , Translate.toZ 360
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Animate Multiple Times With Zero Duration And Initialised Axes Tests

   ==========================================================
-}


animateMultipleTimesWithZeroDurationAndInitialisedAxesTests : Test
animateMultipleTimesWithZeroDurationAndInitialisedAxesTests =
    describe "with multiple zero duration animations and initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> animateMultiple tc.axesFunctions
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            animateMultipleTimesWithZeroDurationAndInitialisedAxesTestData


type alias AnimateMultipleTimesWithZeroDurationAndInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , axesFunctions : List KeyframeAxisFunction
        , expected : String
        }


animateMultipleTimesWithZeroDurationAndInitialisedAxesTestData : AnimateMultipleTimesWithZeroDurationAndInitialisedAxesTestData
animateMultipleTimesWithZeroDurationAndInitialisedAxesTestData =
    [ { description = "Initialised X with Translate.toY then Translate.toY, keeps X, writes Y, and omits untouched Z"
      , initAxis = Translate.initX animGroup 120
      , axesFunctions =
            [ Translate.toY 240
            , Translate.toY 10
            ]
      , expected = "translateX(120px) translateY(10px)"
      }
    , { description = "Initialised Y with Translate.toX then Translate.toY, keeps X, overwrites Y, and omits untouched Z"
      , initAxis = Translate.initY animGroup 240
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 20
            ]
      , expected = "translateX(120px) translateY(20px)"
      }
    , { description = "Initialised Z with Translate.toX then Translate.toY, keeps Z, keeps X, and writes Y"
      , initAxis = Translate.initZ animGroup 360
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Animate With Uninitialised Axes Tests

   ==========================================================
-}


animateWithUninitialisedAxesTests : Test
animateWithUninitialisedAxesTests =
    describe "with uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> animateWithDuration 500 tc.axisFunction
                            |> keyframeString
                            |> Expect.all
                                (List.map
                                    (\( expected, transform ) ->
                                        String.contains transform >> Expect.equal expected
                                    )
                                    tc.expectations
                                )
            )
            animateWithUninitialisedAxesTestData


type alias AnimateWithUninitialisedAxesTestData =
    List
        { description : String
        , axisFunction : KeyframeAxisFunction
        , expectations : List ( Bool, String )
        }


animateWithUninitialisedAxesTestData : AnimateWithUninitialisedAxesTestData
animateWithUninitialisedAxesTestData =
    [ { description = "Translate.toX writes keyframe rule for X, from default 0 to end value and omits untouched YZ"
      , axisFunction = Translate.toX 120
      , expectations =
            [ ( True, "transform: translateX(0px);" )
            , ( True, "transform: translateX(120px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toY writes keyframe rule for Y, from default 0 to end value and omits untouched XZ"
      , axisFunction = Translate.toY 240
      , expectations =
            [ ( True, "transform: translateY(0px);" )
            , ( True, "transform: translateY(240px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(0px, 240px, 0px)" )
            ]
      }
    , { description = "Translate.toZ writes keyframe rule for Z, from default 0 to end value and omits untouched XY"
      , axisFunction = Translate.toZ 360
      , expectations =
            [ ( True, "transform: translateZ(0px);" )
            , ( True, "transform: translateZ(360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(0px, 0px, 360px)" )
            ]
      }
    , { description = "Translate.toXY writes keyframe rule for XY, from default 0 0 to end values and omits Z"
      , axisFunction = Translate.toXY 120 240
      , expectations =
            [ ( True, "transform: translateX(0px) translateY(0px);" )
            , ( True, "transform: translateX(120px) translateY(240px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 240px, 0px)" )
            ]
      }
    , { description = "Translate.toXZ writes keyframe rule for XZ, from default 0 0 to end values and omits Y"
      , axisFunction = Translate.toXZ 120 360
      , expectations =
            [ ( True, "transform: translateX(0px) translateZ(0px);" )
            , ( True, "transform: translateX(120px) translateZ(360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 360px)" )
            ]
      }
    , { description = "Translate.toYZ writes keyframe rule for YZ, from default 0 0 to end values and omits X"
      , axisFunction = Translate.toYZ 240 360
      , expectations =
            [ ( True, "transform: translateY(0px) translateZ(0px);" )
            , ( True, "transform: translateY(240px) translateZ(360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(0px, 240px, 360px)" )
            ]
      }
    , { description = "Translate.toXYZ writes keyframe rule for XYZ, from default 0 0 0 to end values and includes all axes"
      , axisFunction = Translate.toXYZ 120 240 360
      , expectations =
            [ ( True, "transform: translate3d(0px, 0px, 0px);" )
            , ( True, "transform: translate3d(120px, 240px, 360px);" )
            ]
      }
    ]



{-
   ==========================================================

   Animate With Initialised Axes Tests

   ==========================================================
-}


animateWithInitialisedAxesTests : Test
animateWithInitialisedAxesTests =
    describe "with initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> animateWithDuration 500 tc.axisFunction
                            |> keyframeString
                            |> Expect.all
                                (List.map
                                    (\( expected, transform ) ->
                                        String.contains transform >> Expect.equal expected
                                    )
                                    tc.expectations
                                )
            )
            animateWithInitialisedAxesTestData


type alias AnimateWithInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , axisFunction : KeyframeAxisFunction
        , expectations : List ( Bool, String )
        }


animateWithInitialisedAxesTestData : AnimateWithInitialisedAxesTestData
animateWithInitialisedAxesTestData =
    [ { description = "Initialised X then Translate.toX starts X from initialised value, writes X, and omits untouched YZ"
      , initAxis = Translate.initX animGroup 10
      , axisFunction = Translate.toX 120
      , expectations =
            [ ( True, "transform: translateX(10px);" )
            , ( True, "transform: translateX(120px);" )
            , ( False, "transform: translateX(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(10px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 0px)" )
            ]
      }
    , { description = "Initialised Y then Translate.toX keeps Y and writes X"
      , initAxis = Translate.initY animGroup 20
      , axisFunction = Translate.toX 120
      , expectations =
            [ ( True, "transform: translateX(0px) translateY(20px);" )
            , ( True, "transform: translateX(120px) translateY(20px);" )
            , ( False, "transform: translateX(0px) translateY(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 20px, 0px)" )
            ]
      }
    , { description = "Initialised Z then Translate.toXY keeps Z and writes XY"
      , initAxis = Translate.initZ animGroup 30
      , axisFunction = Translate.toXY 120 240
      , expectations =
            [ ( True, "transform: translate3d(0px, 0px, 30px);" )
            , ( True, "transform: translate3d(120px, 240px, 30px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 240px, 0px)" )
            ]
      }
    , { description = "Initialised XZ then Translate.toY starts XZ from initialised values, keeps XZ, and writes Y"
      , initAxis = Translate.initXZ animGroup 10 30
      , axisFunction = Translate.toY 240
      , expectations =
            [ ( True, "transform: translate3d(10px, 0px, 30px);" )
            , ( True, "transform: translate3d(10px, 240px, 30px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(0px, 240px, 0px)" )
            ]
      }
    , { description = "Initialised XYZ then Translate.toX starts XYZ from initialised values, keeps YZ, and overwrites X"
      , initAxis = Translate.initXYZ animGroup 10 20 30
      , axisFunction = Translate.toX 120
      , expectations =
            [ ( True, "transform: translate3d(10px, 20px, 30px);" )
            , ( True, "transform: translate3d(120px, 20px, 30px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 0px)" )
            ]
      }
    ]



{-
   ==========================================================

   Animate Multiple Times With Uninitialised Axes Tests

   ==========================================================
-}


animateMultipleTimesWithUninitialisedAxesTests : Test
animateMultipleTimesWithUninitialisedAxesTests =
    describe "with multiple animations and uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> animateMultipleWithDuration 500 tc.axesFunctions
                            |> keyframeString
                            |> Expect.all
                                (List.map
                                    (\( expected, transform ) ->
                                        String.contains transform >> Expect.equal expected
                                    )
                                    tc.expectations
                                )
            )
            animateMultipleTimesWithUninitialisedAxesTestData


type alias AnimateMultipleTimesWithUninitialisedAxesTestData =
    List
        { description : String
        , axesFunctions : List KeyframeAxisFunction
        , expectations : List ( Bool, String )
        }


animateMultipleTimesWithUninitialisedAxesTestData : AnimateMultipleTimesWithUninitialisedAxesTestData
animateMultipleTimesWithUninitialisedAxesTestData =
    [ { description = "Translate.toX then Translate.toX, writes X and omits untouched YZ"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toX 100
            ]
      , expectations =
            [ ( True, "transform: translateX(120px);" )
            , ( True, "transform: translateX(100px);" )
            , ( False, "transform: translateX(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 0px)" )
            , ( False, "translate3d(100px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toX then Translate.toY, keeps owned X, writes Y, and omits untouched Z"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            ]
      , expectations =
            [ ( True, "transform: translateX(120px) translateY(0px);" )
            , ( True, "transform: translateX(120px) translateY(240px);" )
            , ( False, "transform: translateX(0px) translateY(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 240px, 0px)" )
            ]
      }
    , { description = "Translate.toX then Translate.toXY writes owned X, writesY, and omits untouched Z"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toXY 10 240
            ]
      , expectations =
            [ ( True, "transform: translateX(120px) translateY(0px);" )
            , ( True, "transform: translateX(10px) translateY(240px);" )
            , ( False, "transform: translateX(0px) translateY(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 0px)" )
            , ( False, "translate3d(10px, 240px, 0px)" )
            ]
      }
    , { description = "Translate.toX then Translate.toYZ keeps owned X, writes YZ"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toYZ 240 360
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 0px, 0px);" )
            , ( True, "transform: translate3d(120px, 240px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toX then Translate.toXYZ writes owned X, writes YZ"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toXYZ 10 240 360
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 0px, 0px);" )
            , ( True, "transform: translate3d(10px, 240px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toY then Translate.toZ keeps owned Y, writes Z, and omits untouched X"
      , axesFunctions =
            [ Translate.toY 240
            , Translate.toZ 360
            ]
      , expectations =
            [ ( True, "transform: translateY(240px) translateZ(0px);" )
            , ( True, "transform: translateY(240px) translateZ(360px);" )
            , ( False, "transform: translateY(0px) translateZ(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(0px, 240px, 0px)" )
            , ( False, "translate3d(0px, 240px, 360px)" )
            ]
      }
    , { description = "Translate.toXY then Translate.toX keeps owned Y, writes owned X, and omits untouched Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toX 10
            ]
      , expectations =
            [ ( True, "transform: translateX(120px) translateY(240px);" )
            , ( True, "transform: translateX(10px) translateY(240px);" )
            , ( False, "transform: translateX(0px) translateY(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 240px, 0px)" )
            , ( False, "translate3d(10px, 240px, 0px)" )
            ]
      }
    , { description = "Translate.toXY then Translate.toZ keeps owned XY, writes Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toZ 360
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 240px, 0px);" )
            , ( True, "transform: translate3d(120px, 240px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toXY then Translate.toXY, writes owned XY, and omits untouched Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXY 10 20
            ]
      , expectations =
            [ ( True, "transform: translateX(120px) translateY(240px);" )
            , ( True, "transform: translateX(10px) translateY(20px);" )
            , ( False, "transform: translateX(0px) translateY(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 240px, 0px)" )
            , ( False, "translate3d(10px, 20px, 0px)" )
            ]
      }
    , { description = "Translate.toXY then Translate.toXZ, keeps owned Y, writes owned X, and writes Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXZ 10 360
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 240px, 0px);" )
            , ( True, "transform: translate3d(10px, 240px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toXY then Translate.toXYZ, writes owned XY, and writes Z"
      , axesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXYZ 10 20 360
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 240px, 0px);" )
            , ( True, "transform: translate3d(10px, 20px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    , { description = "Translate.toX then Translate.toY then Translate.toZ keeps owned XY, writes Z"
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            , Translate.toZ 360
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 240px, 0px);" )
            , ( True, "transform: translate3d(120px, 240px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    ]



{-
   ==========================================================

   Animate Multiple Times With Initialised Axes Test Data

   ==========================================================
-}


animateMultipleTimesWithInitialisedAxesTests : Test
animateMultipleTimesWithInitialisedAxesTests =
    describe "with multiple animations and initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> animateMultipleWithDuration 500 tc.axesFunctions
                            |> keyframeString
                            |> Expect.all
                                (List.map
                                    (\( expected, transform ) ->
                                        String.contains transform >> Expect.equal expected
                                    )
                                    tc.expectations
                                )
            )
            animateMultipleTimesWithInitialisedAxesTestData


type alias AnimateMultipleTimesWithInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , axesFunctions : List KeyframeAxisFunction
        , expectations : List ( Bool, String )
        }


animateMultipleTimesWithInitialisedAxesTestData : AnimateMultipleTimesWithInitialisedAxesTestData
animateMultipleTimesWithInitialisedAxesTestData =
    [ { description = "Initialised X with Translate.toY then Translate.toY, keeps X, writes Y, and omits untouched Z"
      , initAxis = Translate.initX animGroup 120
      , axesFunctions =
            [ Translate.toY 240
            , Translate.toY 10
            ]
      , expectations =
            [ ( True, "transform: translateX(120px) translateY(240px);" )
            , ( True, "transform: translateX(120px) translateY(10px);" )
            , ( False, "transform: translateX(0px) translateY(10px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 0px, 0px)" )
            ]
      }
    , { description = "Initialised Y with Translate.toX then Translate.toY, keeps X, writes Y, and omits untouched Z"
      , initAxis = Translate.initY animGroup 240
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 20
            ]
      , expectations =
            [ ( True, "transform: translateX(120px) translateY(240px);" )
            , ( True, "transform: translateX(120px) translateY(20px);" )
            , ( False, "transform: translateX(0px) translateY(0px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            , ( False, "translate3d(120px, 240px, 0px)" )
            ]
      }
    , { description = "Initialised Z with Translate.toX then Translate.toY, keeps Z, keeps X, and writes Y"
      , initAxis = Translate.initZ animGroup 360
      , axesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            ]
      , expectations =
            [ ( True, "transform: translate3d(120px, 0px, 360px);" )
            , ( True, "transform: translate3d(120px, 240px, 360px);" )
            , ( False, "translate3d(0px, 0px, 0px)" )
            ]
      }
    ]
