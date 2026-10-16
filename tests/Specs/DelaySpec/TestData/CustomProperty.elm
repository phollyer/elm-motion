module Specs.DelaySpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as CustomProperty exposing (Property(..))
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData as TD exposing (EngineCase, PropertyCase, TestCase(..), TestData)
import Specs.Shared.CustomProperty as Custom
import Specs.Shared.TimingProfile exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Custom.delay tests"
    , testCases =
        TD.buildPropertyCases NoTiming propertyCases
            ++ TD.buildPropertyCases (DurationMs 500) propertyCases
            ++ TD.buildEngineCases NoTiming engineCases
            ++ TD.buildEngineCases (DurationMs 500) engineCases
    }


propertyCases : List (PropertyCase (AnimBuilder (WithTiming eng)))
propertyCases =
    List.map
        (\( ( property, value ), ( propertyName, _ ) ) ->
            { description = "a " ++ propertyName ++ " property with a delay and a duration is written correctly"
            , propertyName = propertyName
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    CustomProperty.begin property
                        >> CustomProperty.to value
                        >> CustomProperty.delay d
                        >> CustomProperty.end
            }
        )
        Custom.all


engineCases : List (EngineCase (AnimBuilder (WithTiming eng)))
engineCases =
    List.map
        (\( ( property, value ), ( propertyName, _ ) ) ->
            { description = "a " ++ propertyName ++ " with an engine delay with no duration is written correctly"
            , propertyName = propertyName
            , delayMs = 300
            , propertyPipeline =
                CustomProperty.begin property
                    >> CustomProperty.to value
                    >> CustomProperty.end
            }
        )
        Custom.all
