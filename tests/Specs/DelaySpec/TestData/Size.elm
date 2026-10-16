module Specs.DelaySpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData as TD exposing (EngineCase, PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Size.delay tests"
    , testCases =
        TD.buildPropertyCases NoTiming propertyCases
            ++ TD.buildPropertyCases (DurationMs 100) propertyCases
            ++ TD.buildEngineCases NoTiming engineCases
            ++ TD.buildEngineCases (DurationMs 100) engineCases
    }


propertyCases : List (PropertyCase (AnimBuilder (WithTiming eng)))
propertyCases =
    [ { description = "a property delay with a duration is written correctly"
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
    , { description = "a property delay with no duration is written correctly"
      , propertyName = "width"
      , delayMs = 200
      , pipelineWithDelay =
            \d ->
                Size.begin
                    >> Size.toW 200
                    >> Size.delay d
                    >> Size.end
      }
    ]


engineCases : List (EngineCase (AnimBuilder (WithTiming eng)))
engineCases =
    [ { description = "an engine delay with no duration is written correctly"
      , propertyName = "width"
      , delayMs = 300
      , propertyPipeline =
            Size.begin
                >> Size.toW 200
                >> Size.end
      }
    , { description = "an engine delay with a duration is written correctly"
      , propertyName = "height"
      , delayMs = 400
      , propertyPipeline =
            Size.begin
                >> Size.toH 120
                >> Size.duration 1000
                >> Size.end
      }
    ]
