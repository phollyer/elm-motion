module Specs.TransformOrderSpec.TestData exposing (..)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Properties.All exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.TransformOrderSpec.Runner exposing (TestCase(..), TestData)


testData : Factory (a -> a) (b -> b) (c -> c) (d -> d) -> TestData a
testData factory =
    { description = "transformOrder writes the correct inline styles"
    , testCases =
        [ InitTest
            { description = "when initialized writes the default transform order"
            , initFuncs =
                [ factory.translate.init.initX animGroup 0
                , factory.rotate.init.initX animGroup 0
                , factory.scale.init.initX animGroup 0
                , factory.skew.init.initX animGroup 0
                ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated without a specified transform order writes the default transform order"
            , animateFuncs =
                [ factory.translate.init.initX animGroup 0
                , factory.rotate.init.initX animGroup 0
                , factory.scale.init.initX animGroup 0
                , factory.skew.init.initX animGroup 0
                ]
            , transformOrder = [ Translate, Rotate, Skew, Scale ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        ]
    }
