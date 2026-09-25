module Anim.Engine.Keyframe.Api.InitSpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Custom as Property
import Anim.Property.CustomColor as CustomColor
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Helpers.Engine.Api.InitSpec.Runner as Runner exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.CustomColor exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.CustomProperty exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.MultipleGroups exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.MultipleProperties exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Opacity exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.PerspectiveOrigin exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Rotate exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Scale exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Size exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Skew exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Translate exposing (..)
import Helpers.Engine.Keyframe exposing (KeyframeBuilderFunction)
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "Keyframe.init, writes inline styles, and will-change" <|
        Runner.run Keyframe.init Keyframe.attributes <|
            [ customPropertyTestData customPropertyFactory
            , customColorTestData customColorFactory
            , opacityTestData opacityFactory
            , perspectiveOriginTestData perspectiveOriginFactory
            , rotateTestData rotateFactory
            , scaleTestData scaleFactory
            , skewTestData skewFactory
            , sizeTestData sizeFactory
            , translateTestData translateFactory
            , multiPropertyTestData multiPropertyFactory
            , multiGroupTestData multiGroupFactory
            ]


customPropertyFactory : CustomPropertyInitFactory KeyframeBuilderFunction
customPropertyFactory =
    { init = Property.init }


customColorFactory : CustomColorInitFactory KeyframeBuilderFunction
customColorFactory =
    { init = CustomColor.init }


opacityFactory : OpacityInitFactory KeyframeBuilderFunction
opacityFactory =
    { init = Opacity.init }


perspectiveOriginFactory : PerspectiveOriginInitFactory KeyframeBuilderFunction
perspectiveOriginFactory =
    { initX = PerspectiveOrigin.initX
    , initY = PerspectiveOrigin.initY
    , initXY = PerspectiveOrigin.initXY
    , initCssUnitX = PerspectiveOrigin.initCssUnitX
    , initCssUnitY = PerspectiveOrigin.initCssUnitY
    , initCssUnit = PerspectiveOrigin.initCssUnit
    }


rotateFactory : RotateInitFactory KeyframeBuilderFunction
rotateFactory =
    { initX = Rotate.initX
    , initY = Rotate.initY
    , initZ = Rotate.initZ
    , initXY = Rotate.initXY
    , initXZ = Rotate.initXZ
    , initYZ = Rotate.initYZ
    , initXYZ = Rotate.initXYZ
    }


scaleFactory : ScaleInitFactory KeyframeBuilderFunction
scaleFactory =
    { initX = Scale.initX
    , initY = Scale.initY
    , initZ = Scale.initZ
    , initXY = Scale.initXY
    , initXZ = Scale.initXZ
    , initYZ = Scale.initYZ
    , initXYZ = Scale.initXYZ
    }


sizeFactory : SizeInitFactory KeyframeBuilderFunction
sizeFactory =
    { initH = Size.initH
    , initW = Size.initW
    , initHW = Size.initHW
    , initCssUnitH = Size.initCssUnitH
    , initCssUnitW = Size.initCssUnitW
    , initCssUnit = Size.initCssUnit
    }


skewFactory : SkewInitFactory KeyframeBuilderFunction
skewFactory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    }


translateFactory : TranslateInitFactory KeyframeBuilderFunction
translateFactory =
    { initX = Translate.initX
    , initY = Translate.initY
    , initZ = Translate.initZ
    , initXY = Translate.initXY
    , initXZ = Translate.initXZ
    , initYZ = Translate.initYZ
    , initXYZ = Translate.initXYZ
    , initCssUnit = Translate.initCssUnit
    , initCssUnitX = Translate.initCssUnitX
    , initCssUnitY = Translate.initCssUnitY
    , initCssUnitZ = Translate.initCssUnitZ
    }


multiPropertyFactory : MultiPropertyInitFactory KeyframeBuilderFunction
multiPropertyFactory =
    { opacity = opacityFactory
    , translate = translateFactory
    }


multiGroupFactory : MultiGroupInitFactory KeyframeBuilderFunction
multiGroupFactory =
    { perspectiveOrigin = perspectiveOriginFactory
    , size = sizeFactory
    , translate = translateFactory
    }
