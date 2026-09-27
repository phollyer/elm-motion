module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.RestartTests exposing (suite)

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
    describe "Restart: untouched axes do not get written, initialized axes are respected, and subsequent updates behave correctly," <|
        [ tests ]


tests : Test
tests =
    describe "when restart snaps to start state and writes inline transform" <|
        List.map
            (\testCase ->
                test testCase.description <|
                    \_ ->
                        Keyframe.init testCase.initValues
                            |> KH.animateMultipleWithDuration 500 testCase.firstAnimationAxesFunctions
                            |> Keyframe.restart animGroup identity
                            |> Tuple.first
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

   Restart Tests

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
    [ { description = "Translate.toX then Restart writes inline style, from default 0 to end value and omits untouched YZ"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toY then Restart writes inline style, from default 0 to end value and omits untouched XZ"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toZ then Restart writes inline style, from default 0 to end value and omits untouched XY"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toXY then Restart writes inline style, from default 0 0 to end values and omits Z"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXZ then Restart writes inline style, from default 0 0 to end values and omits Y"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart writes inline style, from default 0 0 to end values and omits X"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toXYZ then Restart writes inline style, from default 0 0 0 to end values and includes all axes"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised X with Translate.toX then Restart writes inline style and omits untouched YZ"
      , initValues = [ Translate.initX animGroup 10 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Initialised Y with Translate.toY then Restart writes inline style and omits untouched XZ"
      , initValues = [ Translate.initY animGroup 20 ]
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toZ then Restart writes inline style and omits untouched XY"
      , initValues = [ Translate.initZ animGroup 30 ]
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Initialised XY with Translate.toXY then Restart writes inline style and omits untouched Z"
      , initValues = [ Translate.initXY animGroup 10 20 ]
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised XZ with Translate.toXZ then Restart writes inline style and omits untouched Y"
      , initValues = [ Translate.initXZ animGroup 10 30 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised YZ with Translate.toYZ then Restart writes inline style and omits untouched X"
      , initValues = [ Translate.initYZ animGroup 20 30 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised XYZ with Translate.toXYZ then Restart writes inline style and includes all axes"
      , initValues = [ Translate.initXYZ animGroup 10 20 30 ]
      , firstAnimationAxesFunctions = [ Translate.toXYZ 120 240 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Translate.toX then Restart.toX writes inline style where X starts from previous value and omits untouched YZ [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Restart.toY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Restart.toZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Restart.toXY keeps owned X inline style, starts Y from default 0, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Restart.toXZ keeps owned X inline style, starts Z from default 0, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Restart.toYZ keeps owned X inline style, starts Y and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toX then Restart.toXYZ keeps owned X inline style, starts Y and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px)"
      }
    , { description = "Translate.toY then Restart.toX keeps owned Y inline style, starts X from default 0, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Restart.toY writes inline style where Y starts from previous value, and omits untouched XZ [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Restart.toZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Restart.toXY keeps owned Y inline style, starts X from default 0, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Restart.toXZ keeps owned Y inline style, starts X and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Restart.toYZ keeps owned Y inline style, starts Z from default 0, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toY then Restart.toXYZ keeps owned Y inline style, starts X and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toY 240 ]
      , expected = "translateY(240px)"
      }
    , { description = "Translate.toZ then Restart.toX keeps owned Z inline style, starts X from default 0, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Restart.toY keeps owned Z inline style, starts Y from default 0, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Restart.toZ writes inline style where Z starts from previous value, and omits untouched XY [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Restart.toXY keeps owned Z inline style, starts X and Y from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Restart.toXZ keeps owned Z inline style, starts X from default 0, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Restart.toYZ keeps owned Z inline style, starts Y from default 0, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toZ then Restart.toXYZ keeps owned Z inline style, starts X and Y from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toZ 360 ]
      , expected = "translateZ(360px)"
      }
    , { description = "Translate.toXY then Restart.toX keeps owned Y inline style, starts X from previous value, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Restart.toY keeps owned X inline style, starts Y from previous value, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Restart.toZ keeps owned XY inline styles, starts Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Restart.toXY writes inline style where X and Y start from previous values, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Restart.toXZ keeps owned Y inline style, starts X from previous value, and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Restart.toYZ keeps owned X inline style, starts Y from previous value, and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXY then Restart.toXYZ writes inline style where X and Y start from previous values, and Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXY 120 240 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Translate.toXZ then Restart.toX keeps owned Z inline style, starts X from previous value, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Restart.toY keeps owned X and Z inline styles, starts Y from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Restart.toZ keeps owned X inline style, starts Z from previous value, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Restart.toXY keeps owned Z inline style, starts X from previous value, and Y from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Restart.toXZ writes inline style where X and Z start from previous values, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Restart.toYZ keeps owned X inline style, starts Y from default 0, and Z from previous value [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toXZ then Restart.toXYZ writes inline style where X and Z start from previous values, and Y from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toX keeps owned Y and Z inline styles, starts X from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toY keeps owned Z inline style, starts Y from previous value, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toZ keeps owned Y inline style, starts Z from previous value, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toXY keeps owned Z inline style, starts Y from previous value, and X from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toXZ keeps owned Y inline style, starts Z from previous value, and X from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toYZ writes inline style where Y and Z start from previous values, and omits untouched X [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Translate.toYZ then Restart.toXYZ writes inline style where Y and Z start from previous values, and X from default 0 [Restart regenerates animation and renders end style]"
      , initValues = []
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Restart.toX writes inline style where it carries Y from initialised value, starts X from previous value and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Restart.toX writes inline style where it carries Z from initialised value, starts X from previous value and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Restart.toY keeps owned X inline style, starts Y from initialised value, and omits untouched Z [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Restart.toY carries Z from initialised value, keeps owned X inline style, and starts Y from previous value [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toX then Restart.toZ carries Y from initialised value, keeps owned X inline style, and starts Z from default 0 [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateY(240px)"
      }
    , { description = "Initialised Z with Translate.toX then Restart.toZ keeps owned X inline style, and starts Z from initialised value, and omits untouched Y [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toX 120 ]
      , expected = "translateX(120px) translateZ(360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Restart.toX keeps owned Y and Z inline styles, and starts X from previous value [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Restart.toY keeps owned X and Z inline styles, and starts Y from previous value [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised Y with Translate.toXZ then Restart.toZ keeps owned X and Y inline styles, and starts Z from previous value [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initY animGroup 240 ]
      , firstAnimationAxesFunctions = [ Translate.toXZ 120 360 ]
      , expected = "translate3d(120px, 240px, 360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Restart.toX keeps owned Y and Z inline styles, and starts X from default 0 [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Restart.toY keeps owned Z inline style, and starts Y from previous value [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    , { description = "Initialised Z with Translate.toYZ then Restart.toZ keeps owned Y inline style, and starts Z from previous value [Restart regenerates animation and renders end style]"
      , initValues = [ Translate.initZ animGroup 360 ]
      , firstAnimationAxesFunctions = [ Translate.toYZ 240 360 ]
      , expected = "translateY(240px) translateZ(360px)"
      }
    ]
