module Shared.Easing.Keyframes exposing
    ( KeyframeSample
    , defaultKeyframeCount
    , generateKeyframes
    , sampleCountForDuration
    )

{-| Keyframe sample generation for easings the WAAPI engine cannot
represent with a single CSS easing string.

The Web Animations API's `easing` field accepts CSS easing keywords or a
`cubic-bezier(...)`. Bounce and Elastic curves cannot be approximated by
a single cubic bezier, so the WAAPI engine falls back to a pre-computed
`easingKeyframes` array. Each sample carries both its time offset
(`0..1`) and its eased value so the JS runtime can place keyframes at
their true times rather than assuming uniform spacing.

The Keyframe engine samples its `@keyframes` stops at the same density
to keep the two engines visually consistent.

-}

import Ease as E
import Motion.Easing exposing (Easing(..))


{-| A single easing keyframe sample: the time offset along the animation
(`0..1`) and the eased progress at that offset.
-}
type alias KeyframeSample =
    { offset : Float
    , value : Float
    }



-- ============================================================
-- KEYFRAME COUNT
-- ============================================================


{-| Default number of keyframe samples used by both the WAAPI engine
(per-property `easingKeyframes` arrays) and the Keyframe engine
(`@keyframes` stop count).

This describes curve shape, not playback frame rate — the browser still
animates at its native refresh rate and interpolates linearly between
the samples.

-}
defaultKeyframeCount : Int
defaultKeyframeCount =
    60


{-| Pick a keyframe sample count appropriate for an animation of a
given duration.

Engines that bake to a static keyframe representation (Keyframe
`@keyframes`, WAAPI `easingKeyframes`) need enough samples that the
browser's linear interpolation between samples stays visually smooth.
The default 60 samples is fine for short animations (≤1s) but leaves
long-running motions — notably low-stiffness or high-mass springs whose
settle time can run into tens of seconds — with samples spaced far
enough apart that the linear segments become visible.

The heuristic is ~60 samples per second of motion (floor of 60, cap of

1.  which keeps sub-second motions on their existing budget while
    giving long springs the resolution they need to remain smooth.

-}
sampleCountForDuration : Float -> Int
sampleCountForDuration durationMs =
    let
        target =
            round (durationMs / 16.0)
    in
    max defaultKeyframeCount (min 1000 target)



-- ============================================================
-- KEYFRAME GENERATION
-- ============================================================


{-| Generate keyframe samples for an `Easing` over a given duration.

Returns a list of `{ offset, value }` records sampled densely enough to
reproduce complex easings via linear interpolation between samples. The
`offset` is the sample's true time on `[0, 1]`; the `value` is the
eased progress at that offset.

For non-complex easings the WAAPI encoder routes through CSS `easing`
strings instead of calling this function; a defensive 2-point linear
ramp is returned if anything else falls through.

-}
generateKeyframes : Easing -> Float -> List KeyframeSample
generateKeyframes easing _ =
    case easing of
        BounceIn ->
            sampleWithCriticalPoints E.inBounce defaultKeyframeCount bounceInCriticalTimes

        BounceOut ->
            sampleWithCriticalPoints E.outBounce defaultKeyframeCount bounceOutCriticalTimes

        BounceInOut ->
            sampleWithCriticalPoints E.inOutBounce defaultKeyframeCount bounceInOutCriticalTimes

        ElasticIn ->
            uniformSamples E.inElastic defaultKeyframeCount

        ElasticOut ->
            uniformSamples E.outElastic defaultKeyframeCount

        ElasticInOut ->
            uniformSamples E.inOutElastic defaultKeyframeCount

        _ ->
            [ { offset = 0.0, value = 0.0 }
            , { offset = 1.0, value = 1.0 }
            ]


{-| Sample a function using both the base uniform density and additional
critical time points where bounce curves hit piece boundaries or extrema.
-}
sampleWithCriticalPoints : (Float -> Float) -> Int -> List Float -> List KeyframeSample
sampleWithCriticalPoints f n criticalTimes =
    mergeSampleTimes n criticalTimes
        |> List.map (\t -> { offset = t, value = f t })


{-| Merge uniform sample times with explicit critical times and normalize
to a sorted, de-duplicated 0..1 list.
-}
mergeSampleTimes : Int -> List Float -> List Float
mergeSampleTimes n criticalTimes =
    uniformTimes n
        ++ criticalTimes
        |> normalizeTimes


{-| Uniformly spaced sample times across [0, 1] (inclusive).
-}
uniformTimes : Int -> List Float
uniformTimes n =
    if n <= 1 then
        if n == 1 then
            [ 0 ]

        else
            []

    else
        List.range 0 (n - 1)
            |> List.map (\t -> toFloat t / toFloat (n - 1))


{-| Clamp to [0, 1], then sort and de-duplicate with a tiny epsilon to
avoid double samples from floating-point jitter.
-}
normalizeTimes : List Float -> List Float
normalizeTimes times =
    times
        |> List.map (clamp 0 1)
        |> List.sort
        |> dedupeSorted 0.0000001


dedupeSorted : Float -> List Float -> List Float
dedupeSorted epsilon sortedTimes =
    sortedTimes
        |> List.foldl
            (\time acc ->
                case acc of
                    previous :: _ ->
                        if abs (time - previous) <= epsilon then
                            acc

                        else
                            time :: acc

                    [] ->
                        [ time ]
            )
            []
        |> List.reverse


{-| Piece boundaries for Ease.outBounce's piecewise polynomial.
-}
bounceOutBoundaryTimes : List Float
bounceOutBoundaryTimes =
    let
        d1 =
            2.75
    in
    [ 0
    , 1 / d1
    , 2 / d1
    , 2.5 / d1
    , 1
    ]


{-| Local maxima/minima locations for Ease.outBounce's later segments.
-}
bounceOutExtremaTimes : List Float
bounceOutExtremaTimes =
    let
        d1 =
            2.75
    in
    [ 1.5 / d1
    , 2.25 / d1
    , 2.625 / d1
    ]


bounceOutCriticalTimes : List Float
bounceOutCriticalTimes =
    bounceOutBoundaryTimes ++ bounceOutExtremaTimes


bounceInCriticalTimes : List Float
bounceInCriticalTimes =
    bounceOutCriticalTimes
        |> List.map (\t -> 1 - t)


bounceInOutCriticalTimes : List Float
bounceInOutCriticalTimes =
    let
        firstHalf =
            bounceInCriticalTimes
                |> List.map (\t -> t / 2)

        secondHalf =
            bounceOutCriticalTimes
                |> List.map (\t -> 0.5 + (t / 2))
    in
    firstHalf ++ secondHalf


{-| Sample a `0..1 -> Float` function at `n` evenly spaced points across
[0, 1] (inclusive on both ends).
-}
uniformSamples : (Float -> Float) -> Int -> List KeyframeSample
uniformSamples f n =
    if n <= 1 then
        if n == 1 then
            [ { offset = 0, value = f 0 } ]

        else
            []

    else
        List.range 0 (n - 1)
            |> List.map
                (\i ->
                    let
                        t =
                            toFloat i / toFloat (n - 1)
                    in
                    { offset = t, value = f t }
                )
