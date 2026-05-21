module Anim.Internal.Engine.Shared.Interpolation exposing
    ( interpolateFloat
    , interpolateOpacity
    , interpolatePerspectiveOrigin
    , interpolateRotate
    , interpolateScale
    , interpolateSize
    , interpolateSkew
    , interpolateTranslate
    , interpolateTriple
    , interpolateTuple
    )

{-| Engine-agnostic interpolation primitives used by both the Sub engine
(driven by an Elm-side rAF loop) and the WAAPI engine (driven by raw
progress floats arriving over the `motionMsg` port). Anything that
needs Sub's `PropertyAnimation` record lives in
`Anim.Internal.Engine.Sub.Interpolation` and is built on top of these.
-}

import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)



-- ============================================================
-- CORE INTERPOLATION
-- ============================================================


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat t start end =
    start + (end - start) * t


interpolateTriple : (a -> ( Float, Float, Float )) -> (( Float, Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTriple toTriple fromTriple t start end =
    let
        ( s1, s2, s3 ) =
            toTriple start

        ( e1, e2, e3 ) =
            toTriple end
    in
    fromTriple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2, interpolateFloat t s3 e3 )


interpolateTuple : (a -> ( Float, Float )) -> (( Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTuple toTuple fromTuple t start end =
    let
        ( s1, s2 ) =
            toTuple start

        ( e1, e2 ) =
            toTuple end
    in
    fromTuple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2 )



-- ============================================================
-- PROPERTY INTERPOLATION
-- ============================================================


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity t start end =
    Opacity.fromFloat (interpolateFloat t (Opacity.toFloat start) (Opacity.toFloat end))


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    interpolateTriple Rotate.toTriple Rotate.fromTriple


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    interpolateTriple Scale.toTriple Scale.fromTriple


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    interpolateTuple Size.toTuple Size.fromTuple


interpolatePerspectiveOrigin : Float -> PerspectiveOrigin -> PerspectiveOrigin -> PerspectiveOrigin
interpolatePerspectiveOrigin =
    PerspectiveOrigin.interpolate


interpolateSkew : Float -> Skew -> Skew -> Skew
interpolateSkew =
    interpolateTuple Skew.toTuple Skew.fromTuple


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    interpolateTriple Translate.toTriple Translate.fromTriple
