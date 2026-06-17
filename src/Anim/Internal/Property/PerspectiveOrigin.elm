module Anim.Internal.Property.PerspectiveOrigin exposing
    ( PerspectiveOrigin
    , default
    , distance
    , duration
    , fromRecord
    , getX
    , getY
    , interpolate
    , speed
    , toCssString
    , toRecord
    , toTuple
    )

import Anim.Internal.Unit as InternalUnit
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type PerspectiveOrigin
    = PerspectiveOrigin { x : Float, y : Float }



-- ============================================================
-- BUILD
-- ============================================================


default : PerspectiveOrigin
default =
    PerspectiveOrigin { x = 50, y = 50 }



-- ============================================================
-- QUERY
-- ============================================================


getX : PerspectiveOrigin -> Float
getX (PerspectiveOrigin { x }) =
    x


getY : PerspectiveOrigin -> Float
getY (PerspectiveOrigin { y }) =
    y



-- ============================================================
-- TRANSFORM
-- ============================================================


fromRecord : { x : Float, y : Float } -> PerspectiveOrigin
fromRecord =
    PerspectiveOrigin


toRecord : PerspectiveOrigin -> { x : Float, y : Float }
toRecord (PerspectiveOrigin rec) =
    rec


toTuple : PerspectiveOrigin -> ( Float, Float )
toTuple (PerspectiveOrigin { x, y }) =
    ( x, y )


toCssString : InternalUnit.ResolvedCssUnitAxes -> PerspectiveOrigin -> String
toCssString axes (PerspectiveOrigin { x, y }) =
    String.fromFloat x
        ++ InternalUnit.toCssSuffix axes.x
        ++ " "
        ++ String.fromFloat y
        ++ InternalUnit.toCssSuffix axes.y



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration



-- ============================================================
-- MATH
-- ============================================================


distance : PerspectiveOrigin -> PerspectiveOrigin -> Float
distance start end =
    let
        ( sx, sy ) =
            toTuple start

        ( ex, ey ) =
            toTuple end

        dx =
            ex - sx

        dy =
            ey - sy
    in
    sqrt (dx * dx + dy * dy)


interpolate : Float -> PerspectiveOrigin -> PerspectiveOrigin -> PerspectiveOrigin
interpolate t start end =
    let
        ( sx, sy ) =
            toTuple start

        ( ex, ey ) =
            toTuple end
    in
    PerspectiveOrigin
        { x = sx + (ex - sx) * t
        , y = sy + (ey - sy) * t
        }
