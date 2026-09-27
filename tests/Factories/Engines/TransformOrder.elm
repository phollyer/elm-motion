module Factories.Engines.TransformOrder exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Factories.Properties.Init exposing (..)
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory


type alias TransformOrderFactory animBuilder rotateBuilder scaleBuilder translateBuilder =
    { transformOrder : List TransformProperty -> animBuilder
    , rotate : RotateFactory.Factory animBuilder rotateBuilder
    , scale : ScaleFactory.Factory animBuilder scaleBuilder
    , skew : SkewFactory.InitFactory animBuilder
    , translate : TranslateFactory.Factory animBuilder translateBuilder
    }


transformOrderFactory :
    (List TransformProperty -> AnimBuilder eng -> AnimBuilder eng)
    -> TransformOrderFactory (AnimBuilder eng -> AnimBuilder eng) (Rotate.Builder eng -> Rotate.Builder eng) (Scale.Builder eng -> Scale.Builder eng) (Translate.Builder eng -> Translate.Builder eng)
transformOrderFactory transformOrderFunc =
    { transformOrder = transformOrderFunc
    , rotate = RotateFactory.factory
    , scale = ScaleFactory.factory
    , skew = SkewFactory.initFactory
    , translate = TranslateFactory.factory
    }
