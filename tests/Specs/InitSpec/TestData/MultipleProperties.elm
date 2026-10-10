module Specs.InitSpec.TestData.MultipleProperties exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Multi-Property tests"
    , testCases =
        List.map MultiPropertyTest
            [ { description = "Opacity.init and Translate.initX write opacity and translateX"
              , initFuncs =
                    [ Opacity.init animGroup 0.5
                    , Translate.initX animGroup 10
                    ]
              , expected =
                    [ NameValuePair "opacity" "0.5"
                    , NameValuePair "transform" "translateX(10px)"
                    ]
              , notExpected = [ "translateY", "translateZ" ]
              }
            , { description = "Translate.initX and Skew.initX write translateX and skewX"
              , initFuncs =
                    [ Translate.initX animGroup 10
                    , Skew.initX animGroup 5
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) skewX(5deg)" ]
              , notExpected = [ "translateY", "translateZ", "skewY" ]
              }
            , { description = "Translate.initX, Scale.initX and Skew.initX write translateX, scaleX and skewX"
              , initFuncs =
                    [ Translate.initX animGroup 10
                    , Scale.initX animGroup 2
                    , Skew.initX animGroup 5
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) skewX(5deg) scaleX(2)" ]
              , notExpected = [ "translateY", "translateZ", "scaleY", "scaleZ", "skewY" ]
              }
            , { description = "Translate.initX, Rotate.initX, Scale.initX and Skew.initX write translateX, rotateX, scaleX and skewX"
              , initFuncs =
                    [ Translate.initX animGroup 10
                    , Rotate.initX animGroup 15
                    , Scale.initX animGroup 2
                    , Skew.initX animGroup 0
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) rotateX(15deg) skewX(0deg) scaleX(2)" ]
              , notExpected = [ "translateY", "translateZ", "rotateY", "rotateZ", "scaleY", "scaleZ", "skewY" ]
              }
            ]
    }
