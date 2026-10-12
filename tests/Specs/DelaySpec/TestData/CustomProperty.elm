module Specs.DelaySpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as CustomProperty exposing (Property(..))
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestCase(..), TestData, propertyCase)
import Specs.Shared.CustomProperty as Custom


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Custom.delay tests"
    , testCases =
        buildPropertyCases
            ++ engineCases
    }


buildPropertyCases : List (TestCase (AnimBuilder (WithTiming eng)))
buildPropertyCases =
    List.map
        (\( ( property, value ), ( propertyName, _ ) ) ->
            propertyCase
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


engineCases : List (TestCase (AnimBuilder (WithTiming eng)))
engineCases =
    List.map
        (\( ( property, value ), ( propertyName, _ ) ) ->
            EngineTest
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
