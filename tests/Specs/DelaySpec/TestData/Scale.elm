module Specs.DelaySpec.TestData.Scale exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData as TD exposing (EngineCase, PropertyCase, TestData)
import Specs.Shared exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Scale.delay tests"
    , testCases =
        TD.buildPropertyCases NoTiming propertyCases
            ++ TD.buildPropertyCases (DurationMs 100) propertyCases
            ++ TD.buildEngineCases NoTiming engineCases
            ++ TD.buildEngineCases (DurationMs 100) engineCases
    }


propertyCases : List (PropertyCase (AnimBuilder (WithTiming eng)))
propertyCases =
    [ { description = "a property delay with a duration is written correctly"
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
    , { description = "a property delay with no duration is written correctly"
      , propertyName = "transform"
      , delayMs = 200
      , pipelineWithDelay =
            \d ->
                Scale.begin
                    >> Scale.toY 20
                    >> Scale.delay d
                    >> Scale.end
      }
    ]


engineCases : List (EngineCase (AnimBuilder (WithTiming eng)))
engineCases =
    [ { description = "an engine delay with no duration is written correctly"
      , propertyName = "transform"
      , delayMs = 300
      , propertyPipeline =
            Scale.begin
                >> Scale.toZ 30
                >> Scale.end
      }
    , { description = "an engine delay with a duration is written correctly"
      , propertyName = "transform"
      , delayMs = 400
      , propertyPipeline =
            Scale.begin
                >> Scale.toXY 10 20
                >> Scale.duration 1000
                >> Scale.end
      }
    ]
