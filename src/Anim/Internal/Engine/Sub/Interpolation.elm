module Anim.Internal.Engine.Sub.Interpolation exposing
    ( calculateProgress
    , interpolateEasedProgress
    , interpolateFloat
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

{-| Sub-engine interpolation. The generic primitives live in
`Anim.Internal.Engine.Shared.Interpolation` and are re-exported here so
existing Sub-engine call sites keep working unchanged. Anything that
depends on Sub's `PropertyAnimation` record (`calculateProgress`,
`interpolateEasedProgress`) stays in this module.
-}

import Anim.Internal.Engine.Shared.Interpolation as Shared
import Anim.Internal.Engine.Sub.Animation exposing (PropertyAnimation)
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Skew exposing (Skew)
import Anim.Internal.Property.Translate exposing (Translate)



-- ============================================================
-- PROGRESS
-- ============================================================


calculateProgress : { a | elapsedMs : Float, delayMs : Float, totalDurationMs : Float, isComplete : Bool } -> Float
calculateProgress timing =
    if timing.isComplete || timing.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (timing.elapsedMs - timing.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / timing.totalDurationMs)


interpolateEasedProgress : (Float -> a -> a -> a) -> PropertyAnimation a -> a
interpolateEasedProgress interpolate anim =
    let
        easedProgress =
            anim.easingFunction (calculateProgress anim)
    in
    interpolate easedProgress anim.start anim.end



-- ============================================================
-- RE-EXPORTS FROM SHARED
-- ============================================================


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat =
    Shared.interpolateFloat


interpolateTriple : (a -> ( Float, Float, Float )) -> (( Float, Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTriple =
    Shared.interpolateTriple


interpolateTuple : (a -> ( Float, Float )) -> (( Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTuple =
    Shared.interpolateTuple


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity =
    Shared.interpolateOpacity


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    Shared.interpolateRotate


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    Shared.interpolateScale


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    Shared.interpolateSize


interpolatePerspectiveOrigin : Float -> PerspectiveOrigin -> PerspectiveOrigin -> PerspectiveOrigin
interpolatePerspectiveOrigin =
    Shared.interpolatePerspectiveOrigin


interpolateSkew : Float -> Skew -> Skew -> Skew
interpolateSkew =
    Shared.interpolateSkew


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    Shared.interpolateTranslate
