module Specs.DelaySpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Factories.Capabilities exposing (WithTiming)
import Motion.Easing exposing (Easing(..))
import Specs.DelaySpec.TestData as TD exposing (EngineCase, PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Opacity.delay tests"
    , testCases =
        TD.buildPropertyCases NoTiming propertyCases
            ++ TD.buildPropertyCases (DurationMs 100) propertyCases
            ++ TD.buildEngineCases NoTiming engineCases
            ++ TD.buildEngineCases (DurationMs 100) engineCases
    }


propertyCases : List (PropertyCase (AnimBuilder (WithTiming eng)))
propertyCases =
    [ { description = "a property delay with a duration is written correctly"
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
    , { description = "a property delay with no duration is written correctly"
      , propertyName = "opacity"
      , delayMs = 200
      , pipelineWithDelay =
            \d ->
                Opacity.begin
                    >> Opacity.to 0.8
                    >> Opacity.delay d
                    >> Opacity.end
      }
    ]


engineCases : List (EngineCase (AnimBuilder (WithTiming eng)))
engineCases =
    [ { description = "an engine delay with no duration is written correctly"
      , propertyName = "opacity"
      , delayMs = 300
      , propertyPipeline =
            Opacity.begin
                >> Opacity.to 0.8
                >> Opacity.end
      }
    , { description = "an engine delay with a duration is written correctly"
      , propertyName = "opacity"
      , delayMs = 400
      , propertyPipeline =
            Opacity.begin
                >> Opacity.to 0.8
                >> Opacity.duration 1000
                >> Opacity.end
      }
    ]
