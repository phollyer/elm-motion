module Specs.DelaySpec.TestData.PerspectiveOrigin exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestCase(..), TestData, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "PerspectiveOrigin.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "perspective-origin"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    PerspectiveOrigin.begin
                        >> PerspectiveOrigin.toX 10
                        >> PerspectiveOrigin.duration 100
                        >> PerspectiveOrigin.delay d
                        >> PerspectiveOrigin.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "perspective-origin"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    PerspectiveOrigin.begin
                        >> PerspectiveOrigin.toY 20
                        >> PerspectiveOrigin.delay d
                        >> PerspectiveOrigin.end
            }
        , EngineTest
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "perspective-origin"
            , delayMs = 300
            , propertyPipeline =
                PerspectiveOrigin.begin
                    >> PerspectiveOrigin.toX 10
                    >> PerspectiveOrigin.end
            }
        , EngineTest
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "perspective-origin"
            , delayMs = 400
            , propertyPipeline =
                PerspectiveOrigin.begin
                    >> PerspectiveOrigin.toXY 10 20
                    >> PerspectiveOrigin.duration 1000
                    >> PerspectiveOrigin.end
            }
        ]
    }
