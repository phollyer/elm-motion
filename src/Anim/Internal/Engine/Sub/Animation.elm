module Anim.Internal.Engine.Sub.Animation exposing
    ( Animation(..)
    , PropertyAnimation
    , Timing
    , foldTiming
    , mapTiming
    , replaceAxes
    , reset
    , reverse
    , stop
    , toPropertyKey
    )

import Anim.Internal.Builder exposing (Iterations(..))
import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Unit exposing (ResolvedCssUnitAxes)
import Set exposing (Set)



-- ============================================================
-- TYPES
-- ============================================================


type Animation
    = CustomProperty String String (PropertyAnimation Float)
    | CustomColorProperty String (PropertyAnimation Color)
    | Opacity (PropertyAnimation Opacity)
    | PerspectiveOrigin ResolvedCssUnitAxes (PropertyAnimation PerspectiveOrigin)
    | Rotate (PropertyAnimation Rotate)
    | Scale (PropertyAnimation Scale)
    | Size ResolvedCssUnitAxes (PropertyAnimation Size)
    | Skew (PropertyAnimation Skew)
    | Translate ResolvedCssUnitAxes (PropertyAnimation Translate)


type alias PropertyAnimation property =
    { start : property
    , end : property
    , easingFunction : Float -> Float
    , delayMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , elapsedMs : Float
    }



-- ============================================================
-- QUERY
-- ============================================================


toPropertyKey : Animation -> String
toPropertyKey prop =
    case prop of
        Translate _ _ ->
            "translate"

        Rotate _ ->
            "rotate"

        Skew _ ->
            "skew"

        Scale _ ->
            "scale"

        Opacity _ ->
            "opacity"

        PerspectiveOrigin _ _ ->
            "perspectiveOrigin"

        Size _ _ ->
            "size"

        CustomProperty cssName _ _ ->
            "custom:" ++ cssName

        CustomColorProperty cssName _ ->
            "customColor:" ++ cssName



-- ============================================================
-- TIMING
-- ============================================================


type alias Timing =
    { elapsedMs : Float
    , isComplete : Bool
    , totalDurationMs : Float
    , delayMs : Float
    }



-- ============================================================
-- MODIFY
-- ============================================================


reset : Animation -> Animation
reset =
    mapTiming
        (\t ->
            { t
                | isComplete = False
                , elapsedMs = 0
            }
        )


reverse : Animation -> Animation
reverse anim =
    let
        swap a =
            { a
                | start = a.end
                , end = a.start
            }
    in
    case anim of
        Translate units a ->
            Translate units (swap a)

        Rotate a ->
            Rotate (swap a)

        Skew a ->
            Skew (swap a)

        Scale a ->
            Scale (swap a)

        Opacity a ->
            Opacity (swap a)

        PerspectiveOrigin units a ->
            PerspectiveOrigin units (swap a)

        Size units a ->
            Size units (swap a)

        CustomProperty cssName unit a ->
            CustomProperty cssName unit (swap a)

        CustomColorProperty cssName a ->
            CustomColorProperty cssName (swap a)


stop : Animation -> Animation
stop =
    mapTiming
        (\t ->
            { t
                | isComplete = True
                , elapsedMs = t.totalDurationMs + t.delayMs
            }
        )



-- ============================================================
-- HELPERS
-- ============================================================


toTiming : PropertyAnimation a -> Timing
toTiming anim =
    { elapsedMs = anim.elapsedMs
    , isComplete = anim.isComplete
    , totalDurationMs = anim.totalDurationMs
    , delayMs = anim.delayMs
    }


mapTiming : (Timing -> Timing) -> Animation -> Animation
mapTiming f anim =
    let
        apply a =
            applyTiming (f (toTiming a)) a
    in
    case anim of
        Translate units a ->
            Translate units (apply a)

        Rotate a ->
            Rotate (apply a)

        Skew a ->
            Skew (apply a)

        Scale a ->
            Scale (apply a)

        Opacity a ->
            Opacity (apply a)

        PerspectiveOrigin units a ->
            PerspectiveOrigin units (apply a)

        Size units a ->
            Size units (apply a)

        CustomProperty cssName unit a ->
            CustomProperty cssName unit (apply a)

        CustomColorProperty cssName a ->
            CustomColorProperty cssName (apply a)


applyTiming : Timing -> PropertyAnimation a -> PropertyAnimation a
applyTiming timing anim =
    { anim
        | elapsedMs = timing.elapsedMs
        , isComplete = timing.isComplete
        , totalDurationMs = timing.totalDurationMs
        , delayMs = timing.delayMs
    }


foldTiming : (Timing -> b) -> Animation -> b
foldTiming f anim =
    case anim of
        CustomProperty _ _ a ->
            f (toTiming a)

        CustomColorProperty _ a ->
            f (toTiming a)

        Opacity a ->
            f (toTiming a)

        PerspectiveOrigin _ a ->
            f (toTiming a)

        Rotate a ->
            f (toTiming a)

        Scale a ->
            f (toTiming a)

        Size _ a ->
            f (toTiming a)

        Skew a ->
            f (toTiming a)

        Translate _ a ->
            f (toTiming a)



-- ============================================================
-- PER-AXIS MERGE
-- ============================================================


{-| Replace only the touched axes of the existing animation with the
snapped animation's target value on those axes. Untouched axes keep the
existing animation's `start` / `end` so they continue interpolating with
the original timing and easing curve.

If the merged `start` equals the merged `end` across every axis the
existing animation had no work left to do on untouched axes, so the
fully stopped `snapped` animation is returned instead. The group's play
state will then collapse to `Complete`.

Multi-dimensional properties (`Translate`, `Rotate`, `Scale`, `Skew`,
`PerspectiveOrigin`, `Size`) all participate in per-axis merging. Other
property types are returned as the snapped animation unchanged, matching
the whole-property scoping the engine already applies.

-}
replaceAxes : Set String -> Animation -> Animation -> Animation
replaceAxes touchedAxes snapped existing =
    case ( snapped, existing ) of
        ( Translate _ snappedAnim, Translate units existingAnim ) ->
            mergeXYZ touchedAxes
                Translate.toRecord
                Translate.fromRecord
                snappedAnim
                existingAnim
                snapped
                (\anim -> Translate units anim)

        ( Rotate snappedAnim, Rotate existingAnim ) ->
            mergeXYZ touchedAxes
                Rotate.toRecord
                Rotate.fromRecord
                snappedAnim
                existingAnim
                snapped
                Rotate

        ( Scale snappedAnim, Scale existingAnim ) ->
            mergeXYZ touchedAxes
                Scale.toRecord
                Scale.fromRecord
                snappedAnim
                existingAnim
                snapped
                Scale

        ( Skew snappedAnim, Skew existingAnim ) ->
            mergeXY touchedAxes
                Skew.toRecord
                Skew.fromRecord
                snappedAnim
                existingAnim
                snapped
                Skew

        ( PerspectiveOrigin _ snappedAnim, PerspectiveOrigin units existingAnim ) ->
            mergeXY touchedAxes
                PerspectiveOrigin.toRecord
                PerspectiveOrigin.fromRecord
                snappedAnim
                existingAnim
                snapped
                (\anim -> PerspectiveOrigin units anim)

        ( Size _ snappedAnim, Size units existingAnim ) ->
            mergeWH touchedAxes
                Size.toRecord
                Size.fromRecord
                snappedAnim
                existingAnim
                snapped
                (\anim -> Size units anim)

        _ ->
            snapped


mergeXYZ :
    Set String
    -> (property -> { x : Float, y : Float, z : Float })
    -> ({ x : Float, y : Float, z : Float } -> property)
    -> PropertyAnimation property
    -> PropertyAnimation property
    -> Animation
    -> (PropertyAnimation property -> Animation)
    -> Animation
mergeXYZ touchedAxes toRec fromRec snappedAnim existingAnim snapped wrap =
    let
        target =
            toRec snappedAnim.end

        existingStart =
            toRec existingAnim.start

        existingEnd =
            toRec existingAnim.end

        pick axis fallback selector =
            if Set.member axis touchedAxes then
                selector target

            else
                fallback

        mergedStartRec =
            { x = pick "x" existingStart.x .x
            , y = pick "y" existingStart.y .y
            , z = pick "z" existingStart.z .z
            }

        mergedEndRec =
            { x = pick "x" existingEnd.x .x
            , y = pick "y" existingEnd.y .y
            , z = pick "z" existingEnd.z .z
            }
    in
    if mergedStartRec == mergedEndRec then
        snapped

    else
        wrap
            { existingAnim
                | start = fromRec mergedStartRec
                , end = fromRec mergedEndRec
            }


mergeXY :
    Set String
    -> (property -> { x : Float, y : Float })
    -> ({ x : Float, y : Float } -> property)
    -> PropertyAnimation property
    -> PropertyAnimation property
    -> Animation
    -> (PropertyAnimation property -> Animation)
    -> Animation
mergeXY touchedAxes toRec fromRec snappedAnim existingAnim snapped wrap =
    let
        target =
            toRec snappedAnim.end

        existingStart =
            toRec existingAnim.start

        existingEnd =
            toRec existingAnim.end

        pick axis fallback selector =
            if Set.member axis touchedAxes then
                selector target

            else
                fallback

        mergedStartRec =
            { x = pick "x" existingStart.x .x
            , y = pick "y" existingStart.y .y
            }

        mergedEndRec =
            { x = pick "x" existingEnd.x .x
            , y = pick "y" existingEnd.y .y
            }
    in
    if mergedStartRec == mergedEndRec then
        snapped

    else
        wrap
            { existingAnim
                | start = fromRec mergedStartRec
                , end = fromRec mergedEndRec
            }


mergeWH :
    Set String
    -> (property -> { width : Float, height : Float })
    -> ({ width : Float, height : Float } -> property)
    -> PropertyAnimation property
    -> PropertyAnimation property
    -> Animation
    -> (PropertyAnimation property -> Animation)
    -> Animation
mergeWH touchedAxes toRec fromRec snappedAnim existingAnim snapped wrap =
    let
        target =
            toRec snappedAnim.end

        existingStart =
            toRec existingAnim.start

        existingEnd =
            toRec existingAnim.end

        pick axis fallback selector =
            if Set.member axis touchedAxes then
                selector target

            else
                fallback

        mergedStartRec =
            { width = pick "width" existingStart.width .width
            , height = pick "height" existingStart.height .height
            }

        mergedEndRec =
            { width = pick "width" existingEnd.width .width
            , height = pick "height" existingEnd.height .height
            }
    in
    if mergedStartRec == mergedEndRec then
        snapped

    else
        wrap
            { existingAnim
                | start = fromRec mergedStartRec
                , end = fromRec mergedEndRec
            }
