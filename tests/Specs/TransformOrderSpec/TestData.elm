module Specs.TransformOrderSpec.TestData exposing (..)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Properties.All exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.TransformOrderSpec.Runner exposing (TestCase(..), TestData)


testData : Factory a b c d e f g h i j -> TestData a
testData f =
    { description = "transformOrder writes the correct inline styles"
    , testCases =
        [ InitTest
            { description = "when initialized writes the default transform order"
            , initFuncs =
                [ f.translate.initX animGroup 0
                , f.rotate.initX animGroup 0
                , f.scale.initX animGroup 0
                , f.skew.initX animGroup 0
                ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated without a specified transform order writes the default transform order"
            , animateFuncs =
                [ f.translate.begin
                    >> f.translate.toX 0
                    >> f.translate.end
                , f.rotate.initX animGroup 0
                , f.scale.initX animGroup 0
                , f.skew.initX animGroup 0
                ]
            , transformOrder = [ Translate, Rotate, Skew, Scale ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        ]
    }
