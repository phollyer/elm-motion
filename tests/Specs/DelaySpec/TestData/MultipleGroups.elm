module Specs.DelaySpec.TestData.MultipleGroups exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Helpers.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.DelaySpec.TestData as TD exposing (GroupPropertyTestCase, MultiGroupCase, TestCase(..), TestData, groupPropertyTestCase)
import Specs.Shared exposing (TimingProfile(..))


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "multiple groups for the same animation state keeps delays isolated across timing profiles"
    , testCases =
        TD.buildMultiGroupCases NoTiming multiGroupCases
            ++ TD.buildMultiGroupCases (DurationMs 500) multiGroupCases
    }


multiGroupCases : List (MultiGroupCase (AnimBuilder (WithTiming eng)))
multiGroupCases =
    [ { description = "delay stays scoped to each group when animating the same property"
      , groups =
            List.map
                (\( animGroupName, delayMs ) ->
                    nonTransformCase animGroupName delayMs
                )
                groups
      }
    , { description = "delay stays scoped to each group for transform animations"
      , groups =
            List.map
                (\( animGroupName, delayMs ) ->
                    transformCase animGroupName delayMs
                )
                groups
      }
    ]


groups : List ( String, Int )
groups =
    [ ( animGroup, 200 )
    , ( otherAnimGroup, 500 )
    ]


nonTransformCase : String -> Int -> GroupPropertyTestCase (AnimBuilder (WithTiming eng))
nonTransformCase animGroupName delayMs =
    groupPropertyTestCase
        { description = "non-transform delay is written correctly"
        , animGroup = animGroupName
        , propertyName = "opacity"
        , delayMs = delayMs
        , pipelineWithDelay =
            \d ->
                Opacity.begin
                    >> Opacity.to 0.5
                    >> Opacity.duration 300
                    >> Opacity.delay d
                    >> Opacity.end
        }


transformCase : String -> Int -> GroupPropertyTestCase (AnimBuilder (WithTiming eng))
transformCase animGroupName delayMs =
    groupPropertyTestCase
        { description = "transform delay is written correctly"
        , animGroup = animGroupName
        , propertyName = "transform"
        , delayMs = delayMs
        , pipelineWithDelay =
            \d ->
                Translate.begin
                    >> Translate.toX 20
                    >> Translate.duration 600
                    >> Translate.delay d
                    >> Translate.end
        }
