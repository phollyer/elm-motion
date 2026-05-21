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
import Anim.Unit exposing (Unit)
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type PerspectiveOrigin
    = PerspectiveOrigin { x : Float, y : Float }


default : PerspectiveOrigin
default =
    PerspectiveOrigin { x = 50, y = 50 }



-- ============================================================
-- CONSTRUCTORS
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


getX : PerspectiveOrigin -> Float
getX (PerspectiveOrigin { x }) =
    x


getY : PerspectiveOrigin -> Float
getY (PerspectiveOrigin { y }) =
    y



-- ============================================================
-- CONVERSIONS
-- ============================================================


toCssString : Unit -> PerspectiveOrigin -> String
toCssString unit (PerspectiveOrigin { x, y }) =
    let
        suffix =
            InternalUnit.toCssSuffix unit
    in
    String.fromFloat x ++ suffix ++ " " ++ String.fromFloat y ++ suffix



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


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


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
