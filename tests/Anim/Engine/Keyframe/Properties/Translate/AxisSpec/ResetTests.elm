module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.ResetTests exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Translate as Translate
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Keyframe as KH
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Reset: untouched axes do not get written, initialized axes are respected, and subsequent updates behave correctly,"
        [ afterAnimateWithDurationTests
        ]


afterAnimateWithDurationTests : Test
afterAnimateWithDurationTests =
    describe "when reset snaps to start state and writes inline transform" <|
        List.map
            (\testCase ->
                test testCase.description <|
                    \_ ->
                        Keyframe.init testCase.initValues
                            |> KH.animateMultipleWithDuration 500 testCase.axesFunctions
                            |> Keyframe.reset animGroup
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" testCase.expected ]
                               )
            )
            testData


afterRetargetTests : Test
afterRetargetTests =
    describe "when reset is called after retarget" <|
        List.map
            (\testCase ->
                test testCase.description <|
                    \_ ->
                        Keyframe.init testCase.initValues
                            |> KH.animateMultipleWithDuration 500 testCase.firstAnimationAxesFunctions
                            |> KH.retargetWith testCase.retargetAxesFunctions
                            |> Keyframe.reset animGroup
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" testCase.expected ]
                               )
            )
            afterRetargetTestData


type alias KeyframeBuilderFunction =
    KH.KeyframeBuilderFunction


type alias KeyframeAxisFunction =
    KH.KeyframeAxisFunction



{-
   ==========================================================

   Reset Test Data

   ==========================================================
-}


type alias TestData =
    { description : String
    , initValues : List KeyframeBuilderFunction
    , axesFunctions : List KeyframeAxisFunction
    , expected : String
    }


testData : List TestData
testData =
    uninitializedResetAfterAnimationTestData
        ++ initializedResetAfterAnimationTestData
        ++ uninitialisedResetAfterTwoAnimationsTestData
        ++ initialisedResetAfterTwoAnimationsTestData


uninitializedResetAfterAnimationTestData : List TestData
uninitializedResetAfterAnimationTestData =
    [ { description = "Translate.toX then Reset writes inline style, from default 0 to end value and omits untouched YZ"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toY then Reset writes inline style, from default 0 to end value and omits untouched XZ"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toZ then Reset writes inline style, from default 0 to end value and omits untouched XY"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toXY then Reset writes inline style, from default 0 0 to end values and omits Z"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXZ then Reset writes inline style, from default 0 0 to end values and omits Y"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset writes inline style, from default 0 0 to end values and omits X"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toXYZ then Reset writes inline style, from default 0 0 0 to end values and includes all axes"
      , initValues = []
      , axesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(0px, 0px, 0px)"
      }
    ]


initializedResetAfterAnimationTestData : List TestData
initializedResetAfterAnimationTestData =
    [ { description = "Initialised X with Translate.toX then Reset writes inline style and omits untouched YZ"
      , initValues = [ Translate.initX animGroup 10 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(10px)"
      }
    , { description = "Initialised Y with Translate.toY then Reset writes inline style and omits untouched XZ"
      , initValues = [ Translate.initY animGroup 20 ]
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(20px)"
      }
    , { description = "Initialised Z with Translate.toZ then Reset writes inline style and omits untouched XY"
      , initValues = [ Translate.initZ animGroup 30 ]
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(30px)"
      }
    , { description = "Initialised XY with Translate.toXY then Reset writes inline style and omits untouched Z"
      , initValues = [ Translate.initXY animGroup 10 20 ]
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(10px) translateY(20px)"
      }
    , { description = "Initialised XZ with Translate.toXZ then Reset writes inline style and omits untouched Y"
      , initValues = [ Translate.initXZ animGroup 10 30 ]
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(10px) translateZ(30px)"
      }
    , { description = "Initialised YZ with Translate.toYZ then Reset writes inline style and omits untouched X"
      , initValues = [ Translate.initYZ animGroup 20 30 ]
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(20px) translateZ(30px)"
      }
    , { description = "Initialised XYZ with Translate.toXYZ then Reset writes inline style and includes all axes"
      , initValues = [ Translate.initXYZ animGroup 10 20 30 ]
      , axesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(10px, 20px, 30px)"
      }
    ]


uninitialisedResetAfterTwoAnimationsTestData : List TestData
uninitialisedResetAfterTwoAnimationsTestData =
    [ { description = "Translate.toX then Reset writes inline style where X starts from previous value and omits untouched YZ [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120, Translate.toX 10 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Reset.toY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Reset.toZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Reset.toXY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Reset.toXZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Reset.toYZ keeps owned X inline style, starts Y and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Reset.toXYZ keeps owned X inline style, starts Y and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toY then Reset.toX keeps owned Y inline style, starts X from default 0, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Reset.toY writes inline style where Y starts from previous value, and omits untouched XZ [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Reset.toZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Reset.toXY keeps owned Y inline style, starts X from default 0, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Reset.toXZ keeps owned Y inline style, starts X and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Reset.toYZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Reset.toXYZ keeps owned Y inline style, starts X and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toZ then Reset.toX keeps owned Z inline style, starts X from default 0, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Reset.toY keeps owned Z inline style, starts Y from default 0, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Reset.toZ writes inline style where Z starts from previous value, and omits untouched XY [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Reset.toXY keeps owned Z inline style, starts X and Y from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Reset.toXZ keeps owned Z inline style, starts X from default 0, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Reset.toYZ keeps owned Z inline style, starts Y from default 0, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Reset.toXYZ keeps owned Z inline style, starts X and Y from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toXY then Reset.toX keeps owned Y inline style, starts X from previous value, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Reset.toY keeps owned X inline style, starts Y from previous value, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Reset.toZ keeps owned XY inline styles, starts Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Reset.toXY writes inline style where X and Y start from previous values, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Reset.toXZ keeps owned Y inline style, starts X from previous value, and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Reset.toYZ keeps owned X inline style, starts Y from previous value, and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Reset.toXYZ writes inline style where X and Y start from previous values, and Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXZ then Reset.toX keeps owned Z inline style, starts X from previous value, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Reset.toY keeps owned X and Z inline styles, starts Y from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Reset.toZ keeps owned X inline style, starts Z from previous value, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Reset.toXY keeps owned Z inline style, starts X from previous value, and Y from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Reset.toXZ writes inline style where X and Z start from previous values, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Reset.toYZ keeps owned X inline style, starts Y from default 0, and Z from previous value [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Reset.toXYZ writes inline style where X and Z start from previous values, and Y from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toX keeps owned Y and Z inline styles, starts X from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toY keeps owned Z inline style, starts Y from previous value, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toZ keeps owned Y inline style, starts Z from previous value, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toXY keeps owned Z inline style, starts Y from previous value, and X from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toXZ keeps owned Y inline style, starts Z from previous value, and X from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toYZ writes inline style where Y and Z start from previous values, and omits untouched X [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Reset.toXYZ writes inline style where Y and Z start from previous values, and X from default 0 [Reset snaps to first sequence start state]"
      , initValues = []
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    ]


initialisedResetAfterTwoAnimationsTestData : List TestData
initialisedResetAfterTwoAnimationsTestData =
    [ { description = "Initialised Y with Translate.toX then Reset.toX writes inline style where it carries Y from initialised value, starts X from previous value and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Reset.toX writes inline style where it carries Z from initialised value, starts X from previous value and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Reset.toY keeps owned X inline style, starts Y from initialised value, and omits untouched Z [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Reset.toY carries Z from initialised value, keeps owned X inline style, and starts Y from previous value [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Reset.toZ carries Y from initialised value, keeps owned X inline style, and starts Z from default 0 [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Reset.toZ keeps owned X inline style, and starts Z from initialised value, and omits untouched Y [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , axesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Reset.toX keeps owned Y and Z inline styles, and starts X from previous value [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(0px, 240px, 0px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Reset.toY keeps owned X and Z inline styles, and starts Y from previous value [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(0px, 240px, 0px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Reset.toZ keeps owned X and Y inline styles, and starts Z from previous value [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , axesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(0px, 240px, 0px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Reset.toX keeps owned Y and Z inline styles, and starts X from default 0 [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Reset.toY keeps owned Z inline style, and starts Y from previous value [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Reset.toZ keeps owned Y inline style, and starts Z from previous value [Reset snaps to first sequence start state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , axesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(360px)"
      }
    ]



{-
   ==========================================================

   After Retarget Tests

   ==========================================================
-}


type alias AfterRetargetTestData =
    { description : String
    , initValues : List KeyframeBuilderFunction
    , firstAnimationAxesFunctions : List KeyframeAxisFunction
    , retargetAxesFunctions : List KeyframeAxisFunction
    , expected : String
    }


afterRetargetTestData : List AfterRetargetTestData
afterRetargetTestData =
    [ { description = "Retarget.toX writes inline style and omits untouched YZ [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(0px)"
      }
    , { description = "Retarget.toY writes inline style and omits untouched XZ [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(0px)"
      }
    , { description = "Retarget.toZ writes inline style and omits untouched XY [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Retarget.toXY writes inline style and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Retarget.toXZ writes inline style and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Retarget.toYZ writes inline style and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Retarget.toXYZ writes inline style and includes all axes [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(0px, 0px, 0px)"
      }
    , { description = "Initialised X with Retarget.toX writes inline style and omits untouched YZ [Reset called after retarget]"
      , initValues = [ Translate.initX animGroup 10 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(10px)"
      }
    , { description = "Initialised Y with Retarget.toY writes inline style and omits untouched XZ [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 20 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(20px)"
      }
    , { description = "Initialised Z with Retarget.toZ writes inline style and omits untouched XY [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 30 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(30px)"
      }
    , { description = "Initialised XY with Retarget.toXY writes inline style and omits untouched Z [Reset called after retarget]"
      , initValues = [ Translate.initXY animGroup 10 20 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(10px) translateY(20px)"
      }
    , { description = "Initialised XZ with Retarget.toXZ writes inline style and omits untouched Y [Reset called after retarget]"
      , initValues = [ Translate.initXZ animGroup 10 30 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(10px) translateZ(30px)"
      }
    , { description = "Initialised YZ with Retarget.toYZ writes inline style and omits untouched X [Reset called after retarget]"
      , initValues = [ Translate.initYZ animGroup 20 30 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(20px) translateZ(30px)"
      }
    , { description = "Initialised XYZ with Retarget.toXYZ writes inline style and includes all axes [Reset called after retarget]"
      , initValues = [ Translate.initXYZ animGroup 10 20 30 ]
      , firstAnimationAxesFunctions = []
      , retargetAxesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(10px, 20px, 30px)"
      }
    , { description = "Translate.toX then Retarget.toX writes inline style where X starts from previous value and omits untouched YZ [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toX 10 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Retarget.toY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Retarget.toZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Retarget.toXY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toXY 10 240 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Retarget.toXZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toXZ 10 360 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Retarget.toYZ keeps owned X inline style, starts Y and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toX then Retarget.toXYZ keeps owned X inline style, starts Y and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toXYZ 10 240 360 ]
      , expected = "translateX(0px)"
      }
    , { description = "Translate.toY then Retarget.toX keeps owned Y inline style, starts X from default 0, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Retarget.toY writes inline style where Y starts from previous value, and omits untouched XZ [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toY 20 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Retarget.toZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Retarget.toXY keeps owned Y inline style, starts X from default 0, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toXY 10 20 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Retarget.toXZ keeps owned Y inline style, starts X and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toXZ 10 360 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Retarget.toYZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toYZ 20 360 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toY then Retarget.toXYZ keeps owned Y inline style, starts X and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , retargetAxesFunctions = [ Translate.toXYZ 120 20 360 ]
      , expected = "translateY(0px)"
      }
    , { description = "Translate.toZ then Retarget.toX keeps owned Z inline style, starts X from default 0, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Retarget.toY keeps owned Z inline style, starts Y from default 0, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Retarget.toZ writes inline style where Z starts from previous value, and omits untouched XY [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toZ 30 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Retarget.toXY keeps owned Z inline style, starts X and Y from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Retarget.toXZ keeps owned Z inline style, starts X from default 0, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toXZ 10 30 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Retarget.toYZ keeps owned Z inline style, starts Y from default 0, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toYZ 240 30 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toZ then Retarget.toXYZ keeps owned Z inline style, starts X and Y from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , retargetAxesFunctions = [ Translate.toXYZ 120 240 30 ]
      , expected = "translateZ(0px)"
      }
    , { description = "Translate.toXY then Retarget.toX keeps owned Y inline style, starts X from previous value, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toX 10 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Retarget.toY keeps owned X inline style, starts Y from previous value, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toY 20 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Retarget.toZ keeps owned XY inline styles, starts Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Retarget.toXY writes inline style where X and Y start from previous values, and omits untouched Z [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toXY 10 20 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Retarget.toXZ keeps owned Y inline style, starts X from previous value, and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toXZ 10 360 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Retarget.toYZ keeps owned X inline style, starts Y from previous value, and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toYZ 20 360 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXY then Retarget.toXYZ writes inline style where X and Y start from previous values, and Z from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , retargetAxesFunctions = [ Translate.toXYZ 10 20 360 ]
      , expected = "translateX(0px) translateY(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toX keeps owned Z inline style, starts X from previous value, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toX 10 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toY keeps owned X and Z inline styles, starts Y from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toZ keeps owned X inline style, starts Z from previous value, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toZ 30 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toXY keeps owned Z inline style, starts X from previous value, and Y from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toXY 10 240 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toXZ writes inline style where X and Z start from previous values, and omits untouched Y [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toXZ 10 30 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toYZ keeps owned X inline style, starts Y from default 0, and Z from previous value [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toYZ 240 30 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toXZ then Retarget.toXYZ writes inline style where X and Z start from previous values, and Y from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toXYZ 10 240 30 ]
      , expected = "translateX(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toX keeps owned Y and Z inline styles, starts X from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toY keeps owned Z inline style, starts Y from previous value, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toY 20 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toZ keeps owned Y inline style, starts Z from previous value, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toZ 30 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toXY keeps owned Z inline style, starts Y from previous value, and X from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toXY 120 20 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toXZ keeps owned Y inline style, starts Z from previous value, and X from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toXZ 120 30 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toYZ writes inline style where Y and Z start from previous values, and omits untouched X [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toYZ 20 30 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Translate.toYZ then Retarget.toXYZ writes inline style where Y and Z start from previous values, and X from default 0 [Reset called after retarget]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toXYZ 120 20 30 ]
      , expected = "translateY(0px) translateZ(0px)"
      }
    , { description = "Initialised Y with Translate.toX then Retarget.toX writes inline style where it carries Y from initialised value, starts X from previous value and omits untouched Z [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toX 10 ]
      , expected = "translateX(0px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Retarget.toX writes inline style where it carries Z from initialised value, starts X from previous value and omits untouched Y [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toX 10 ]
      , expected = "translateX(0px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Retarget.toY keeps owned X inline style, starts Y from initialised value, and omits untouched Z [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toY 20 ]
      , expected = "translateX(0px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Retarget.toY carries Z from initialised value, keeps owned X inline style, and starts Y from previous value [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateX(0px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Retarget.toZ carries Y from initialised value, keeps owned X inline style, and starts Z from default 0 [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateX(0px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Retarget.toZ keeps owned X inline style, and starts Z from initialised value, and omits untouched Y [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , retargetAxesFunctions = [ Translate.toZ 30 ]
      , expected = "translateX(0px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Retarget.toX keeps owned Y and Z inline styles, and starts X from previous value [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toX 10 ]
      , expected = "translate3d(0px, 240px, 0px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Retarget.toY keeps owned X and Z inline styles, and starts Y from previous value [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toY 20 ]
      , expected = "translate3d(0px, 240px, 0px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Retarget.toZ keeps owned X and Y inline styles, and starts Z from previous value [Reset called after retarget]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , retargetAxesFunctions = [ Translate.toZ 30 ]
      , expected = "translate3d(0px, 240px, 0px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Retarget.toX keeps owned Y and Z inline styles, and starts X from default 0 [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateY(0px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Retarget.toY keeps owned Z inline style, and starts Y from previous value [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toY 20 ]
      , expected = "translateY(0px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Retarget.toZ keeps owned Y inline style, and starts Z from previous value [Reset called after retarget]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , retargetAxesFunctions = [ Translate.toZ 30 ]
      , expected = "translateY(0px) translateZ(360px)"
      }
    ]
