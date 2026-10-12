module Specs.DelaySpec.TestData.CustomColor exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Factories.Capabilities exposing (WithTiming)
import Motion.Easing exposing (Easing(..))
import Specs.DelaySpec.TestData exposing (TestCase(..), TestData, propertyCase)
import Specs.Shared.CustomColor as CustomColor


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "CustomColor.delay tests"
    , testCases =
        propertyCases
            ++ engineCases
    }


propertyCases : List (TestCase (AnimBuilder (WithTiming eng)))
propertyCases =
    List.map
        (\( colorProperty, propertyName, colorValue ) ->
            propertyCase
                { description = "a " ++ propertyName ++ " with a delay with no duration is written correctly"
                , propertyName = propertyName
                , delayMs = 500
                , pipelineWithDelay =
                    \d ->
                        case Color.fromString colorValue of
                            Just color ->
                                CustomColor.begin colorProperty
                                    >> CustomColor.to color
                                    >> CustomColor.delay d
                                    >> CustomColor.end

                            Nothing ->
                                identity
                }
        )
        CustomColor.all


engineCases : List (TestCase (AnimBuilder (WithTiming eng)))
engineCases =
    List.map
        (\( colorProperty, propertyName, colorValue ) ->
            EngineTest
                { description = "a " ++ propertyName ++ " with an engine delay with no duration is written correctly"
                , propertyName = propertyName
                , delayMs = 300
                , propertyPipeline =
                    CustomColor.begin colorProperty
                        >> CustomColor.to (Color.fromString colorValue |> Maybe.withDefault (Color.rgba 0 0 0 0))
                        >> CustomColor.end
                }
        )
        CustomColor.all
