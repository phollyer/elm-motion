module Anim.Internal.Property.Size exposing
    ( Size
    , default
    , distance
    , duration
    , fromRecord
    , fromTuple
    , getH
    , getW
    , heightToCssString
    , interpolate
    , speed
    , toCssString
    , toRecord
    , toTuple
    , widthToCssString
    )

import Anim.Internal.Unit as InternalUnit
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Size
    = Size { w : Float, h : Float }


default : Size
default =
    Size { w = 0, h = 0 }



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


getH : Size -> Float
getH (Size dimensions) =
    dimensions.h


getW : Size -> Float
getW (Size dimensions) =
    dimensions.w


fromRecord : { width : Float, height : Float } -> Size
fromRecord record =
    Size { w = record.width, h = record.height }


fromTuple : ( Float, Float ) -> Size
fromTuple ( width, height ) =
    Size { w = width, h = height }


toTuple : Size -> ( Float, Float )
toTuple (Size dimensions) =
    ( dimensions.w, dimensions.h )


toRecord : Size -> { width : Float, height : Float }
toRecord (Size dimensions) =
    { width = dimensions.w, height = dimensions.h }



-- ============================================================
-- CONVERSIONS
-- ============================================================


toCssString : InternalUnit.ResolvedLengthAxes -> Size -> String
toCssString axes size =
    let
        ( width, height ) =
            toTuple size
    in
    "width: "
        ++ String.fromFloat width
        ++ InternalUnit.toCssSuffix axes.x
        ++ "; height: "
        ++ String.fromFloat height
        ++ InternalUnit.toCssSuffix axes.y


widthToCssString : InternalUnit.ResolvedLengthAxes -> Size -> String
widthToCssString axes (Size dimensions) =
    String.fromFloat dimensions.w ++ InternalUnit.toCssSuffix axes.x


heightToCssString : InternalUnit.ResolvedLengthAxes -> Size -> String
heightToCssString axes (Size dimensions) =
    String.fromFloat dimensions.h ++ InternalUnit.toCssSuffix axes.y



-- ============================================================
-- MATH
-- ============================================================


distance : Size -> Size -> Float
distance (Size start) (Size end) =
    let
        dw =
            end.w - start.w

        dh =
            end.h - start.h
    in
    sqrt (dw * dw + dh * dh)


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


interpolate : Float -> Size -> Size -> Size
interpolate t (Size start) (Size endSize) =
    Size
        { w = start.w + (endSize.w - start.w) * t
        , h = start.h + (endSize.h - start.h) * t
        }
