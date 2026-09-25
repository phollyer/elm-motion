module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.StopTests exposing (suite)

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
    describe "Stop: untouched axes do not get written, initialized axes are respected, and subsequent updates behave correctly," <|
        [ tests ]


tests : Test
tests =
    describe "when stop snaps to end state and writes inline transform" <|
        List.map
            (\testCase ->
                test testCase.description <|
                    \_ ->
                        Keyframe.init testCase.initValues
                            |> KH.animateMultipleWithDuration 500 testCase.firstAnimationAxesFunctions
                            |> Keyframe.stop animGroup
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" testCase.expected ]
                               )
            )
            testData


type alias KeyframeBuilderFunction =
    KH.KeyframeBuilderFunction


type alias KeyframeAxisFunction =
    KH.KeyframeAxisFunction



{-
   ==========================================================

   Stop Tests

   ==========================================================
-}


type alias TestData =
    { description : String
    , initValues : List KeyframeBuilderFunction
    , firstAnimationAxesFunctions : List KeyframeAxisFunction
    , expected : String
    }


testData : List TestData
testData =
    uninitializedSingleStopTestData
        ++ initializedSingleStopTestData
        ++ uninitialisedTwoStepStopTestData
        ++ initialisedTwoStepStopTestData


uninitializedSingleStopTestData : List TestData
uninitializedSingleStopTestData =
    [ { description = "Translate.toX then Stop writes inline style, from default 0 to end value and omits untouched YZ"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toY then Stop writes inline style, from default 0 to end value and omits untouched XZ"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toZ then Stop writes inline style, from default 0 to end value and omits untouched XY"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toXY then Stop writes inline style, from default 0 0 to end values and omits Z"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXZ then Stop writes inline style, from default 0 0 to end values and omits Y"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop writes inline style, from default 0 0 to end values and omits X"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toXYZ then Stop writes inline style, from default 0 0 0 to end values and includes all axes"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]


initializedSingleStopTestData : List TestData
initializedSingleStopTestData =
    [ { description = "Initialised X with Translate.toX then Stop writes inline style and omits untouched YZ"
      , initValues = [ Translate.initX animGroup 10 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Initialised Y with Translate.toY then Stop writes inline style and omits untouched XZ"
      , initValues = [ Translate.initY animGroup 20 ]
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toZ then Stop writes inline style and omits untouched XY"
      , initValues = [ Translate.initZ animGroup 30 ]
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Initialised XY with Translate.toXY then Stop writes inline style and omits untouched Z"
      , initValues = [ Translate.initXY animGroup 10 20 ]
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised XZ with Translate.toXZ then Stop writes inline style and omits untouched Y"
      , initValues = [ Translate.initXZ animGroup 10 30 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised YZ with Translate.toYZ then Stop writes inline style and omits untouched X"
      , initValues = [ Translate.initYZ animGroup 20 30 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised XYZ with Translate.toXYZ then Stop writes inline style and includes all axes"
      , initValues = [ Translate.initXYZ animGroup 10 20 30 ]
      , firstAnimationAxesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    ]


uninitialisedTwoStepStopTestData : List TestData
uninitialisedTwoStepStopTestData =
    [ { description = "Translate.toX then Stop.toX writes inline style where X starts from previous value and omits untouched YZ [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Stop.toY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Stop.toZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Stop.toXY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Stop.toXZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Stop.toYZ keeps owned X inline style, starts Y and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Stop.toXYZ keeps owned X inline style, starts Y and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toY then Stop.toX keeps owned Y inline style, starts X from default 0, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Stop.toY writes inline style where Y starts from previous value, and omits untouched XZ [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Stop.toZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Stop.toXY keeps owned Y inline style, starts X from default 0, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Stop.toXZ keeps owned Y inline style, starts X and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Stop.toYZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Stop.toXYZ keeps owned Y inline style, starts X and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toZ then Stop.toX keeps owned Z inline style, starts X from default 0, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Stop.toY keeps owned Z inline style, starts Y from default 0, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Stop.toZ writes inline style where Z starts from previous value, and omits untouched XY [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Stop.toXY keeps owned Z inline style, starts X and Y from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Stop.toXZ keeps owned Z inline style, starts X from default 0, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Stop.toYZ keeps owned Z inline style, starts Y from default 0, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Stop.toXYZ keeps owned Z inline style, starts X and Y from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toXY then Stop.toX keeps owned Y inline style, starts X from previous value, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Stop.toY keeps owned X inline style, starts Y from previous value, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Stop.toZ keeps owned XY inline styles, starts Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Stop.toXY writes inline style where X and Y start from previous values, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Stop.toXZ keeps owned Y inline style, starts X from previous value, and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Stop.toYZ keeps owned X inline style, starts Y from previous value, and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Stop.toXYZ writes inline style where X and Y start from previous values, and Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXZ then Stop.toX keeps owned Z inline style, starts X from previous value, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Stop.toY keeps owned X and Z inline styles, starts Y from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Stop.toZ keeps owned X inline style, starts Z from previous value, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Stop.toXY keeps owned Z inline style, starts X from previous value, and Y from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Stop.toXZ writes inline style where X and Z start from previous values, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Stop.toYZ keeps owned X inline style, starts Y from default 0, and Z from previous value [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Stop.toXYZ writes inline style where X and Z start from previous values, and Y from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toX keeps owned Y and Z inline styles, starts X from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toY keeps owned Z inline style, starts Y from previous value, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toZ keeps owned Y inline style, starts Z from previous value, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toXY keeps owned Z inline style, starts Y from previous value, and X from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toXZ keeps owned Y inline style, starts Z from previous value, and X from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toYZ writes inline style where Y and Z start from previous values, and omits untouched X [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Stop.toXYZ writes inline style where Y and Z start from previous values, and X from default 0 [Stop snaps to first sequence end state]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    ]


initialisedTwoStepStopTestData : List TestData
initialisedTwoStepStopTestData =
    [ { description = "Initialised Y with Translate.toX then Stop.toX writes inline style where it carries Y from initialised value, starts X from previous value and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Stop.toX writes inline style where it carries Z from initialised value, starts X from previous value and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Stop.toY keeps owned X inline style, starts Y from initialised value, and omits untouched Z [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Stop.toY carries Z from initialised value, keeps owned X inline style, and starts Y from previous value [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Stop.toZ carries Y from initialised value, keeps owned X inline style, and starts Z from default 0 [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Stop.toZ keeps owned X inline style, and starts Z from initialised value, and omits untouched Y [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Stop.toX keeps owned Y and Z inline styles, and starts X from previous value [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Stop.toY keeps owned X and Z inline styles, and starts Y from previous value [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Stop.toZ keeps owned X and Y inline styles, and starts Z from previous value [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Stop.toX keeps owned Y and Z inline styles, and starts X from default 0 [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Stop.toY keeps owned Z inline style, and starts Y from previous value [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Stop.toZ keeps owned Y inline style, and starts Z from previous value [Stop snaps to first sequence end state]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    ]
