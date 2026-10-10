module Specs.AnimateSpec.TestData.MultipleProperties exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Specs.AnimateSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Multi-Property tests"
    , testCases =
        List.map MultiPropertyTest
            [ { description = "Opacity and Translate combine and write opacity + transform and combined will-change"
              , propertyPipeline =
                    [ Opacity.begin
                        >> Opacity.to 0.5
                        >> Opacity.end
                    , Translate.begin
                        >> Translate.toX 10
                        >> Translate.end
                    ]
              , expected =
                    [ NameValuePair "opacity" "0.5"
                    , NameValuePair "transform" "translateX(10px)"
                    ]
              , notExpected = [ "translateY", "translateZ" ]
              }
            , { description = "Translate and Skew combine and write transform"
              , propertyPipeline =
                    [ Translate.begin
                        >> Translate.toX 10
                        >> Translate.end
                    , Skew.begin
                        >> Skew.toX 5
                        >> Skew.end
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) skewX(5deg)" ]
              , notExpected = [ "translateY", "translateZ", "skewY", "skewZ" ]
              }
            , { description = "Translate, Scale and Skew combine and write transform"
              , propertyPipeline =
                    [ Translate.begin
                        >> Translate.toX 10
                        >> Translate.end
                    , Scale.begin
                        >> Scale.toX 2
                        >> Scale.end
                    , Skew.begin
                        >> Skew.toX 5
                        >> Skew.end
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) skewX(5deg) scaleX(2)" ]
              , notExpected = [ "translateY", "translateZ", "skewY", "skewZ", "scaleY", "scaleZ" ]
              }
            , { description = "Translate, Rotate, Scale and Skew combine and write transform"
              , propertyPipeline =
                    [ Translate.begin
                        >> Translate.toX 10
                        >> Translate.end
                    , Rotate.begin
                        >> Rotate.toX 15
                        >> Rotate.end
                    , Scale.begin
                        >> Scale.toX 2
                        >> Scale.end
                    , Skew.begin
                        >> Skew.toX 0
                        >> Skew.end
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) rotateX(15deg) skewX(0deg) scaleX(2)" ]
              , notExpected = [ "translateY", "translateZ", "rotateY", "rotateZ", "skewY", "skewZ", "scaleY", "scaleZ" ]
              }
            ]
    }
