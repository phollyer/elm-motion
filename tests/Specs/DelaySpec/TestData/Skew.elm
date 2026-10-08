module Specs.DelaySpec.TestData.Skew exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Skew as Skew
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestData, engineCase, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Skew.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    Skew.begin
                        >> Skew.toX 10
                        >> Skew.duration 100
                        >> Skew.delay d
                        >> Skew.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    Skew.begin
                        >> Skew.toY 20
                        >> Skew.delay d
                        >> Skew.end
            }
        , engineCase
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 300
            , propertyPipeline =
                Skew.begin
                    >> Skew.toX 10
                    >> Skew.end
            }
        , engineCase
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 400
            , propertyPipeline =
                Skew.begin
                    >> Skew.toXY 10 20
                    >> Skew.duration 1000
                    >> Skew.end
            }
        ]
    }
