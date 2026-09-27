module Factories.Properties.All exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Factories.Properties.CustomColor as CustomColorFactory
import Factories.Properties.CustomProperty as CustomPropertyFactory
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory


type alias Factory animBuilder customColorEng customPropertyEng opacityEng perspectiveOriginEng rotateEng scaleBuilder sizeBuilder skewBuilder translateBuilder =
    { customColor : CustomColorFactory.Factory animBuilder customColorEng
    , customProperty : CustomPropertyFactory.Factory animBuilder customPropertyEng
    , opacity : OpacityFactory.Factory animBuilder opacityEng
    , perspectiveOrigin : PerspectiveOriginFactory.Factory animBuilder perspectiveOriginEng
    , rotate : RotateFactory.Factory animBuilder rotateEng
    , scale : ScaleFactory.Factory animBuilder scaleBuilder
    , size : SizeFactory.Factory animBuilder sizeBuilder
    , skew : SkewFactory.Factory animBuilder skewBuilder
    , translate : TranslateFactory.Factory animBuilder translateBuilder
    }


factory : Factory (AnimBuilder eng) eng eng eng eng eng (Scale.Builder eng) (Size.Builder eng) (Skew.Builder eng) (Translate.Builder eng)
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
