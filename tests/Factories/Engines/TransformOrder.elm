module Factories.Engines.TransformOrder exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Factories.Properties.Init exposing (..)


type alias TransformOrderFactory builder =
    { transformOrder : List TransformProperty -> builder
    , rotate : RotateInitFactory builder
    , scale : ScaleInitFactory builder
    , skew : SkewInitFactory builder
    , translate : TranslateInitFactory builder
    }


transformOrderFactory : (List TransformProperty -> AnimBuilder eng -> AnimBuilder eng) -> TransformOrderFactory (AnimBuilder eng -> AnimBuilder eng)
transformOrderFactory transformOrderFunc =
    { transformOrder = transformOrderFunc
    , rotate = rotateFactory
    , scale = scaleFactory
    , skew = skewFactory
    , translate = translateFactory
    }
