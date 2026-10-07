module Specs.TransformOrderSpec.TestData.Init exposing (..)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Properties.All exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.TransformOrderSpec.TestData exposing (TestCase(..), TestData)


testData : Factory a b c d e f g h i j -> TestData a
testData f =
    { description = "when initialized, transformOrder writes the correct inline styles"
    , testCases =
        List.map InitTest
            [ { description = "when initialized without a transform order, writes the default transform order"
              , initFuncs = initFuncs f
              , transformOrder = []
              , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
              }
            , { description = "when initialized with Rotate only writes rotate, translate, skew, scale"
              , initFuncs = initFuncs f
              , transformOrder = [ Rotate ]
              , expected = "rotateX(0deg) translateX(0px) skewX(0deg) scaleX(0)"
              }
            , { description = "when initialized with Scale only writes scale, translate, rotate, skew"
              , initFuncs = initFuncs f
              , transformOrder = [ Scale ]
              , expected = "scaleX(0) translateX(0px) rotateX(0deg) skewX(0deg)"
              }
            , { description = "when initialized with Skew only writes skew, translate, rotate, scale"
              , initFuncs = initFuncs f
              , transformOrder = [ Skew ]
              , expected = "skewX(0deg) translateX(0px) rotateX(0deg) scaleX(0)"
              }
            , { description = "when initialized with Rotate, Scale only writes rotate, scale, translate, skew"
              , initFuncs = initFuncs f
              , transformOrder = [ Rotate, Scale ]
              , expected = "rotateX(0deg) scaleX(0) translateX(0px) skewX(0deg)"
              }
            , { description = "when initialized with Scale, Skew, Rotate only writes scale, skew, rotate, translate"
              , initFuncs = initFuncs f
              , transformOrder = [ Scale, Skew, Rotate ]
              , expected = "scaleX(0) skewX(0deg) rotateX(0deg) translateX(0px)"
              }
            ]
    }


initFuncs : Factory a b c d e f g h i j -> List (a -> a)
initFuncs f =
    [ f.rotate.initX animGroup 0
    , f.scale.initX animGroup 0
    , f.skew.initX animGroup 0
    , f.translate.initX animGroup 0
    ]
