module Specs.TransformOrderSpec.TestData exposing (..)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Properties.All exposing (InitFactory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.TransformOrderSpec.Runner exposing (TestCase(..), TestData)


testData : InitFactory (a -> a) -> TestData a
testData factory =
    { description = "transformOrder writes the correct inline styles"
    , testCases =
        [ InitTest
            { description = "when initialized writes the default transform order"
            , initFuncs =
                [ factory.translate.initX animGroup 0
                , factory.rotate.initX animGroup 0
                , factory.scale.initX animGroup 0
                , factory.skew.initX animGroup 0
                ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated without a specified transform order writes the default transform order"
            , animateFuncs =
                [ factory.translate.initX animGroup 0
                , factory.rotate.initX animGroup 0
                , factory.scale.initX animGroup 0
                , factory.skew.initX animGroup 0
                ]
            , transformOrder = [ Translate, Rotate, Skew, Scale ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        ]
    }
