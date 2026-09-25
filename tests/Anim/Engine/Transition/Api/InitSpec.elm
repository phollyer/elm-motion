module Anim.Engine.Transition.Api.InitSpec exposing (suite)

import Anim.Engine.Transition as Transition
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
import Helpers.Engine.Transition exposing (TransitionBuilderFunction)
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "Transition.init, writes inline styles, and will-change" <|
        Runner.run Transition.init Transition.attributes <|
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


customPropertyFactory : CustomPropertyInitFactory TransitionBuilderFunction
customPropertyFactory =
    { init = Property.init }


customColorFactory : CustomColorInitFactory TransitionBuilderFunction
customColorFactory =
    { init = CustomColor.init }


opacityFactory : OpacityInitFactory TransitionBuilderFunction
opacityFactory =
    { init = Opacity.init }


perspectiveOriginFactory : PerspectiveOriginInitFactory TransitionBuilderFunction
perspectiveOriginFactory =
    { initX = PerspectiveOrigin.initX
    , initY = PerspectiveOrigin.initY
    , initXY = PerspectiveOrigin.initXY
    , initCssUnitX = PerspectiveOrigin.initCssUnitX
    , initCssUnitY = PerspectiveOrigin.initCssUnitY
    , initCssUnit = PerspectiveOrigin.initCssUnit
    }


rotateFactory : RotateInitFactory TransitionBuilderFunction
rotateFactory =
    { initX = Rotate.initX
    , initY = Rotate.initY
    , initZ = Rotate.initZ
    , initXY = Rotate.initXY
    , initXZ = Rotate.initXZ
    , initYZ = Rotate.initYZ
    , initXYZ = Rotate.initXYZ
    }


scaleFactory : ScaleInitFactory TransitionBuilderFunction
scaleFactory =
    { initX = Scale.initX
    , initY = Scale.initY
    , initZ = Scale.initZ
    , initXY = Scale.initXY
    , initXZ = Scale.initXZ
    , initYZ = Scale.initYZ
    , initXYZ = Scale.initXYZ
    }


sizeFactory : SizeInitFactory TransitionBuilderFunction
sizeFactory =
    { initH = Size.initH
    , initW = Size.initW
    , initHW = Size.initHW
    , initCssUnitH = Size.initCssUnitH
    , initCssUnitW = Size.initCssUnitW
    , initCssUnit = Size.initCssUnit
    }


skewFactory : SkewInitFactory TransitionBuilderFunction
skewFactory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    }


translateFactory : TranslateInitFactory TransitionBuilderFunction
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


multiPropertyFactory : MultiPropertyInitFactory TransitionBuilderFunction
multiPropertyFactory =
    { opacity = opacityFactory
    , translate = translateFactory
    }


multiGroupFactory : MultiGroupInitFactory TransitionBuilderFunction
multiGroupFactory =
    { perspectiveOrigin = perspectiveOriginFactory
    , size = sizeFactory
    , translate = translateFactory
    }
