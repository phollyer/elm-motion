module Factories.Properties.All exposing
    ( Factory
    , InitFactory
    , factory
    , initFactory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory


type alias Factory animBuilder rotateBuilder scaleBuilder translateBuilder =
    { opacity : OpacityFactory.Factory animBuilder
    , perspectiveOrigin : PerspectiveOriginFactory.Factory animBuilder
    , rotate : RotateFactory.Factory animBuilder rotateBuilder
    , scale : ScaleFactory.Factory animBuilder scaleBuilder
    , size : SizeFactory.Factory animBuilder
    , skew : SkewFactory.Factory animBuilder
    , translate : TranslateFactory.Factory animBuilder translateBuilder
    }


factory : Factory (AnimBuilder eng -> AnimBuilder eng) (Rotate.Builder eng -> Rotate.Builder eng) (Scale.Builder eng -> Scale.Builder eng) (Translate.Builder eng -> Translate.Builder eng)
factory =
    { opacity = OpacityFactory.factory
    , perspectiveOrigin = PerspectiveOriginFactory.factory
    , rotate = RotateFactory.factory
    , scale = ScaleFactory.factory
    , size = SizeFactory.factory
    , skew = SkewFactory.factory
    , translate = TranslateFactory.factory
    }


type alias InitFactory animBuilder =
    { opacity : OpacityFactory.InitFactory animBuilder
    , perspectiveOrigin : PerspectiveOriginFactory.InitFactory animBuilder
    , rotate : RotateFactory.InitFactory animBuilder
    , scale : ScaleFactory.InitFactory animBuilder
    , size : SizeFactory.InitFactory animBuilder
    , skew : SkewFactory.InitFactory animBuilder
    , translate : TranslateFactory.InitFactory animBuilder
    }


initFactory : InitFactory (AnimBuilder eng -> AnimBuilder eng)
initFactory =
    { opacity = OpacityFactory.initFactory
    , perspectiveOrigin = PerspectiveOriginFactory.initFactory
    , rotate = RotateFactory.initFactory
    , scale = ScaleFactory.initFactory
    , size = SizeFactory.initFactory
    , skew = SkewFactory.initFactory
    , translate = TranslateFactory.initFactory
    }
