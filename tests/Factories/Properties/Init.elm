module Factories.Properties.Init exposing
    ( CustomColorInitFactory
    , CustomPropertyInitFactory
    , MultiGroupInitFactory
    , MultiPropertyInitFactory
    , OpacityInitFactory
    , PerspectiveOriginInitFactory
    , RotateInitFactory
    , ScaleInitFactory
    , SizeInitFactory
    , SkewInitFactory
    , TranslateInitFactory
    , customColorFactory
    , customPropertyFactory
    , multiGroupFactory
    , multiPropertyFactory
    , opacityFactory
    , perspectiveOriginFactory
    , rotateFactory
    , scaleFactory
    , sizeFactory
    , skewFactory
    , translateFactory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color exposing (Color)
import Anim.Property.Custom as Property exposing (Property)
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty)
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))


type alias CustomColorInitFactory builder =
    { init : String -> ColorProperty -> Color -> builder }


type alias CustomPropertyInitFactory builder =
    { init : String -> Property -> Float -> builder }


type alias MultiGroupInitFactory builder =
    { translate : TranslateInitFactory builder
    , size : SizeInitFactory builder
    , perspectiveOrigin : PerspectiveOriginInitFactory builder
    }


type alias MultiPropertyInitFactory builder =
    { opacity : OpacityInitFactory builder
    , rotate : RotateInitFactory builder
    , scale : ScaleInitFactory builder
    , skew : SkewInitFactory builder
    , translate : TranslateInitFactory builder
    }


type alias OpacityInitFactory builder =
    { init : String -> Float -> builder }


type alias PerspectiveOriginInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initCssUnitX : Unit -> builder
    , initCssUnitY : Unit -> builder
    , initCssUnit : Unit -> builder
    }


type alias RotateInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initZ : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initXZ : String -> Float -> Float -> builder
    , initYZ : String -> Float -> Float -> builder
    , initXYZ : String -> Float -> Float -> Float -> builder
    }


type alias ScaleInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initZ : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initXZ : String -> Float -> Float -> builder
    , initYZ : String -> Float -> Float -> builder
    , initXYZ : String -> Float -> Float -> Float -> builder
    }


type alias SizeInitFactory builder =
    { initH : String -> Float -> builder
    , initW : String -> Float -> builder
    , initHW : String -> Float -> Float -> builder
    , initCssUnitH : Unit -> builder
    , initCssUnitW : Unit -> builder
    , initCssUnit : Unit -> builder
    }


type alias SkewInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    }


type alias TranslateInitFactory builder =
    { initX : String -> Float -> builder
    , initY : String -> Float -> builder
    , initZ : String -> Float -> builder
    , initXY : String -> Float -> Float -> builder
    , initXZ : String -> Float -> Float -> builder
    , initYZ : String -> Float -> Float -> builder
    , initXYZ : String -> Float -> Float -> Float -> builder
    , initCssUnit : Unit -> builder
    , initCssUnitX : Unit -> builder
    , initCssUnitY : Unit -> builder
    , initCssUnitZ : Unit -> builder
    }


customColorFactory : CustomColorInitFactory (AnimBuilder eng -> AnimBuilder eng)
customColorFactory =
    { init = CustomColor.init }


customPropertyFactory : CustomPropertyInitFactory (AnimBuilder eng -> AnimBuilder eng)
customPropertyFactory =
    { init = Property.init }


opacityFactory : OpacityInitFactory (AnimBuilder eng -> AnimBuilder eng)
opacityFactory =
    { init = Opacity.init }


perspectiveOriginFactory : PerspectiveOriginInitFactory (AnimBuilder eng -> AnimBuilder eng)
perspectiveOriginFactory =
    { initX = PerspectiveOrigin.initX
    , initY = PerspectiveOrigin.initY
    , initXY = PerspectiveOrigin.initXY
    , initCssUnitX = PerspectiveOrigin.initCssUnitX
    , initCssUnitY = PerspectiveOrigin.initCssUnitY
    , initCssUnit = PerspectiveOrigin.initCssUnit
    }


rotateFactory : RotateInitFactory (AnimBuilder eng -> AnimBuilder eng)
rotateFactory =
    { initX = Rotate.initX
    , initY = Rotate.initY
    , initZ = Rotate.initZ
    , initXY = Rotate.initXY
    , initXZ = Rotate.initXZ
    , initYZ = Rotate.initYZ
    , initXYZ = Rotate.initXYZ
    }


scaleFactory : ScaleInitFactory (AnimBuilder eng -> AnimBuilder eng)
scaleFactory =
    { initX = Scale.initX
    , initY = Scale.initY
    , initZ = Scale.initZ
    , initXY = Scale.initXY
    , initXZ = Scale.initXZ
    , initYZ = Scale.initYZ
    , initXYZ = Scale.initXYZ
    }


sizeFactory : SizeInitFactory (AnimBuilder eng -> AnimBuilder eng)
sizeFactory =
    { initH = Size.initH
    , initW = Size.initW
    , initHW = Size.initHW
    , initCssUnitH = Size.initCssUnitH
    , initCssUnitW = Size.initCssUnitW
    , initCssUnit = Size.initCssUnit
    }


skewFactory : SkewInitFactory (AnimBuilder eng -> AnimBuilder eng)
skewFactory =
    { initX = Skew.initX
    , initY = Skew.initY
    , initXY = Skew.initXY
    }


translateFactory : TranslateInitFactory (AnimBuilder eng -> AnimBuilder eng)
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


multiPropertyFactory : MultiPropertyInitFactory (AnimBuilder eng -> AnimBuilder eng)
multiPropertyFactory =
    { opacity = opacityFactory
    , rotate = rotateFactory
    , scale = scaleFactory
    , skew = skewFactory
    , translate = translateFactory
    }


multiGroupFactory : MultiGroupInitFactory (AnimBuilder eng -> AnimBuilder eng)
multiGroupFactory =
    { perspectiveOrigin = perspectiveOriginFactory
    , size = sizeFactory
    , translate = translateFactory
    }
