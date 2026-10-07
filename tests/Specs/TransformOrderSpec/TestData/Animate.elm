module Specs.TransformOrderSpec.TestData.Animate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Specs.TransformOrderSpec.TestData exposing (TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "transformOrder writes the correct inline styles"
    , testCases =
        List.map AnimateTest
            [ { description = "when animated without a specified transform order writes the default transform order"
              , animateFuncs = animateFuncs
              , transformOrder = []
              , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
              }
            , { description = "when animated with only Translate declared, writes translate, rotate, skew, scale"
              , animateFuncs = animateFuncs
              , transformOrder = [ Translate ]
              , expected = "translateX(0px) rotateX(0deg) skewX(0deg) scaleX(0)"
              }
            , { description = "when animated with only Rotate declared, writes rotate, translate, skew, scale"
              , animateFuncs = animateFuncs
              , transformOrder = [ Rotate ]
              , expected = "rotateX(0deg) translateX(0px) skewX(0deg) scaleX(0)"
              }
            , { description = "when animated with only Scale declared, writes scale, translate, rotate, skew"
              , animateFuncs = animateFuncs
              , transformOrder = [ Scale ]
              , expected = "scaleX(0) translateX(0px) rotateX(0deg) skewX(0deg)"
              }
            , { description = "when animated with only Skew declared, writes skew, translate, rotate, scale"
              , animateFuncs = animateFuncs
              , transformOrder = [ Skew ]
              , expected = "skewX(0deg) translateX(0px) rotateX(0deg) scaleX(0)"
              }
            , { description = "when animated with Translate, Scale declared, writes translate, scale, rotate, skew"
              , animateFuncs = animateFuncs
              , transformOrder = [ Translate, Scale ]
              , expected = "translateX(0px) scaleX(0) rotateX(0deg) skewX(0deg)"
              }
            , { description = "when animated with Scale, Rotate declared, writes translate, scale, rotate, skew"
              , animateFuncs = animateFuncs
              , transformOrder = [ Scale, Rotate ]
              , expected = "scaleX(0) rotateX(0deg) translateX(0px) skewX(0deg)"
              }
            , { description = "when animated with Scale, Skew, Rotate, Translate declared, writes scale, rotate, translate, skew"
              , animateFuncs = animateFuncs
              , transformOrder = [ Scale, Skew, Rotate, Translate ]
              , expected = "scaleX(0) skewX(0deg) rotateX(0deg) translateX(0px)"
              }
            ]
    }


animateFuncs : AnimBuilder eng -> AnimBuilder eng
animateFuncs =
    Translate.begin
        >> Translate.toX 0
        >> Translate.end
        >> Rotate.begin
        >> Rotate.toX 0
        >> Rotate.end
        >> Scale.begin
        >> Scale.toX 0
        >> Scale.end
        >> Skew.begin
        >> Skew.toX 0
        >> Skew.end
