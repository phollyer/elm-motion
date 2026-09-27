module Factories.Properties.All exposing
    ( InitFactory
    , initFactory
    )

import Anim.Builder exposing (AnimBuilder)
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory


type alias InitFactory builder =
    { opacity : OpacityFactory.InitFactory builder
    , perspectiveOrigin : PerspectiveOriginFactory.InitFactory builder
    , rotate : RotateFactory.InitFactory builder
    , scale : ScaleFactory.InitFactory builder
    , size : SizeFactory.InitFactory builder
    , skew : SkewFactory.InitFactory builder
    , translate : TranslateFactory.InitFactory builder
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
