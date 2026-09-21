module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.RetargetTests exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Keyframe.Properties.Translate.AxisSpec.Helpers exposing (..)
import Anim.Property.Translate as Translate
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


{-| Retarget Tests

Tests the `retarget` pipeline for handling translate properties correctly.

Scenarios under test:

  - test inline style application
      - when retargeting with uninitialised axes
      - when retargeting with initialised axes
      - when retargeting multiple times with uninitialised axes
      - when retargeting multiple times with initialised axes
      - when retargeting an animation with uninitialised axes
      - when retargeting an animation with initialised axes

-}
suite : List Test
suite =
    [ retargetWithUninitialisedAxesTests
    , retargetWithInitialisedAxesTests
    , retargetMultipleTimesWithUninitialisedAxesTests
    , retargetMultipleTimesWithInitialisedAxesTests
    , retargetAfterAnimateWithUninitialisedAxesTests
    , retargetAfterAnimateWithInitialisedAxesTests
    ]



{-
   ==========================================================

   Retarget With Uninitialised Axes Tests

   ==========================================================
-}


retargetWithUninitialisedAxesTests : Test
retargetWithUninitialisedAxesTests =
    describe "with uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> retarget tc.retargetAxisFunction
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            retargetWithUninitialisedAxesTestData


type alias RetargetWithUninitialisedAxesTestData =
    List
        { description : String
        , retargetAxisFunction : KeyframeAxisFunction
        , expected : String
        }


retargetWithUninitialisedAxesTestData : RetargetWithUninitialisedAxesTestData
retargetWithUninitialisedAxesTestData =
    [ { description = "Translate.toX writes X and omits untouched YZ"
      , retargetAxisFunction = Translate.toX 120
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toY writes Y and omits untouched XZ"
      , retargetAxisFunction = Translate.toY 240
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toZ writes Z and omits untouched XY"
      , retargetAxisFunction = Translate.toZ 360
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toXY writes XY and omits untouched Z"
      , retargetAxisFunction = Translate.toXY 120 240
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXZ writes XZ and omits untouched Y"
      , retargetAxisFunction = Translate.toXZ 120 360
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toYZ writes YZ and omits untouched X"
      , retargetAxisFunction = Translate.toYZ 240 360
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toXYZ writes XYZ"
      , retargetAxisFunction = Translate.toXYZ 120 240 360
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Retarget With Initialised Axes Tests

   ==========================================================
-}


retargetWithInitialisedAxesTests : Test
retargetWithInitialisedAxesTests =
    describe "with initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> retarget tc.retargetAxisFunction
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            initialisedSingleRetargetTestData


type alias RetargetWithInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , retargetAxisFunction : KeyframeAxisFunction
        , expected : String
        }


initialisedSingleRetargetTestData : RetargetWithInitialisedAxesTestData
initialisedSingleRetargetTestData =
    [ { description = "Initialised X then Translate.toX overwrites X and omits untouched YZ"
      , initAxis = Translate.initX animGroup 10
      , retargetAxisFunction = Translate.toX 120
      , expected = "translateX(120px)"
      }
    , { description = "Initialised Y then Translate.toX keeps Y and writes X and omits untouched Z"
      , initAxis = Translate.initY animGroup 20
      , retargetAxisFunction = Translate.toX 120
      , expected = "translateX(120px) translateY(20px)"
      }
    , { description = "Initialised Z then Translate.toXY keeps Z and writes XY"
      , initAxis = Translate.initZ animGroup 30
      , retargetAxisFunction = Translate.toXY 120 240
      , expected = "translate3d(120px, 240px, 30px)"
      }
    , { description = "Initialised XY then Translate.toZ keeps XY and writes Z"
      , initAxis = Translate.initXY animGroup 10 20
      , retargetAxisFunction = Translate.toZ 360
      , expected = "translate3d(10px, 20px, 360px)"
      }
    , { description = "Initialised XYZ then Translate.toX keeps YZ and overwrites X"
      , initAxis = Translate.initXYZ animGroup 10 20 30
      , retargetAxisFunction = Translate.toX 120
      , expected = "translate3d(120px, 20px, 30px)"
      }
    ]



{-
   ==========================================================

   Retarget Multiple Times With Uninitialised Axes Tests

   ==========================================================
-}


retargetMultipleTimesWithUninitialisedAxesTests : Test
retargetMultipleTimesWithUninitialisedAxesTests =
    describe "with multiple retargets and uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> retargetMultiple tc.retargetAxesFunctions
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            retargetMultipleTimesWithUninitialisedAxesTestData


type alias RetargetMultipleTimesWithUninitialisedAxesTestData =
    List
        { description : String
        , retargetAxesFunctions : List KeyframeAxisFunction
        , expected : String
        }


retargetMultipleTimesWithUninitialisedAxesTestData : RetargetMultipleTimesWithUninitialisedAxesTestData
retargetMultipleTimesWithUninitialisedAxesTestData =
    [ { description = "Translate.toX then Translate.toX overwrites X and omits untouched YZ"
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toX 100
            ]
      , expected = "translateX(100px)"
      }
    , { description = "Translate.toX then Translate.toY keeps X, writes Y, and omits untouched Z"
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toX then Translate.toXY overwrites owned X, writes Y, and omits untouched Z"
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toXY 10 240
            ]
      , expected = "translateX(10px) translateY(240px)"
      }
    , { description = "Translate.toX then Translate.toYZ keeps owned X, writes YZ"
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toYZ 240 360
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Translate.toX then Translate.toXYZ overwrites owned X, writes YZ"
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toXYZ 10 240 360
            ]
      , expected = "translate3d(10px, 240px, 360px)"
      }
    , { description = "Translate.toY then Translate.toZ keeps owned Y, writes Z, and omits untouched X"
      , retargetAxesFunctions =
            [ Translate.toY 240
            , Translate.toZ 360
            ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toXY then Translate.toX keeps owned Y, overwrites owned X, and omits untouched Z"
      , retargetAxesFunctions =
            [ Translate.toXY 120 240
            , Translate.toX 10
            ]
      , expected = "translateX(10px) translateY(240px)"
      }
    , { description = "Translate.toXY then Translate.toZ keeps owned XY, writes Z"
      , retargetAxesFunctions =
            [ Translate.toXY 120 240
            , Translate.toZ 360
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Translate.toXY then Translate.toXY overwrites owned XY, and omits untouched Z"
      , retargetAxesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXY 10 20
            ]
      , expected = "translateX(10px) translateY(20px)"
      }
    , { description = "Translate.toXY then Translate.toXZ, keeps owned Y, overwrites owned X, and writes Z"
      , retargetAxesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXZ 10 360
            ]
      , expected = "translate3d(10px, 240px, 360px)"
      }
    , { description = "Translate.toXY then Translate.toXYZ, overwrites owned XY, and writes Z"
      , retargetAxesFunctions =
            [ Translate.toXY 120 240
            , Translate.toXYZ 10 20 30
            ]
      , expected = "translate3d(10px, 20px, 30px)"
      }
    , { description = "Translate.toX then Translate.toY then Translate.toZ keeps owned XY, writes Z"
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            , Translate.toZ 360
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Retarget Multiple Times With Initialised Axes Tests

   ==========================================================
-}


retargetMultipleTimesWithInitialisedAxesTests : Test
retargetMultipleTimesWithInitialisedAxesTests =
    describe "with multiple retargets and initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> retargetMultiple tc.retargetAxesFunctions
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            retargetMultipleTimesWithInitialisedAxesTestData


type alias RetargetMultipleTimesWithInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , retargetAxesFunctions : List KeyframeAxisFunction
        , expected : String
        }


retargetMultipleTimesWithInitialisedAxesTestData : RetargetMultipleTimesWithInitialisedAxesTestData
retargetMultipleTimesWithInitialisedAxesTestData =
    [ { description = "Initialised X with Translate.toY then Translate.toY, keeps X, writes Y, and omits untouched Z"
      , initAxis = Translate.initX animGroup 120
      , retargetAxesFunctions =
            [ Translate.toY 240
            , Translate.toY 10
            ]
      , expected = "translateX(120px) translateY(10px)"
      }
    , { description = "Initialised Y with Translate.toX then Translate.toY, keeps X, overwrites Y, and omits untouched Z"
      , initAxis = Translate.initY animGroup 240
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toY 20
            ]
      , expected = "translateX(120px) translateY(20px)"
      }
    , { description = "Initialised Z with Translate.toX then Translate.toY, keeps Z, keeps X, and writes Y"
      , initAxis = Translate.initZ animGroup 360
      , retargetAxesFunctions =
            [ Translate.toX 120
            , Translate.toY 240
            ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Retarget After Animate With Uninitialised Axes Tests

   ==========================================================
-}


retargetAfterAnimateWithUninitialisedAxesTests : Test
retargetAfterAnimateWithUninitialisedAxesTests =
    describe "after `animate` with uninitialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init []
                            |> animateWithDuration 500 tc.animateAxisFunction
                            |> retarget tc.retargetAxisFunction
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            retargetAfterAnimateWithUninitialisedAxesTestData


type alias RetargetAfterAnimateWithUninitialisedAxesTestData =
    List
        { description : String
        , animateAxisFunction : KeyframeAxisFunction
        , retargetAxisFunction : KeyframeAxisFunction
        , expected : String
        }


retargetAfterAnimateWithUninitialisedAxesTestData : RetargetAfterAnimateWithUninitialisedAxesTestData
retargetAfterAnimateWithUninitialisedAxesTestData =
    [ { description = "Animate Translate.toX then retarget Translate.toX overwrites X and omits untouched YZ"
      , animateAxisFunction = Translate.toX 120
      , retargetAxisFunction = Translate.toX 10
      , expected = "translateX(10px)"
      }
    , { description = "Animate Translate.toY then retarget Translate.toX keeps Y, writes X and omits untouched Z"
      , animateAxisFunction = Translate.toY 240
      , retargetAxisFunction = Translate.toX 120
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Animate Translate.toZ then retarget Translate.toXY keeps Z and writes XY"
      , animateAxisFunction = Translate.toZ 360
      , retargetAxisFunction = Translate.toXY 120 240
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]



{-
   ==========================================================

   Retarget After Animate With Initialised Axes Tests

   ==========================================================
-}


retargetAfterAnimateWithInitialisedAxesTests : Test
retargetAfterAnimateWithInitialisedAxesTests =
    describe "after `animate` with initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> animateWithDuration 500 tc.animateAxisFunction
                            |> retarget tc.retargetAxisFunction
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            retargetAfterAnimateWithInitialisedAxesTestData


type alias RetargetAfterAnimateWithInitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , animateAxisFunction : KeyframeAxisFunction
        , retargetAxisFunction : KeyframeAxisFunction
        , expected : String
        }


retargetAfterAnimateWithInitialisedAxesTestData : RetargetAfterAnimateWithInitialisedAxesTestData
retargetAfterAnimateWithInitialisedAxesTestData =
    [ { description = "Initialised X with animate Translate.toY then retarget Translate.toY keeps X and overwrites Y, and omits untouched Z"
      , initAxis = Translate.initX animGroup 120
      , animateAxisFunction = Translate.toY 240
      , retargetAxisFunction = Translate.toY 10
      , expected = "translateX(120px) translateY(10px)"
      }
    , { description = "Initialised Y with animate Translate.toX then retarget Translate.toY keeps X and overwrites Y, and omits untouched Z"
      , initAxis = Translate.initY animGroup 240
      , animateAxisFunction = Translate.toX 120
      , retargetAxisFunction = Translate.toY 20
      , expected = "translateX(120px) translateY(20px)"
      }
    , { description = "Initialised Z with animate Translate.toX then retarget Translate.toY keeps Z, keeps X, and writes Y"
      , initAxis = Translate.initZ animGroup 360
      , animateAxisFunction = Translate.toX 120
      , retargetAxisFunction = Translate.toY 240
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]
