module Specs.DelaySpec.TestData.Rotate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData as TD exposing (EngineCase, PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Rotate.delay tests"
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
                Rotate.begin
                    >> Rotate.toX 10
                    >> Rotate.duration 100
                    >> Rotate.delay d
                    >> Rotate.end
      }
    , { description = "a property delay with no duration is written correctly"
      , propertyName = "transform"
      , delayMs = 200
      , pipelineWithDelay =
            \d ->
                Rotate.begin
                    >> Rotate.toY 20
                    >> Rotate.delay d
                    >> Rotate.end
      }
    ]


engineCases : List (EngineCase (AnimBuilder (WithTiming eng)))
engineCases =
    [ { description = "an engine delay with no duration is written correctly"
      , propertyName = "transform"
      , delayMs = 300
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toZ 30
                >> Rotate.end
      }
    , { description = "an engine delay with a duration is written correctly"
      , propertyName = "transform"
      , delayMs = 400
      , propertyPipeline =
            Rotate.begin
                >> Rotate.toXY 10 20
                >> Rotate.duration 1000
                >> Rotate.end
      }
    ]
