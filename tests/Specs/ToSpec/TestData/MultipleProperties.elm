module Specs.ToSpec.TestData.MultipleProperties exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "multiple properties combine across timing profiles"
    , testCases =
        TD.buildMultiPropertyCases NoTiming propertyCases
            ++ TD.buildMultiPropertyCases (DelayMs 500) propertyCases
            ++ TD.buildMultiPropertyCases (DurationMs 500) propertyCases
    }


propertyCases : List (TD.MultiPropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "Opacity and Translate combine and write separate opacity + transform properties"
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
    , { description = "Translate, Size, Rotate, and Opacity combine and write transform"
      , propertyPipeline =
            [ Translate.begin
                >> Translate.toX 10
                >> Translate.end
            , Size.begin
                >> Size.toH 10
                >> Size.end
            , Rotate.begin
                >> Rotate.toX 15
                >> Rotate.end
            , Opacity.begin
                >> Opacity.to 0.5
                >> Opacity.end
            ]
      , expected =
            [ NameValuePair "transform" "translateX(10px) rotateX(15deg)"
            , NameValuePair "height" "10px"
            , NameValuePair "opacity" "0.5"
            ]
      , notExpected = [ "translateY", "translateZ", "rotateY", "rotateZ", "width" ]
      }
    ]
