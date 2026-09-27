module Factories.Properties.Init exposing
    ( MultiGroupInitFactory
    , MultiPropertyInitFactory
    , multiGroupFactory
    , multiPropertyFactory
    )

import Anim.Builder exposing (AnimBuilder)
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory


type alias MultiGroupInitFactory builder =
    { translate : TranslateFactory.InitFactory builder
    , size : SizeFactory.InitFactory builder
    , perspectiveOrigin : PerspectiveOriginFactory.InitFactory builder
    }


type alias MultiPropertyInitFactory builder =
    { opacity : OpacityFactory.InitFactory builder
    , rotate : RotateFactory.InitFactory builder
    , scale : ScaleFactory.InitFactory builder
    , skew : SkewFactory.InitFactory builder
    , translate : TranslateFactory.InitFactory builder
    }


multiPropertyFactory : MultiPropertyInitFactory (AnimBuilder eng -> AnimBuilder eng)
multiPropertyFactory =
    { opacity = OpacityFactory.initFactory
    , rotate = RotateFactory.initFactory
    , scale = ScaleFactory.initFactory
    , skew = SkewFactory.initFactory
    , translate = TranslateFactory.initFactory
    }


multiGroupFactory : MultiGroupInitFactory (AnimBuilder eng -> AnimBuilder eng)
multiGroupFactory =
    { perspectiveOrigin = PerspectiveOriginFactory.initFactory
    , size = SizeFactory.initFactory
    , translate = TranslateFactory.initFactory
    }
