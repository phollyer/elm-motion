module Specs.DelaySpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData as TD exposing (EngineCase, PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Translate.delay tests"
    , testCases =
        TD.buildPropertyCases NoTiming propertyCases
            ++ TD.buildPropertyCases (DurationMs 500) propertyCases
            ++ TD.buildEngineCases NoTiming engineCases
            ++ TD.buildEngineCases (DurationMs 500) engineCases
    }


propertyCases : List (PropertyCase (AnimBuilder (WithTiming eng)))
propertyCases =
    [ { description = "a property delay with no duration is written correctly"
      , propertyName = "transform"
      , delayMs = 200
      , pipelineWithDelay =
            \d ->
                Translate.begin
                    >> Translate.toX 10
                    >> Translate.delay d
                    >> Translate.end
      }
    ]


engineCases : List (EngineCase (AnimBuilder (WithTiming eng)))
engineCases =
    [ { description = "an engine delay with no duration is written correctly"
      , propertyName = "transform"
      , delayMs = 300
      , propertyPipeline =
            Translate.begin
                >> Translate.toX 10
                >> Translate.end
      }
    ]
