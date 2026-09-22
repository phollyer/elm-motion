module Anim.Engine.Keyframe.Properties.Translate.AxisSpec.AnimateTests.InitAxesTests exposing (..)

import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Keyframe.Properties.Translate.AxisSpec.Helpers exposing (..)
import Anim.Property.Translate as Translate
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


initialisedAxesTests : Test
initialisedAxesTests =
    describe "initialised axes" <|
        List.map
            (\tc ->
                test tc.description <|
                    \_ ->
                        Keyframe.init [ tc.initAxis ]
                            |> (\state ->
                                    Html.div (Keyframe.attributes animGroup state) []
                                        |> Query.fromHtml
                                        |> Query.has [ Selector.style "transform" tc.expected ]
                               )
            )
            initialisedAxesTestData


type alias InitialisedAxesTestData =
    List
        { description : String
        , initAxis : KeyframeBuilderFunction
        , expected : String
        }


initialisedAxesTestData : InitialisedAxesTestData
initialisedAxesTestData =
    [ { description = "Initialised X writes X, and omits untouched YZ"
      , initAxis = Translate.initX animGroup 10
      , expected = "translateX(10px)"
      }
    , { description = "Initialised Y writes Y, and omits untouched XZ"
      , initAxis = Translate.initY animGroup 20
      , expected = "translateY(20px)"
      }
    , { description = "Initialised Z writes Z, and omits untouched XY"
      , initAxis = Translate.initZ animGroup 30
      , expected = "translateZ(30px)"
      }
    , { description = "Initialised XY writes XY and omits untouched Z"
      , initAxis = Translate.initXY animGroup 10 20
      , expected = "translateX(10px) translateY(20px)"
      }
    , { description = "Initialised XZ writes XZ and omits untouched Y"
      , initAxis = Translate.initXZ animGroup 10 30
      , expected = "translateX(10px) translateZ(30px)"
      }
    , { description = "Initialised YZ writes YZ and omits untouched X"
      , initAxis = Translate.initYZ animGroup 20 30
      , expected = "translateY(20px) translateZ(30px)"
      }
    , { description = "Initialised XYZ writes XYZ promoted to translate3d"
      , initAxis = Translate.initXYZ animGroup 10 20 30
      , expected = "translate3d(10px, 20px, 30px)"
      }
    ]
