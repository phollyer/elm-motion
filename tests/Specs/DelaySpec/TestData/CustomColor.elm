module Specs.DelaySpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Factories.Capabilities exposing (WithTiming)
import Motion.Easing exposing (Easing(..))
import Specs.DelaySpec.TestData exposing (TestData, engineCase, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "CustomColor.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "background-color"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    CustomColor.begin BackgroundColor
                        >> CustomColor.to (Color.rgba 0 0 0 0)
                        >> CustomColor.duration 100
                        >> CustomColor.delay d
                        >> CustomColor.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "color"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    CustomColor.begin TextColor
                        >> CustomColor.to (Color.rgba 0 0 0 0.8)
                        >> CustomColor.delay d
                        >> CustomColor.end
            }
        , engineCase
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "border-color"
            , delayMs = 300
            , propertyPipeline =
                CustomColor.begin BorderColor
                    >> CustomColor.to (Color.rgba 0 0 0 0)
                    >> CustomColor.end
            }
        , engineCase
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "accent-color"
            , delayMs = 400
            , propertyPipeline =
                CustomColor.begin AccentColor
                    >> CustomColor.to (Color.rgba 0 0 0 0.8)
                    >> CustomColor.duration 1000
                    >> CustomColor.end
            }
        ]
    }
