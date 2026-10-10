module Specs.DelaySpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Factories.Capabilities exposing (WithTiming)
import Motion.Easing exposing (Easing(..))
import Specs.DelaySpec.TestData exposing (TestCase(..), TestData, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Opacity.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "opacity"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    Opacity.begin
                        >> Opacity.to 0.8
                        >> Opacity.duration 100
                        >> Opacity.delay d
                        >> Opacity.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "opacity"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    Opacity.begin
                        >> Opacity.to 0.8
                        >> Opacity.delay d
                        >> Opacity.end
            }
        , EngineTest
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "opacity"
            , delayMs = 300
            , propertyPipeline =
                Opacity.begin
                    >> Opacity.to 0.8
                    >> Opacity.end
            }
        , EngineTest
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "opacity"
            , delayMs = 400
            , propertyPipeline =
                Opacity.begin
                    >> Opacity.to 0.8
                    >> Opacity.duration 1000
                    >> Opacity.end
            }
        ]
    }
