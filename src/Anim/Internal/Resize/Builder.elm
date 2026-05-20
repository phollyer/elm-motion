module Anim.Internal.Resize.Builder exposing
    ( AnimGroupName
    , AxisBounds
    , AxisResult
    , Bounds
    , Builder
    , Entry
    , Position
    , applyAxis
    , applyAxisPosition
    , bounds
    , build
    , empty
    , getPerspectiveOrigin
    , getScale
    , getTranslate
    , getTranslatePosition
    , groups
    , isEmpty
    , merge
    , setPerspectiveOrigin
    , setScale
    , setTranslate
    , setTranslatePosition
    )

{-| Internal accumulator used by `Anim.Resize.Builder.Builder` (the public
opaque alias) and consumed by engine `onResize` functions.

A `Builder` is constructed by composing per-property `bounds` functions
exposed from property modules - e.g.

    Translate.bounds "box" bounds

Each call records a bounds directive against a specific anim group, so a single
builder can target many groups at once. Per-group group-wide defaults
may also be supplied via [`Anim.Resize.bounds`](Anim-Resize#bounds).

Resize behaviour is always proportional: endpoints track the new bounds,
the current value is proportionally remapped from the old range into the
new range, and the timing cursor's normalised progress is preserved.

-}

import Dict exposing (Dict)


{-| The name of an anim group a directive targets.
-}
type alias AnimGroupName =
    String


{-| One pending resize bounds directive for a single property (or the group
default).
-}
type alias Entry =
    { bounds : Bounds }


{-| Per-group accumulator. Adding a new supported property means
extending this record and providing matching `setX` / `getX` helpers.

`default` is the group-wide fallback applied to any supported property
on this group that has no explicit per-property entry.

-}
type alias GroupEntries =
    { default : Maybe Entry
    , translate : Maybe Entry
    , scale : Maybe Entry
    , perspectiveOrigin : Maybe Entry
    , translatePosition : Maybe Position
    }


type alias AxisBounds =
    { min : Float, max : Float }


{-| Per-axis one-shot position snap for a static axis (an axis where the
property's `start` equals its `end`).

Each axis is `Just newPos` to snap that axis, or `Nothing` to leave it
untouched. Engines apply this AFTER any bounds directive, and only on
static axes - an animating axis (`start /= end`) is left unchanged
because the next interpolation frame would overwrite a current-only
snap.

-}
type alias Position =
    { x : Maybe Float
    , y : Maybe Float
    , z : Maybe Float
    }


{-| Per-axis bounds describing the new container size. An axis left as
`Nothing` is untouched.

    { x = Just { min = 0, max = newWidth - boxSize }
    , y = Nothing
    , z = Nothing
    }

-}
type alias Bounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    , z : Maybe AxisBounds
    }


{-| Opaque accumulator. Indexed by anim group name so a single builder
can carry directives for many groups in one engine `onResize` call.
-}
type Builder
    = Builder (Dict AnimGroupName GroupEntries)


{-| Empty builder with no resize directives for any group.
-}
empty : Builder
empty =
    Builder Dict.empty


emptyEntries : GroupEntries
emptyEntries =
    { default = Nothing
    , translate = Nothing
    , scale = Nothing
    , perspectiveOrigin = Nothing
    , translatePosition = Nothing
    }


{-| Apply a builder transformer (composed property `onResize` calls) to
the empty builder.
-}
build : (Builder -> Builder) -> Builder
build fn =
    fn empty


{-| Right-biased merge of two builders. For each anim group present in
both builders, per-property entries from the right builder override those
from the left. Used by engines to fold incoming resize directives into a
cached builder so re-applying the most recent bounds doesn't require
another resize event.
-}
merge : Builder -> Builder -> Builder
merge (Builder left) (Builder right) =
    Builder
        (Dict.merge
            Dict.insert
            (\name leftEntries rightEntries -> Dict.insert name (mergeEntries leftEntries rightEntries))
            Dict.insert
            left
            right
            Dict.empty
        )


mergeEntries : GroupEntries -> GroupEntries -> GroupEntries
mergeEntries left right =
    { default = orMaybe right.default left.default
    , translate = orMaybe right.translate left.translate
    , scale = orMaybe right.scale left.scale
    , perspectiveOrigin = orMaybe right.perspectiveOrigin left.perspectiveOrigin
    , translatePosition = orMaybe right.translatePosition left.translatePosition
    }


orMaybe : Maybe a -> Maybe a -> Maybe a
orMaybe preferred fallback =
    case preferred of
        Just _ ->
            preferred

        Nothing ->
            fallback


updateEntries : (GroupEntries -> GroupEntries) -> Maybe GroupEntries -> Maybe GroupEntries
updateEntries fn maybeEntries =
    Just (fn (Maybe.withDefault emptyEntries maybeEntries))


{-| Record the group-wide default bounds directive used as a fallback for any
property on this group that has no explicit entry.
-}
bounds : AnimGroupName -> Bounds -> Builder -> Builder
bounds name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | default = Just { bounds = bounds_ } }))
            d
        )


{-| Record a translate-axis resize bounds directive for the given anim group.
-}
setTranslate : AnimGroupName -> Bounds -> Builder -> Builder
setTranslate name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | translate = Just { bounds = bounds_ } }))
            d
        )


{-| Read the effective translate directive for the given anim group: the
explicit per-property entry if present, otherwise the group-wide default.
-}
getTranslate : AnimGroupName -> Builder -> Maybe Entry
getTranslate name (Builder d) =
    Dict.get name d
        |> Maybe.andThen
            (\e ->
                case e.translate of
                    Just _ ->
                        e.translate

                    Nothing ->
                        e.default
            )


{-| Record a one-shot translate-position snap for the given anim group.
Applied after any bounds directive; only static axes are affected.
-}
setTranslatePosition : AnimGroupName -> Position -> Builder -> Builder
setTranslatePosition name pos (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | translatePosition = Just pos }))
            d
        )


{-| Read the translate-position snap recorded for the given anim group, if any.
-}
getTranslatePosition : AnimGroupName -> Builder -> Maybe Position
getTranslatePosition name (Builder d) =
    Dict.get name d
        |> Maybe.andThen .translatePosition


{-| Record a scale-axis resize bounds directive for the given anim group.
-}
setScale : AnimGroupName -> Bounds -> Builder -> Builder
setScale name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | scale = Just { bounds = bounds_ } }))
            d
        )


{-| Read the effective scale directive for the given anim group: the
explicit per-property entry if present, otherwise the group-wide default.
-}
getScale : AnimGroupName -> Builder -> Maybe Entry
getScale name (Builder d) =
    Dict.get name d
        |> Maybe.andThen
            (\e ->
                case e.scale of
                    Just _ ->
                        e.scale

                    Nothing ->
                        e.default
            )


{-| Record a perspective-origin resize bounds directive for the given anim group.
-}
setPerspectiveOrigin : AnimGroupName -> Bounds -> Builder -> Builder
setPerspectiveOrigin name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\entries -> { entries | perspectiveOrigin = Just { bounds = bounds_ } }))
            d
        )


{-| Read the effective perspective-origin directive for the given anim group:
the explicit per-property entry if present, otherwise the group-wide default.
-}
getPerspectiveOrigin : AnimGroupName -> Builder -> Maybe Entry
getPerspectiveOrigin name (Builder d) =
    Dict.get name d
        |> Maybe.andThen
            (\e ->
                case e.perspectiveOrigin of
                    Just _ ->
                        e.perspectiveOrigin

                    Nothing ->
                        e.default
            )


{-| All anim group names that have at least one directive recorded
against them. Engines iterate over this list to apply directives.
-}
groups : Builder -> List AnimGroupName
groups (Builder d) =
    Dict.keys d



-- ============================================================
-- AXIS MATH
-- ============================================================


{-| Per-axis result of resizing one axis.

  - `start` / `end` are the new extremes for the current leg (so the engine's
    alternate-swap on iteration boundary continues to work for looping anims).
  - `current` is the new visual value the box should snap to.

-}
type alias AxisResult =
    { start : Float
    , end : Float
    , current : Float
    }


{-| Convenience predicate: a resize directive with no populated axes is
treated as a no-op by engines.
-}
isEmpty : Bounds -> Bool
isEmpty bounds_ =
    bounds_.x == Nothing && bounds_.y == Nothing && bounds_.z == Nothing


{-| Compute new per-axis start / end / current under proportional resize.

`maybeNewBounds = Nothing` leaves the axis untouched.

`maybePrevBounds` is the bounds last applied to this axis (i.e. the viewport
range that `currentV` is currently positioned within). When `Just`, the
current value is proportionally remapped from the previous viewport range
into the new viewport range. When `Nothing` (first resize for this axis,
no prior bounds recorded) the leg endpoints `startV..endV` are used as a
fallback reference range - correct when the user's animation endpoints
align with the original viewport extents.

Using the previous bounds (rather than the current leg endpoints) is what
preserves visual position across **successive** resizes during a single
in-flight one-shot leg: after the first resize chops the leg to
`(newCurrent, legEnd)`, the leg range no longer represents the viewport
range, so a leg-derived `oldRange` would compress the proportional remap.

`isLooping` controls whether the result preserves full extremes (so that
ping-pong continues to span the full new range) or shrinks to a single
leg (one-shot animations finish at the new target).

-}
applyAxis :
    Bool
    -> Maybe AxisBounds
    -> Maybe AxisBounds
    -> Float
    -> Float
    -> Float
    -> AxisResult
applyAxis isLooping maybePrevBounds maybeNewBounds startV endV currentV =
    case maybeNewBounds of
        Nothing ->
            { start = startV, end = endV, current = currentV }

        Just b ->
            if startV == endV then
                let
                    clamped =
                        clamp b.min b.max currentV
                in
                { start = clamped, end = clamped, current = clamped }

            else
                let
                    forward =
                        startV <= endV

                    ( legStart, legEnd ) =
                        if forward then
                            ( b.min, b.max )

                        else
                            ( b.max, b.min )

                    ( oldMin, oldRange ) =
                        case maybePrevBounds of
                            Just pb ->
                                ( pb.min, pb.max - pb.min )

                            Nothing ->
                                ( Basics.min startV endV
                                , abs (endV - startV)
                                )

                    newRange =
                        b.max - b.min

                    newCurrent =
                        if oldRange == 0 then
                            clamp b.min b.max currentV

                        else
                            b.min + ((currentV - oldMin) / oldRange) * newRange
                in
                if isLooping then
                    { start = legStart
                    , end = legEnd
                    , current = newCurrent
                    }

                else
                    { start = newCurrent
                    , end = legEnd
                    , current = newCurrent
                    }


{-| Apply a one-shot position snap to one axis.

  - `Nothing` -> axis unchanged.
  - `Just p` on a static axis (`startV == endV`) -> snap all three of
    `start`, `end`, `current` to `p`.
  - `Just p` on an animating axis (`startV /= endV`) -> axis unchanged.
    The next interpolation frame would overwrite a current-only snap,
    so `position` is meaningless on an animating axis. Callers should
    use `bounds` (with proportional remap) to retarget animating axes.

-}
applyAxisPosition :
    Maybe Float
    -> Float
    -> Float
    -> Float
    -> AxisResult
applyAxisPosition maybeNewPos startV endV currentV =
    case maybeNewPos of
        Nothing ->
            { start = startV, end = endV, current = currentV }

        Just newPos ->
            if startV == endV then
                { start = newPos, end = newPos, current = newPos }

            else
                { start = startV, end = endV, current = currentV }
