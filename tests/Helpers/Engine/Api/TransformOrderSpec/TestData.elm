module Helpers.Engine.Api.TransformOrderSpec.TestData exposing (..)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Engines.TransformOrder exposing (TransformOrderFactory)
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.TransformOrderSpec.Runner exposing (TestCase(..), TestData)


transformOrderTestData : TransformOrderFactory (a -> a) -> TestData (a -> a)
transformOrderTestData factory =
    { description = "transformOrder writes the correct inline styles"
    , testCases =
        List.map GeneralTest
            [ { description = "an empty list produces the default transform order"
              , initFuncs =
                    [ factory.translate.initX animGroup 0
                    , factory.rotate.initX animGroup 0
                    , factory.scale.initX animGroup 0
                    , factory.skew.initX animGroup 5
                    ]
              , transformOrderFunc = factory.transformOrder []
              , expected = "translateX(0px) rotateX(0deg) skewX(5deg) scaleX(0)"
              }
            ]
    }
