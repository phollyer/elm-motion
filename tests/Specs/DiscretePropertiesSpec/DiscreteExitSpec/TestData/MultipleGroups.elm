module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.MultipleGroups exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.AnimGroups exposing (animGroup, otherAnimGroup)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "multiple groups output with discreteExit"
    , testCases =
        [ MultiGroupTest
            { description = "Translate output stays isolated per group while discreteExit is configured per group"
            , animGroups = [ animGroup, otherAnimGroup ]
            , initFuncs =
                [ \_ -> Translate.initX animGroup 0
                , \_ -> Translate.initZ otherAnimGroup 0
                ]
            , propertyPipelines =
                [ [ \fns ->
                        fns.discreteExit "display" "block" "none"
                            >> Translate.begin
                            >> Translate.toX 10
                            >> Translate.duration 500
                            >> Translate.end
                  ]
                , [ \fns ->
                        fns.discreteExit "display" "block" "none"
                            >> Translate.begin
                            >> Translate.toZ 10
                            >> Translate.duration 500
                            >> Translate.end
                  ]
                ]
            , expected =
                [ [ NameValuePair "transform" "translateX(10px)" ]
                , [ NameValuePair "transform" "translateZ(10px)" ]
                ]
            , notExpected =
                [ [ "translateY", "translateZ" ]
                , [ "translateX", "translateY" ]
                ]
            }
        , MultiGroupTest
            { description = "Size output stays isolated per group while discreteExit is configured per group"
            , animGroups = [ animGroup, otherAnimGroup ]
            , initFuncs =
                [ \_ -> Size.initH animGroup 0
                , \_ -> Size.initW otherAnimGroup 0
                ]
            , propertyPipelines =
                [ [ \fns ->
                        fns.discreteExit "display" "block" "none"
                            >> Size.begin
                            >> Size.toH 10
                            >> Size.duration 500
                            >> Size.end
                  ]
                , [ \fns ->
                        fns.discreteExit "display" "block" "none"
                            >> Size.begin
                            >> Size.toW 10
                            >> Size.duration 500
                            >> Size.end
                  ]
                ]
            , expected =
                [ [ NameValuePair "height" "10px" ]
                , [ NameValuePair "width" "10px" ]
                ]
            , notExpected =
                [ [ "width" ]
                , [ "height" ]
                ]
            }
        ]
    }
