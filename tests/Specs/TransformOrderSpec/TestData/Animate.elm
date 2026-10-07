module Specs.TransformOrderSpec.TestData.Animate exposing (testData)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Properties.All exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.TransformOrderSpec.TestData exposing (TestCase(..), TestData)


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
            , animateFuncs = animateFuncs f
            , transformOrder = []
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated with only Translate declared, writes translate, rotate, skew, scale"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Translate ]
            , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated with only Rotate declared, writes rotate, translate, skew, scale"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Rotate ]
            , expected = "rotateX(0deg) translateX(0px) skewX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated with only Scale declared, writes scale, translate, rotate, skew"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Scale ]
            , expected = "scaleX(0) translateX(0px) rotateX(0deg) skewX(0deg)"
            }
        , AnimateTest
            { description = "when animated with only Skew declared, writes skew, translate, rotate, scale"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Skew ]
            , expected = "skewX(0deg) translateX(0px) rotateX(0deg) scaleX(0)"
            }
        , AnimateTest
            { description = "when animated with Translate, Scale declared, writes translate, scale, rotate, skew"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Translate, Scale ]
            , expected = "translateX(0px) scaleX(0) rotateX(0deg) skewX(0deg)"
            }
        , AnimateTest
            { description = "when animated with Scale, Rotate declared, writes scale, rotate, translate, skew"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Scale, Rotate ]
            , expected = "scaleX(0) rotateX(0deg) translateX(0px) skewX(0deg)"
            }
        , AnimateTest
            { description = "when animated with Scale, Skew, Rotate, Translate declared, writes scale, skew, rotate, translate"
            , animateFuncs = animateFuncs f
            , transformOrder = [ Scale, Skew, Rotate, Translate ]
            , expected = "scaleX(0) skewX(0deg) rotateX(0deg) translateX(0px)"
            }
        ]
    }


animateFuncs : Factory a b c d e f g h i j -> (a -> a)
animateFuncs f =
    f.translate.begin
        >> f.translate.toX 0
        >> f.translate.end
        >> f.rotate.begin
        >> f.rotate.toX 0
        >> f.rotate.end
        >> f.scale.begin
        >> f.scale.toX 0
        >> f.scale.end
        >> f.skew.begin
        >> f.skew.toX 0
        >> f.skew.end
