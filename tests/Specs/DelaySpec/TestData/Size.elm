module Specs.DelaySpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestCase(..), TestData, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Size.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "height"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    Size.begin
                        >> Size.toH 120
                        >> Size.duration 100
                        >> Size.delay d
                        >> Size.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "width"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    Size.begin
                        >> Size.toW 200
                        >> Size.delay d
                        >> Size.end
            }
        , EngineTest
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "width"
            , delayMs = 300
            , propertyPipeline =
                Size.begin
                    >> Size.toW 200
                    >> Size.end
            }
        , EngineTest
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "height"
            , delayMs = 400
            , propertyPipeline =
                Size.begin
                    >> Size.toH 120
                    >> Size.duration 1000
                    >> Size.end
            }
        ]
    }
