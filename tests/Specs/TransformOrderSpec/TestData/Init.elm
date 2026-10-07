module Specs.TransformOrderSpec.TestData.Init exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Helpers.AnimGroups exposing (animGroup)
import Specs.TransformOrderSpec.TestData exposing (TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "when initialized, transformOrder writes the correct inline styles"
    , testCases =
        List.map InitTest
            [ { description = "when initialized without a transform order, writes the default transform order"
              , initFuncs = initFuncs
              , transformOrder = []
              , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
              }
            , { description = "when initialized with Rotate only writes rotate, translate, skew, scale"
              , initFuncs = initFuncs
              , transformOrder = [ Rotate ]
              , expected = "rotateX(0deg) translateX(0px) skewX(0deg) scaleX(0)"
              }
            , { description = "when initialized with Scale only writes scale, translate, rotate, skew"
              , initFuncs = initFuncs
              , transformOrder = [ Scale ]
              , expected = "scaleX(0) translateX(0px) rotateX(0deg) skewX(0deg)"
              }
            , { description = "when initialized with Skew only writes skew, translate, rotate, scale"
              , initFuncs = initFuncs
              , transformOrder = [ Skew ]
              , expected = "skewX(0deg) translateX(0px) rotateX(0deg) scaleX(0)"
              }
            , { description = "when initialized with Rotate, Scale only writes rotate, scale, translate, skew"
              , initFuncs = initFuncs
              , transformOrder = [ Rotate, Scale ]
              , expected = "rotateX(0deg) scaleX(0) translateX(0px) skewX(0deg)"
              }
            , { description = "when initialized with Scale, Skew, Rotate only writes scale, skew, rotate, translate"
              , initFuncs = initFuncs
              , transformOrder = [ Scale, Skew, Rotate ]
              , expected = "scaleX(0) skewX(0deg) rotateX(0deg) translateX(0px)"
              }
            ]
    }


initFuncs : List (AnimBuilder eng -> AnimBuilder eng)
initFuncs =
    [ Rotate.initX animGroup 0
    , Scale.initX animGroup 0
    , Skew.initX animGroup 0
    , Translate.initX animGroup 0
    ]
