module Specs.DelaySpec.TestData.CustomProperty exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as CustomProperty exposing (Property(..))
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestData, engineCase, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Custom.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "border-radius"
            , delayMs = 100
            , pipelineWithDelay =
                \d ->
                    CustomProperty.begin (BorderRadius Em)
                        >> CustomProperty.to 20
                        >> CustomProperty.duration 100
                        >> CustomProperty.delay d
                        >> CustomProperty.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "line-height"
            , delayMs = 200
            , pipelineWithDelay =
                \d ->
                    CustomProperty.begin (LineHeight Unitless)
                        >> CustomProperty.to 1.2
                        >> CustomProperty.delay d
                        >> CustomProperty.end
            }
        , engineCase
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "border-width"
            , delayMs = 300
            , propertyPipeline =
                CustomProperty.begin (BorderWidth Px)
                    >> CustomProperty.to 2
                    >> CustomProperty.end
            }
        , engineCase
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "my-custom-property"
            , delayMs = 400
            , propertyPipeline =
                CustomProperty.begin (Custom "my-custom-property" "unit")
                    >> CustomProperty.to 10
                    >> CustomProperty.duration 1000
                    >> CustomProperty.end
            }
        ]
    }
