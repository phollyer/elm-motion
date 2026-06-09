module Anim.Internal.Property.Scale exposing
    ( Scale(..)
    , default
    , distance
    , duration
    , fromRecord
    , fromTriple
    , getX
    , getY
    , getZ
    , interpolate
    , speed
    , toCssPropertyValue
    , toCssString
    , toRecord
    , toTriple
    )

import Anim.Internal.Property.Shared.Axis3 as Axis
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Scale
    = Scale { x : Float, y : Float, z : Float }


default : Scale
default =
    Scale { x = 1.0, y = 1.0, z = 1.0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Axis.Axis3Support Scale
support =
    { zero = default -- For Scale, "zero" is actually (1,1,1)
    , fromRecord = Scale
    , toRecord = \(Scale coords) -> coords

    -- Scale uses additive operations: 1.0 + 0.2 = 1.2 (120% scale)
    , add = \(Scale a) (Scale b) -> Scale { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Scale a) (Scale b) -> Scale { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Scale coords) -> Scale { x = coords.x * factor, y = coords.y * factor, z = coords.z * factor }
    }



-- ============================================================
-- CONVERSIONS
-- ============================================================


toCssString : Scale -> String
toCssString (Scale { x, y, z }) =
    let
        parts =
            List.filterMap identity
                [ if x /= 1.0 then
                    Just ("scaleX(" ++ String.fromFloat x ++ ")")

                  else
                    Nothing
                , if y /= 1.0 then
                    Just ("scaleY(" ++ String.fromFloat y ++ ")")

                  else
                    Nothing
                , if z /= 1.0 then
                    Just ("scaleZ(" ++ String.fromFloat z ++ ")")

                  else
                    Nothing
                ]
    in
    case parts of
        [] ->
            "scale3d(1,1,1)"

        [ single ] ->
            single

        multiple ->
            String.join " " multiple


toCssPropertyValue : Scale -> String
toCssPropertyValue (Scale { x, y, z }) =
    if z /= 1.0 then
        String.fromFloat x ++ " " ++ String.fromFloat y ++ " " ++ String.fromFloat z

    else if x == y then
        String.fromFloat x

    else
        String.fromFloat x ++ " " ++ String.fromFloat y



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


toTriple : Scale -> ( Float, Float, Float )
toTriple =
    Axis.toTriple support


fromTriple : ( Float, Float, Float ) -> Scale
fromTriple =
    Axis.fromTriple support


toRecord : Scale -> { x : Float, y : Float, z : Float }
toRecord =
    Axis.toRecord support


fromRecord : { x : Float, y : Float, z : Float } -> Scale
fromRecord =
    Axis.fromRecord support


getY : Scale -> Float
getY (Scale { y }) =
    y


getX : Scale -> Float
getX (Scale { x }) =
    x


getZ : Scale -> Float
getZ (Scale { z }) =
    z



-- ============================================================
-- MATH
-- ============================================================


interpolate : Float -> Scale -> Scale -> Scale
interpolate =
    Axis.interpolate support


distance : Scale -> Scale -> Float
distance =
    Axis.distance support


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration
