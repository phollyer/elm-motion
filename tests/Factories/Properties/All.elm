module Factories.Properties.All exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Factories.Properties.CustomColor as CustomColorFactory
import Factories.Properties.CustomProperty as CustomPropertyFactory
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory


type alias Factory animBuilder customColorEng customPropertyEng opacityEng perspectiveOriginEng rotateEng scaleEng sizeEng skewEng translateEng =
    { customColor : CustomColorFactory.Factory animBuilder customColorEng
    , customProperty : CustomPropertyFactory.Factory animBuilder customPropertyEng
    , opacity : OpacityFactory.Factory animBuilder opacityEng
    , perspectiveOrigin : PerspectiveOriginFactory.Factory animBuilder perspectiveOriginEng
    , rotate : RotateFactory.Factory animBuilder rotateEng
    , scale : ScaleFactory.Factory animBuilder scaleEng
    , size : SizeFactory.Factory animBuilder sizeEng
    , skew : SkewFactory.Factory animBuilder skewEng
    , translate : TranslateFactory.Factory animBuilder translateEng
    }


factory : Factory (AnimBuilder eng) eng eng eng eng eng eng eng eng eng
factory =
    { customColor = CustomColorFactory.factory
    , customProperty = CustomPropertyFactory.factory
    , opacity = OpacityFactory.factory
    , perspectiveOrigin = PerspectiveOriginFactory.factory
    , rotate = RotateFactory.factory
    , scale = ScaleFactory.factory
    , size = SizeFactory.factory
    , skew = SkewFactory.factory
    , translate = TranslateFactory.factory
    }
