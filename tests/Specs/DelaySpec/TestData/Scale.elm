module Specs.DelaySpec.TestData.Scale exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestData, engineCase, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Scale.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    Scale.begin
                        >> Scale.toX 10
                        >> Scale.duration 100
                        >> Scale.delay d
                        >> Scale.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    Scale.begin
                        >> Scale.toY 20
                        >> Scale.delay d
                        >> Scale.end
            }
        , engineCase
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 300
            , propertyPipeline =
                Scale.begin
                    >> Scale.toZ 30
                    >> Scale.end
            }
        , engineCase
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 400
            , propertyPipeline =
                Scale.begin
                    >> Scale.toXY 10 20
                    >> Scale.duration 1000
                    >> Scale.end
            }
        ]
    }
