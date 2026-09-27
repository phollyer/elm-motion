module Helpers.Engine.Api.TransformOrderSpec.TestData exposing (..)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Engines.TransformOrder exposing (TransformOrderFactory)
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.TransformOrderSpec.Runner exposing (TestCase(..), TestData)


transformOrderTestData : TransformOrderFactory (a -> a) (b -> b) (c -> c) (d -> d) -> TestData a
transformOrderTestData factory =
    { description = "transformOrder writes the correct inline styles"
    , testCases =
        [ InitTest
            { description = "when initialized writes the default transform order"
            , initFuncs =
                [ factory.translate.init.initX animGroup 0
                , factory.rotate.init.initX animGroup 0
                , factory.scale.init.initX animGroup 0
                , factory.skew.initX animGroup 0
                ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated writes the default transform order"
            , animateFuncs =
                [ factory.translate.init.initX animGroup 0
                , factory.rotate.init.initX animGroup 0
                , factory.scale.init.initX animGroup 0
                , factory.skew.initX animGroup 0
                ]
            , transformOrderFunc = identity --factory.transformOrder [ Translate, Rotate, Skew, Scale ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        ]
    }
