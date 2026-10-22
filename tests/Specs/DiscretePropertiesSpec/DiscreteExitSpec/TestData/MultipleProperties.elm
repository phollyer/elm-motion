module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.MultipleProperties exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "multiple properties output with discreteExit"
    , testCases =
        [ MultiPropertyTest
            { description = "Opacity and Translate still write styles while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs =
                [ \_ ->
                    Opacity.init animGroup 1
                        >> Translate.initX animGroup 0
                ]
            , propertyPipelines =
                [ \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Opacity.begin
                        >> Opacity.to 0.5
                        >> Opacity.duration 500
                        >> Opacity.end
                , \_ ->
                    Translate.begin
                        >> Translate.toX 10
                        >> Translate.duration 500
                        >> Translate.end
                ]
            , expected =
                [ NameValuePair "opacity" "0.5"
                , NameValuePair "transform" "translateX(10px)"
                ]
            , notExpected = [ "translateY", "translateZ" ]
            }
        , MultiPropertyTest
            { description = "Translate, Rotate, Skew and Scale still compose transform while discreteExit is configured"
            , animGroup = animGroup
            , initFuncs =
                [ \_ ->
                    Translate.initX animGroup 0
                        >> Rotate.initX animGroup 0
                        >> Skew.initX animGroup 0
                        >> Scale.initX animGroup 1
                ]
            , propertyPipelines =
                [ \fns ->
                    fns.discreteExit "display" "block" "none"
                        >> Translate.begin
                        >> Translate.toX 10
                        >> Translate.duration 500
                        >> Translate.end
                , \_ ->
                    Rotate.begin
                        >> Rotate.toX 15
                        >> Rotate.duration 500
                        >> Rotate.end
                , \_ ->
                    Skew.begin
                        >> Skew.toX 5
                        >> Skew.duration 500
                        >> Skew.end
                , \_ ->
                    Scale.begin
                        >> Scale.toX 2
                        >> Scale.duration 500
                        >> Scale.end
                ]
            , expected =
                [ NameValuePair "transform" "translateX(10px) rotateX(15deg) skewX(5deg) scaleX(2)" ]
            , notExpected = [ "translateY", "translateZ", "rotateY", "rotateZ", "skewY", "scaleY", "scaleZ" ]
            }
        ]
    }
