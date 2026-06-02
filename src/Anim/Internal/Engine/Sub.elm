module Anim.Internal.Engine.Sub exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg(..)
    , AnimState
    , ControlEvent(..)
    , EngineBuilder
    , FreezeProperty
    , TickEvent(..)
    , TimelineBuilder
    , allComplete
    , alternate
    , animate
    , anyRunning
    , attributes
    , calculateProgress
    , cssUnit
    , cssUnitX
    , cssUnitY
    , cssUnitZ
    , delay
    , discreteEntry
    , discreteExit
    , duration
    , easing
    , freezeAxes
    , freezeRotate
    , freezeScale
    , freezeSkew
    , freezeTranslate
    , getColorPropertyCurrent
    , getColorPropertyEnd
    , getColorPropertyRange
    , getColorPropertyStart
    , getOpacityCurrent
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getPerspectiveOriginCurrent
    , getPerspectiveOriginEnd
    , getPerspectiveOriginRange
    , getPerspectiveOriginStart
    , getProgress
    , getPropertyCurrent
    , getPropertyEnd
    , getPropertyRange
    , getPropertyStart
    , getRotateCurrent
    , getRotateEnd
    , getRotateRange
    , getRotateStart
    , getScaleCurrent
    , getScaleEnd
    , getScaleRange
    , getScaleStart
    , getSizeCurrent
    , getSizeEnd
    , getSizeRange
    , getSizeStart
    , getSkewCurrent
    , getSkewEnd
    , getSkewRange
    , getSkewStart
    , getTranslateCurrent
    , getTranslateEnd
    , getTranslateRange
    , getTranslateStart
    , init
    , interpolateEasedProgress
    , interpolateFloat
    , isComplete
    , isRunning
    , iterations
    , loopForever
    , onResize
    , pause
    , reset
    , restart
    , resume
    , retarget
    , speed
    , spring
    , stop
    , subscriptions
    , transformOrder
    , unfreezeAxes
    , update
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Engine.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Sub.Animation as Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Sub.Animations as Animations
import Anim.Internal.Engine.Sub.Generator as Generator
import Anim.Internal.Engine.Sub.Interpolation as Interpolation
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Resize.Builder as ResizeBuilder exposing (Bounds)
import Anim.Internal.Unit as InternalUnit
import Anim.Unit exposing (Unit(..))
import Browser.Events
import Dict
import Html
import Html.Attributes
import Motion.Easing exposing (Easing(..))
import Motion.Spring exposing (Spring)
import Set exposing (Set)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type AnimState
    = AnimState
        { builder : EngineBuilder
        , subscriptionsActive : Bool
        , pendingControlEvents : List ControlEvent
        , lastResize : Dict.Dict ( AnimGroupName, String ) Bounds
        }
        (AnimGroups AnimGroup)


type alias AnimBuilder eng =
    Builder.AnimBuilder eng


type alias TimelineBuilder engine =
    Builder.AnimBuilder engine


type alias EngineBuilder =
    Builder.AnimBuilder Builder.ForSub


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (EngineBuilder -> EngineBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , subscriptionsActive = False
                , pendingControlEvents = []
                , lastResize = Dict.empty
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder

                initGroup : AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
                initGroup _ { properties } =
                    Generator.init
                        (Builder.getDiscreteEntryProperties builder)
                        (Builder.getDiscreteExitProperties builder)
                        properties
            in
            AnimState
                { subscriptionsActive = False
                , builder =
                    builder
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                , pendingControlEvents = []
                , lastResize = Dict.empty
                }
                (AnimGroups.map initGroup animGroups)



-- ============================================================
-- TRIGGER
-- ============================================================


animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate (AnimState state animGroups) build =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates (setSnapshot animGroups)
                |> build

        processed =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup animGroupName config =
            Generator.generateAnimation
                processed.iterations
                processed.animationDirection
                config.transformOrder
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                (AnimGroups.get animGroupName animGroups)
                config.properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existing ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.addAnimation (AnimGroup.getAnimations existing) animGroup)
                        acc

        startedEvents =
            AnimGroups.names processed.groups
                |> List.map Started

        nextAnimGroups =
            processed.groups
                |> AnimGroups.map generateAnimGroup
                |> AnimGroups.foldl insertAnimGroup animGroups

        nextState =
            AnimState
                { subscriptionsActive = True
                , builder =
                    builder
                        |> Builder.addAnimationToHistory processed
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                , pendingControlEvents = state.pendingControlEvents ++ startedEvents
                , lastResize = state.lastResize
                }
                nextAnimGroups
    in
    nextState


setSnapshot : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : PropertyBaselines }
setSnapshot anims =
    AnimGroups.map (\_ anim -> { propertySnapshot = extractElementCurrentStates anim }) anims


{-| Snap the named anim groups to the targets described by `build`, with no
animation.

For every property mentioned in `build`, the engine writes the target
value as the new current position and stops that property's interpolation.
Builder timing fields (`duration`, `delay`, `easing`, `spring`) are
accepted but ignored — there is no animation to apply them to.

For `Translate`, only the axes mentioned in `build` are snapped. Untouched
axes keep their in-flight start / end and continue interpolating along the
original easing curve, so a per-axis retarget redirects one axis while the
others carry on. Other property types are snapped as a whole.

Properties on the same anim group that are not mentioned in `build` keep
running with their existing state.

Emits a `Cancelled` [ControlEvent](#ControlEvent) for every animGroup that
was previously `Running` and is touched by the build. No `Started` events
are emitted.

Use `retarget` to instantly reposition an element — e.g. after a layout
change, a teleport, or to seed a new starting position before a follow-up
`animate` call. For a smooth redirect from the current position toward a
new target, use [animate](#animate) with a factored builder instead.

-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget (AnimState state animGroups) build =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates (setSnapshot animGroups)
                |> build

        processed =
            Builder.process builder

        touchedAxesByGroup =
            Builder.getAllTouchedAxes builder

        touchedAxesFor : AnimGroupName -> Dict.Dict String (Set String)
        touchedAxesFor groupName =
            Dict.foldl
                (\( g, propName ) axes acc ->
                    if g == groupName then
                        Dict.insert propName axes acc

                    else
                        acc
                )
                Dict.empty
                touchedAxesByGroup

        touchedNames =
            AnimGroups.names processed.groups

        cancelledEvents =
            touchedNames
                |> List.filterMap
                    (\animGroupName ->
                        AnimGroups.get animGroupName animGroups
                            |> Maybe.andThen
                                (\existing ->
                                    if AnimGroup.isRunning existing then
                                        Just (Cancelled animGroupName (overallProgress existing))

                                    else
                                        Nothing
                                )
                    )

        snapAnimations : AnimGroup -> Animations.Animations
        snapAnimations animGroup =
            AnimGroup.getAnimations animGroup
                |> Animations.map (\_ -> Animation.stop)

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup animGroupName config =
            Generator.generateAnimation
                processed.iterations
                processed.animationDirection
                config.transformOrder
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                (AnimGroups.get animGroupName animGroups)
                config.properties

        insertSnap : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertSnap animGroupName freshAnimGroup acc =
            let
                snapped =
                    AnimGroup.setAnimations (snapAnimations freshAnimGroup) freshAnimGroup
            in
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.setPlayState PlayState.Complete snapped)
                        acc

                Just existing ->
                    -- Per touched property: if the existing animation is
                    -- still in flight, keep its timing / easing curve and
                    -- pin only the touched axes to the new target. Untouched
                    -- axes carry on toward their original end. Properties
                    -- not mentioned in the build keep running as-is. A Paused
                    -- group stays Paused; otherwise the merged group is
                    -- Running while any animation has work left, else
                    -- Complete.
                    let
                        groupTouchedAxes =
                            touchedAxesFor animGroupName

                        existingAnimations =
                            AnimGroup.getAnimations existing

                        mergedTouched =
                            AnimGroup.getAnimations snapped
                                |> Animations.map
                                    (\propName snappedAnim ->
                                        case Animations.get propName existingAnimations of
                                            Just existingAnim ->
                                                if Animation.foldTiming .isComplete existingAnim then
                                                    snappedAnim

                                                else
                                                    case Dict.get propName groupTouchedAxes of
                                                        Just axes ->
                                                            Animation.replaceAxes axes snappedAnim existingAnim

                                                        Nothing ->
                                                            snappedAnim

                                            Nothing ->
                                                snappedAnim
                                    )

                        mergedAnimations =
                            Animations.add existingAnimations mergedTouched

                        merged =
                            AnimGroup.setAnimations mergedAnimations snapped
                    in
                    AnimGroups.insert animGroupName
                        (AnimGroup.setPlayState
                            (mergedPlayState (AnimGroup.getPlayState existing) merged)
                            merged
                        )
                        acc

        mergedPlayState : PlayState.PlayState -> AnimGroup -> PlayState.PlayState
        mergedPlayState existingPlayState merged =
            if PlayState.isPaused existingPlayState then
                PlayState.Paused

            else if hasIncompleteAnimation merged then
                PlayState.Running

            else
                PlayState.Complete

        hasIncompleteAnimation : AnimGroup -> Bool
        hasIncompleteAnimation animGroup =
            AnimGroup.getAnimations animGroup
                |> Animations.foldl
                    (\_ anim acc -> acc || not (Animation.foldTiming .isComplete anim))
                    False

        nextAnimGroups =
            processed.groups
                |> AnimGroups.map generateAnimGroup
                |> AnimGroups.foldl insertSnap animGroups

        nextSubscriptionsActive =
            nextAnimGroups
                |> AnimGroups.groups
                |> List.any AnimGroup.isRunning
    in
    AnimState
        { subscriptionsActive = nextSubscriptionsActive
        , builder =
            builder
                |> Builder.addRetargetToHistory processed
                |> Builder.clearAnimData
        , pendingControlEvents = state.pendingControlEvents ++ cancelledEvents
        , lastResize = state.lastResize
        }
        nextAnimGroups



-- ============================================================
-- EVENTS
-- ============================================================


type alias Progress =
    Float


{-| Events generated naturally by animation frame ticks.
-}
type TickEvent
    = Progress AnimGroupName Progress
    | Ended AnimGroupName
    | Iteration AnimGroupName Int


{-| Events generated by control function calls (animate, stop, pause, etc.).
-}
type ControlEvent
    = Started AnimGroupName
    | Cancelled AnimGroupName Progress
    | Paused AnimGroupName Progress
    | Resumed AnimGroupName
    | Restarted AnimGroupName


type AnimEvent
    = Tick TickEvent
    | Control ControlEvent



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = AnimationFrame Float


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state animGroups) =
    case msg of
        AnimationFrame deltaMs ->
            let
                ( groups, events ) =
                    animGroups
                        |> AnimGroups.toList
                        |> List.map (tick deltaMs)
                        |> List.unzip

                updatedGroups =
                    AnimGroups.fromList groups

                allEvents =
                    List.concat events

                emitProgress =
                    Builder.getEmitProgress state.builder

                filteredEvents =
                    if emitProgress then
                        allEvents

                    else
                        List.filter
                            (\e ->
                                case e of
                                    Progress _ _ ->
                                        False

                                    _ ->
                                        True
                            )
                            allEvents

                stillRunning =
                    updatedGroups
                        |> AnimGroups.groups
                        |> List.any AnimGroup.isRunning
            in
            ( AnimState
                { subscriptionsActive = stillRunning
                , builder = state.builder
                , pendingControlEvents = []
                , lastResize = state.lastResize
                }
                updatedGroups
            , List.map Control state.pendingControlEvents
                ++ List.map Tick filteredEvents
            )


tick : Float -> ( AnimGroupName, AnimGroup ) -> ( ( AnimGroupName, AnimGroup ), List TickEvent )
tick deltaMs ( animGroupName, animGroup ) =
    let
        ( newAnimGroup, events ) =
            handleTick deltaMs animGroupName animGroup
    in
    ( ( animGroupName, newAnimGroup ), events )


handleTick : Float -> AnimGroupName -> AnimGroup -> ( AnimGroup, List TickEvent )
handleTick deltaMs animGroupName animGroup =
    if AnimGroup.isPaused animGroup then
        ( animGroup, [] )

    else
        let
            updatedAnimations =
                animGroup
                    |> AnimGroup.getAnimations
                    |> Animations.map (\_ -> updateTiming deltaMs)

            allPropertiesComplete =
                updatedAnimations
                    |> Animations.list
                    |> List.all (Animation.foldTiming .isComplete)
        in
        if allPropertiesComplete && AnimGroup.isRunning animGroup then
            -- Properties just finished - check if we need to iterate
            let
                shouldIterate =
                    case AnimGroup.getIterations animGroup of
                        Builder.Infinite ->
                            True

                        Builder.Times totalIterations ->
                            AnimGroup.getCurrentIteration animGroup < totalIterations

                        Builder.Once ->
                            False
            in
            if shouldIterate then
                iterateAnimGroup animGroupName animGroup updatedAnimations

            else
                ( animGroup
                    |> AnimGroup.setAnimations updatedAnimations
                    |> AnimGroup.setPlayState PlayState.Complete
                , [ Ended animGroupName ]
                )

        else
            let
                updatedAnimGroup =
                    AnimGroup.setAnimations updatedAnimations animGroup
            in
            -- Not all properties complete yet (or already complete)
            ( updatedAnimGroup
            , if AnimGroup.isRunning updatedAnimGroup then
                [ Progress animGroupName (overallProgress updatedAnimGroup) ]

              else
                []
            )


updateTiming : Float -> Animation -> Animation
updateTiming deltaMs =
    Animation.mapTiming
        (\timing ->
            if timing.isComplete then
                timing

            else
                let
                    newElapsedMs =
                        timing.elapsedMs + deltaMs

                    animationElapsedMs =
                        max 0 (newElapsedMs - timing.delayMs)
                in
                { timing
                    | elapsedMs = newElapsedMs
                    , isComplete = animationElapsedMs >= timing.totalDurationMs
                }
        )


iterateAnimGroup : AnimGroupName -> AnimGroup -> Animations.Animations -> ( AnimGroup, List TickEvent )
iterateAnimGroup animGroupName animGroup animations =
    let
        nextIteration =
            AnimGroup.getCurrentIteration animGroup + 1

        shouldReverse =
            case AnimGroup.getAnimationDirection animGroup of
                Builder.Alternate ->
                    -- `Animation.reverse` physically swaps each property's
                    -- start/end. To produce a true ping-pong we must swap on
                    -- every iteration boundary so the next leg plays in the
                    -- opposite direction to the leg that just finished.
                    True

                Builder.Normal ->
                    False

        anims =
            animations
                |> Animations.map
                    (\_ anim ->
                        let
                            reversed =
                                if shouldReverse then
                                    Animation.reverse anim

                                else
                                    anim
                        in
                        Animation.reset reversed
                    )
    in
    ( animGroup
        |> AnimGroup.setAnimations anims
        |> AnimGroup.setCurrentIteration nextIteration
        |> AnimGroup.setPlayState PlayState.Running
    , [ Iteration animGroupName nextIteration ]
    )



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state _) =
    if state.subscriptionsActive then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



-- ============================================================
-- RESIZE
-- ============================================================


{-| Adjust the in-flight properties of every anim group referenced by the
resize builder to match new bounding ranges.

Properties without a bounds entry for a given group are left alone. Axes
set to `Nothing` are left alone. Groups that do not exist are silently
skipped.

-}
onResize : AnimState -> (AnimBuilder Builder.ForResizeSub -> AnimBuilder Builder.ForResizeSub) -> AnimState
onResize (AnimState state animGroups) buildResize =
    let
        processed =
            Builder.init []
                |> buildResize
                |> Builder.process
    in
    AnimGroups.foldl applyGroupResize (AnimState state animGroups) processed.groups


applyGroupResize : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimState -> AnimState
applyGroupResize animGroupName cfg st =
    List.foldl (applyBoundsEntry animGroupName)
        st
        (Builder.partitionForResize cfg.properties).bounds


applyBoundsEntry : AnimGroupName -> ( Builder.ProcessedPropertyConfig, Builder.AxisRanges ) -> AnimState -> AnimState
applyBoundsEntry animGroupName ( prop, ranges ) ((AnimState state _) as st) =
    let
        propKey =
            Builder.processedPropertyType prop

        cacheKey =
            ( animGroupName, propKey )

        prev =
            Dict.get cacheKey state.lastResize
                |> Maybe.withDefault emptyBounds

        next =
            case propKey of
                "translate" ->
                    applyTranslateResize animGroupName prev ranges st

                "scale" ->
                    applyScaleResize animGroupName prev ranges st

                "perspectiveOrigin" ->
                    applyPerspectiveOriginResize animGroupName prev ranges st

                "size" ->
                    applySizeResize animGroupName prev ranges st

                _ ->
                    st

        (AnimState nextState nextGroups) =
            next
    in
    AnimState
        { nextState | lastResize = Dict.insert cacheKey ranges nextState.lastResize }
        nextGroups


emptyBounds : Bounds
emptyBounds =
    { x = Nothing, y = Nothing, z = Nothing }


applyTranslateResize : AnimGroupName -> Bounds -> Bounds -> AnimState -> AnimState
applyTranslateResize animGroupName previousBounds bounds (AnimState state animGroups) =
    if ResizeBuilder.isEmpty bounds then
        AnimState state animGroups

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                AnimState state animGroups

            Just animGroup ->
                let
                    isLooping =
                        case AnimGroup.getIterations animGroup of
                            Builder.Once ->
                                False

                            _ ->
                                True

                    isPaused =
                        AnimGroup.isPaused animGroup

                    updatedAnimations =
                        AnimGroup.getAnimations animGroup
                            |> Animations.map
                                (\_ anim ->
                                    case anim of
                                        Translate units cfg ->
                                            Translate units (resizeTranslate units previousBounds bounds isLooping isPaused cfg)

                                        _ ->
                                            anim
                                )

                    updatedGroup =
                        AnimGroup.setAnimations updatedAnimations animGroup

                    updatedAnimGroups =
                        AnimGroups.insert animGroupName updatedGroup animGroups
                in
                AnimState
                    { state
                        | subscriptionsActive =
                            updatedAnimGroups
                                |> AnimGroups.groups
                                |> List.any AnimGroup.isRunning
                    }
                    updatedAnimGroups


{-| Resize the in-memory translate animation to match new bounds.
-}
resizeTranslate : InternalUnit.ResolvedCssUnitAxes -> Bounds -> Bounds -> Bool -> Bool -> PropertyAnimation Translate -> PropertyAnimation Translate
resizeTranslate units previousBounds bounds isLooping isPaused cfg =
    let
        oldStart =
            Translate.toRecord cfg.start

        oldEnd =
            Translate.toRecord cfg.end

        rx =
            applyAxisLegForUnit units.x previousBounds.x bounds.x oldStart.x oldEnd.x

        ry =
            applyAxisLegForUnit units.y previousBounds.y bounds.y oldStart.y oldEnd.y

        rz =
            applyAxisLegForUnit units.z previousBounds.z bounds.z oldStart.z oldEnd.z

        newStart =
            Translate.fromRecord { x = rx.start, y = ry.start, z = rz.start }

        newEnd =
            Translate.fromRecord { x = rx.end, y = ry.end, z = rz.end }

        oldDistance =
            Translate.distance cfg.start cfg.end

        newLegDistance =
            Translate.distance newStart newEnd
    in
    if cfg.isComplete && not isLooping then
        -- Completed one-shot: stay complete, pinned to the rescaled endpoint.
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else if newLegDistance == 0 && not (isPaused && not isLooping) then
        -- Resize collapsed the leg to zero length. Auto-complete - except
        -- when the user has paused a one-shot, where we keep the pause intact.
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else
        preserveProgress
            { cfg = cfg
            , newStart = newStart
            , newEnd = newEnd
            , oldDistance = oldDistance
            , newLegDistance = newLegDistance
            }


applyAxisLeg :
    Maybe ResizeBuilder.AxisBounds
    -> Maybe ResizeBuilder.AxisBounds
    -> Float
    -> Float
    -> { start : Float, end : Float }
applyAxisLeg maybePrevBounds maybeNewBounds startV endV =
    let
        result =
            ResizeBuilder.applyAxis maybePrevBounds maybeNewBounds startV endV startV
    in
    { start = result.start, end = result.end }


applyAxisLegForUnit : Unit -> Maybe ResizeBuilder.AxisBounds -> Maybe ResizeBuilder.AxisBounds -> Float -> Float -> { start : Float, end : Float }
applyAxisLegForUnit unit maybePrevBounds maybeNewBounds startV endV =
    if unit == Px then
        applyAxisLeg maybePrevBounds maybeNewBounds startV endV

    else
        { start = startV, end = endV }


{-| Rescale an in-flight `PropertyAnimation` so that the elapsed
fraction of the new leg matches the elapsed fraction of the old leg.
-}
preserveProgress :
    { cfg : PropertyAnimation a
    , newStart : a
    , newEnd : a
    , oldDistance : Float
    , newLegDistance : Float
    }
    -> PropertyAnimation a
preserveProgress { cfg, newStart, newEnd, oldDistance, newLegDistance } =
    let
        scale =
            if oldDistance > 0 then
                newLegDistance / oldDistance

            else
                1

        newTotalDuration =
            if cfg.totalDurationMs > 0 then
                scale * cfg.totalDurationMs

            else
                cfg.totalDurationMs

        newElapsedMs =
            scale * cfg.elapsedMs
    in
    { cfg
        | start = newStart
        , end = newEnd
        , totalDurationMs = newTotalDuration
        , elapsedMs = newElapsedMs
        , isComplete = False
    }


{-| Dispatch a translate-position snap to the group's translate animation, if it has one.
-}
applyScaleResize : AnimGroupName -> Bounds -> Bounds -> AnimState -> AnimState
applyScaleResize animGroupName previousBounds bounds (AnimState state animGroups) =
    if ResizeBuilder.isEmpty bounds then
        AnimState state animGroups

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                AnimState state animGroups

            Just animGroup ->
                let
                    isLooping =
                        case AnimGroup.getIterations animGroup of
                            Builder.Once ->
                                False

                            _ ->
                                True

                    isPaused =
                        AnimGroup.isPaused animGroup

                    updatedAnimations =
                        AnimGroup.getAnimations animGroup
                            |> Animations.map
                                (\_ anim ->
                                    case anim of
                                        Scale cfg ->
                                            Scale (resizeScale previousBounds bounds isLooping isPaused cfg)

                                        _ ->
                                            anim
                                )

                    updatedGroup =
                        AnimGroup.setAnimations updatedAnimations animGroup

                    updatedAnimGroups =
                        AnimGroups.insert animGroupName updatedGroup animGroups
                in
                AnimState
                    { state
                        | subscriptionsActive =
                            updatedAnimGroups
                                |> AnimGroups.groups
                                |> List.any AnimGroup.isRunning
                    }
                    updatedAnimGroups


{-| Resize the in-memory scale animation to match new bounds.
-}
resizeScale : Bounds -> Bounds -> Bool -> Bool -> PropertyAnimation Scale -> PropertyAnimation Scale
resizeScale previousBounds bounds isLooping isPaused cfg =
    let
        oldStart =
            Scale.toRecord cfg.start

        oldEnd =
            Scale.toRecord cfg.end

        rx =
            applyAxisLeg previousBounds.x bounds.x oldStart.x oldEnd.x

        ry =
            applyAxisLeg previousBounds.y bounds.y oldStart.y oldEnd.y

        rz =
            applyAxisLeg previousBounds.z bounds.z oldStart.z oldEnd.z

        newStart =
            Scale.fromRecord { x = rx.start, y = ry.start, z = rz.start }

        newEnd =
            Scale.fromRecord { x = rx.end, y = ry.end, z = rz.end }

        oldDistance =
            Scale.distance cfg.start cfg.end

        newLegDistance =
            Scale.distance newStart newEnd
    in
    if cfg.isComplete && not isLooping then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else if newLegDistance == 0 && not (isPaused && not isLooping) then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else
        preserveProgress
            { cfg = cfg
            , newStart = newStart
            , newEnd = newEnd
            , oldDistance = oldDistance
            , newLegDistance = newLegDistance
            }


{-| Dispatch a perspective-origin position snap to the group's perspective-origin animation, if it has one.
-}
applyPerspectiveOriginResize : AnimGroupName -> Bounds -> Bounds -> AnimState -> AnimState
applyPerspectiveOriginResize animGroupName previousBounds bounds (AnimState state animGroups) =
    if ResizeBuilder.isEmpty bounds then
        AnimState state animGroups

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                AnimState state animGroups

            Just animGroup ->
                let
                    isLooping =
                        case AnimGroup.getIterations animGroup of
                            Builder.Once ->
                                False

                            _ ->
                                True

                    isPaused =
                        AnimGroup.isPaused animGroup

                    updatedAnimations =
                        AnimGroup.getAnimations animGroup
                            |> Animations.map
                                (\_ anim ->
                                    case anim of
                                        PerspectiveOrigin units cfg ->
                                            PerspectiveOrigin units (resizePerspectiveOrigin units previousBounds bounds isLooping isPaused cfg)

                                        _ ->
                                            anim
                                )

                    updatedGroup =
                        AnimGroup.setAnimations updatedAnimations animGroup

                    updatedAnimGroups =
                        AnimGroups.insert animGroupName updatedGroup animGroups
                in
                AnimState
                    { state
                        | subscriptionsActive =
                            updatedAnimGroups
                                |> AnimGroups.groups
                                |> List.any AnimGroup.isRunning
                    }
                    updatedAnimGroups


resizePerspectiveOrigin : InternalUnit.ResolvedCssUnitAxes -> Bounds -> Bounds -> Bool -> Bool -> PropertyAnimation PerspectiveOrigin -> PropertyAnimation PerspectiveOrigin
resizePerspectiveOrigin units previousBounds bounds isLooping isPaused cfg =
    let
        oldStart =
            PerspectiveOrigin.toRecord cfg.start

        oldEnd =
            PerspectiveOrigin.toRecord cfg.end

        rx =
            applyAxisLegForUnit units.x previousBounds.x bounds.x oldStart.x oldEnd.x

        ry =
            applyAxisLegForUnit units.y previousBounds.y bounds.y oldStart.y oldEnd.y

        newStart =
            PerspectiveOrigin.fromRecord { x = rx.start, y = ry.start }

        newEnd =
            PerspectiveOrigin.fromRecord { x = rx.end, y = ry.end }

        oldDistance =
            PerspectiveOrigin.distance cfg.start cfg.end

        newLegDistance =
            PerspectiveOrigin.distance newStart newEnd
    in
    if cfg.isComplete && not isLooping then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else if newLegDistance == 0 && not (isPaused && not isLooping) then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else
        preserveProgress
            { cfg = cfg
            , newStart = newStart
            , newEnd = newEnd
            , oldDistance = oldDistance
            , newLegDistance = newLegDistance
            }


{-| Dispatch a size remap to the group's size animation, if it has one.
-}
applySizeResize : AnimGroupName -> Bounds -> Bounds -> AnimState -> AnimState
applySizeResize animGroupName previousBounds bounds (AnimState state animGroups) =
    if ResizeBuilder.isEmpty bounds then
        AnimState state animGroups

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                AnimState state animGroups

            Just animGroup ->
                let
                    isLooping =
                        case AnimGroup.getIterations animGroup of
                            Builder.Once ->
                                False

                            _ ->
                                True

                    isPaused =
                        AnimGroup.isPaused animGroup

                    updatedAnimations =
                        AnimGroup.getAnimations animGroup
                            |> Animations.map
                                (\_ anim ->
                                    case anim of
                                        Size units cfg ->
                                            Size units (resizeSize units previousBounds bounds isLooping isPaused cfg)

                                        _ ->
                                            anim
                                )

                    updatedGroup =
                        AnimGroup.setAnimations updatedAnimations animGroup

                    updatedAnimGroups =
                        AnimGroups.insert animGroupName updatedGroup animGroups
                in
                AnimState
                    { state
                        | subscriptionsActive =
                            updatedAnimGroups
                                |> AnimGroups.groups
                                |> List.any AnimGroup.isRunning
                    }
                    updatedAnimGroups


{-| Resize the in-memory size animation to match new bounds. Width is
mapped to the X axis of the bounds record, height to the Y axis.
-}
resizeSize : InternalUnit.ResolvedCssUnitAxes -> Bounds -> Bounds -> Bool -> Bool -> PropertyAnimation Size -> PropertyAnimation Size
resizeSize units previousBounds bounds isLooping isPaused cfg =
    let
        oldStart =
            Size.toRecord cfg.start

        oldEnd =
            Size.toRecord cfg.end

        rw =
            applyAxisLegForUnit units.x previousBounds.x bounds.x oldStart.width oldEnd.width

        rh =
            applyAxisLegForUnit units.y previousBounds.y bounds.y oldStart.height oldEnd.height

        newStart =
            Size.fromRecord { width = rw.start, height = rh.start }

        newEnd =
            Size.fromRecord { width = rw.end, height = rh.end }

        oldDistance =
            Size.distance cfg.start cfg.end

        newLegDistance =
            Size.distance newStart newEnd
    in
    if cfg.isComplete && not isLooping then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else if newLegDistance == 0 && not (isPaused && not isLooping) then
        { cfg
            | start = newStart
            , end = newEnd
            , elapsedMs = cfg.totalDurationMs
            , isComplete = True
        }

    else
        preserveProgress
            { cfg = cfg
            , newStart = newStart
            , newEnd = newEnd
            , oldDistance = oldDistance
            , newLegDistance = newLegDistance
            }


extractElementCurrentStates : AnimGroup -> PropertyBaselines
extractElementCurrentStates =
    AnimGroup.getAnimations
        >> Animations.foldl (\_ -> extractPropertyCurrentState)
            PropertyBaselines.empty


extractPropertyCurrentState : Animation -> PropertyBaselines -> PropertyBaselines
extractPropertyCurrentState anim =
    let
        interpolated : (a -> PropertyBaselines -> PropertyBaselines) -> (Float -> a -> a -> a) -> PropertyAnimation a -> PropertyBaselines -> PropertyBaselines
        interpolated set interp a =
            set (interpolateEasedProgress interp a)
    in
    case anim of
        CustomProperty cssName unit a ->
            PropertyBaselines.setCustomProperty cssName (interpolateEasedProgress interpolateFloat a) unit

        CustomColorProperty cssName a ->
            PropertyBaselines.setCustomColorProperty cssName (interpolateEasedProgress Color.interpolate a)

        Opacity a ->
            interpolated PropertyBaselines.setOpacity interpolateOpacity a

        PerspectiveOrigin units a ->
            interpolated
                (\value ->
                    PropertyBaselines.setPerspectiveOrigin value
                        >> PropertyBaselines.setPerspectiveOriginUnits units
                )
                interpolatePerspectiveOrigin
                a

        Rotate a ->
            interpolated PropertyBaselines.setRotate interpolateRotate a

        Scale a ->
            interpolated PropertyBaselines.setScale interpolateScale a

        Size units a ->
            interpolated
                (\value ->
                    PropertyBaselines.setSize value
                        >> PropertyBaselines.setSizeUnits units
                )
                interpolateSize
                a

        Skew a ->
            interpolated PropertyBaselines.setSkew interpolateSkew a

        Translate units a ->
            interpolated
                (\value ->
                    PropertyBaselines.setTranslate value
                        >> PropertyBaselines.setTranslateUnits units
                )
                interpolateTranslate
                a



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            let
                anims =
                    animGroup
                        |> AnimGroup.getAnimations
                        |> Animations.list

                currentOrder =
                    AnimGroup.getTransformOrder animGroup

                transformParts =
                    List.foldl collectCurrentTransform Builder.emptyTransformParts anims

                transformString =
                    currentOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]

                nonTransformStyles =
                    List.concatMap getNonTransformStyleAttribute anims

                discreteStyles =
                    discreteEntryStyles animGroup
                        ++ discreteExitStyles animGroup

                willChangeStyle =
                    -- `will-change` promotes the animated properties to
                    -- their own compositor layer before per-frame style
                    -- updates start landing. We clear it once the
                    -- animation finishes (infinite loops never reach this
                    -- branch) so the element doesn't keep paying the
                    -- layer cost forever.
                    if AnimGroup.isComplete animGroup then
                        []

                    else
                        case AnimGroup.getWillChange animGroup of
                            "" ->
                                []

                            value ->
                                [ Html.Attributes.style "will-change" value ]
            in
            willChangeStyle ++ transformStyle ++ nonTransformStyles ++ discreteStyles


collectCurrentTransform : Animation -> Builder.TransformParts -> Builder.TransformParts
collectCurrentTransform anim acc =
    case anim of
        Translate units a ->
            { acc | translate = Translate.toCssString units (interpolateEasedProgress interpolateTranslate a) }

        Rotate a ->
            { acc | rotate = Rotate.toCssString (interpolateEasedProgress interpolateRotate a) }

        Skew a ->
            { acc | skew = Skew.toCssString (interpolateEasedProgress interpolateSkew a) }

        Scale a ->
            { acc | scale = Scale.toCssString (interpolateEasedProgress interpolateScale a) }

        _ ->
            acc


transformOrderToPart : Builder.TransformParts -> TransformProperty -> String
transformOrderToPart parts property =
    case property of
        TransformProperty.Translate ->
            parts.translate

        TransformProperty.Rotate ->
            parts.rotate

        TransformProperty.Skew ->
            parts.skew

        TransformProperty.Scale ->
            parts.scale


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles =
    AnimGroup.getDiscreteEntry
        >> Dict.toList
        >> List.map
            (\( prop, value ) ->
                Html.Attributes.style prop value
            )


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    AnimGroup.getDiscreteExit animGroup
        |> Dict.toList
        |> List.map
            (\( prop, { from, to } ) ->
                if AnimGroup.isComplete animGroup then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )


getNonTransformStyleAttribute : Animation -> List (Html.Attribute msg)
getNonTransformStyleAttribute anim =
    case anim of
        CustomProperty cssName unit a ->
            [ Html.Attributes.style cssName (String.fromFloat (interpolateEasedProgress interpolateFloat a) ++ unit) ]

        CustomColorProperty cssName a ->
            [ Html.Attributes.style cssName (Color.toCssString (interpolateEasedProgress Color.interpolate a)) ]

        Opacity a ->
            [ Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (interpolateEasedProgress interpolateOpacity a))) ]

        PerspectiveOrigin units a ->
            [ Html.Attributes.style "perspective-origin" (PerspectiveOrigin.toCssString units (interpolateEasedProgress interpolatePerspectiveOrigin a)) ]

        Rotate _ ->
            []

        Scale _ ->
            []

        Size units a ->
            let
                size =
                    interpolateEasedProgress interpolateSize a

                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ InternalUnit.toCssSuffix units.x)
            , Html.Attributes.style "height" (String.fromFloat height ++ InternalUnit.toCssSuffix units.y)
            ]

        Skew _ ->
            []

        Translate _ _ ->
            []



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> Builder.AnimBuilder { eng | withIterations : () } -> Builder.AnimBuilder { eng | withIterations : () }
iterations =
    Builder.iterations


loopForever : Builder.AnimBuilder { eng | withLoopForever : () } -> Builder.AnimBuilder { eng | withLoopForever : () }
loopForever =
    Builder.loopForever


alternate : Builder.AnimBuilder { eng | withAlternate : () } -> Builder.AnimBuilder { eng | withAlternate : () }
alternate =
    Builder.alternate



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> Builder.AnimBuilder { eng | withTiming : () } -> Builder.AnimBuilder { eng | withTiming : () }
delay =
    Builder.delay


duration : Int -> Builder.AnimBuilder { eng | withTiming : () } -> Builder.AnimBuilder { eng | withTiming : () }
duration =
    Builder.duration


speed : Float -> Builder.AnimBuilder { eng | withTiming : () } -> Builder.AnimBuilder { eng | withTiming : () }
speed =
    Builder.speed



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
easing =
    Builder.easing



-- ============================================================
-- UNIT
-- ============================================================


cssUnit : Unit -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
cssUnit =
    Builder.cssUnit


cssUnitX : Unit -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
cssUnitX =
    Builder.cssUnitX


cssUnitY : Unit -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
cssUnitY =
    Builder.cssUnitY


cssUnitZ : Unit -> Builder.AnimBuilder eng -> Builder.AnimBuilder eng
cssUnitZ =
    Builder.cssUnitZ



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> Builder.AnimBuilder { eng | withSpring : () } -> Builder.AnimBuilder { eng | withSpring : () }
spring =
    Builder.spring



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName =
    applyControlAction animGroupName Cancelled <|
        \animGroup ->
            let
                animations =
                    mapAnimations Animation.stop animGroup
            in
            AnimGroups.insert animGroupName
                (animGroup
                    |> AnimGroup.setAnimations animations
                    |> AnimGroup.setPlayState PlayState.Complete
                )


reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName =
    applyControlAction animGroupName Cancelled <|
        \animGroup animGroups ->
            let
                animations =
                    mapAnimations Animation.reset animGroup
            in
            AnimGroups.insert animGroupName
                (animGroup
                    |> AnimGroup.setAnimations animations
                    |> AnimGroup.setPlayState PlayState.Reset
                )
                animGroups


restart : AnimGroupName -> AnimState -> AnimState
restart animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                animations =
                    mapAnimations Animation.reset animGroup

                updatedAnimGroup =
                    animGroup
                        |> AnimGroup.setAnimations animations
                        |> AnimGroup.setPlayState PlayState.Running
            in
            AnimState
                { state
                    | subscriptionsActive = True
                    , pendingControlEvents = state.pendingControlEvents ++ [ Restarted animGroupName ]
                }
                (AnimGroups.insert animGroupName updatedAnimGroup animGroups)


pause : AnimGroupName -> AnimState -> AnimState
pause animGroupName =
    applyControlAction animGroupName Paused <|
        \_ animGroups ->
            AnimGroups.update animGroupName
                (Maybe.map (AnimGroup.setPlayState PlayState.Paused))
                animGroups


mapAnimations : (Animation -> Animation) -> AnimGroup -> Animations.Animations
mapAnimations fn =
    AnimGroup.getAnimations
        >> Animations.map (\_ -> fn)


applyControlAction :
    AnimGroupName
    -> (AnimGroupName -> Float -> ControlEvent)
    -> (AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup)
    -> AnimState
    -> AnimState
applyControlAction animGroupName toEvent transformGroups (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                updatedAnimGroups =
                    transformGroups animGroup animGroups
            in
            AnimState
                { state
                    | subscriptionsActive =
                        updatedAnimGroups
                            |> AnimGroups.groups
                            |> List.any AnimGroup.isRunning
                    , pendingControlEvents =
                        if AnimGroup.isRunning animGroup then
                            state.pendingControlEvents ++ [ toEvent animGroupName (overallProgress animGroup) ]

                        else
                            state.pendingControlEvents
                }
                updatedAnimGroups


resume : AnimGroupName -> AnimState -> AnimState
resume animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            if not (AnimGroup.isPaused animGroup) then
                -- Resume only re-activates an explicitly Paused animation.
                -- After Reset or Complete it is a no-op.
                AnimState state animGroups

            else
                AnimState
                    { state
                        | subscriptionsActive = True
                        , pendingControlEvents =
                            state.pendingControlEvents ++ [ Resumed animGroupName ]
                    }
                    (AnimGroups.update animGroupName
                        (Maybe.map (AnimGroup.setPlayState PlayState.Running))
                        animGroups
                    )



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Builder.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    Builder.discreteExit



-- ============================================================
-- FREEZE
-- ============================================================


type alias FreezeProperty =
    Builder.FreezeProperty


freezeTranslate : FreezeProperty
freezeTranslate =
    Builder.FreezeTranslate


freezeRotate : FreezeProperty
freezeRotate =
    Builder.FreezeRotate


freezeScale : FreezeProperty
freezeScale =
    Builder.FreezeScale


freezeSkew : FreezeProperty
freezeSkew =
    Builder.FreexeSkew


freezeAxes : List String -> List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeAxes =
    Builder.freezeAxes



-- ============================================================
-- UNFREEZE
-- ============================================================


unfreezeAxes : List String -> List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeAxes =
    Builder.unfreezeAxes



-- ============================================================
-- STATE QUERIES
-- ============================================================


anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState state animGroups) =
    case AnimGroups.groups animGroups of
        [] ->
            Nothing

        _ ->
            Just state.subscriptionsActive


isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map AnimGroup.isRunning


isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map AnimGroup.isComplete


allComplete : AnimState -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        animGroups
            |> AnimGroups.groups
            |> List.all AnimGroup.isComplete
            |> Just


getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map overallProgress


overallProgress : AnimGroup -> Float
overallProgress =
    AnimGroup.getAnimations
        >> Animations.list
        >> List.map (Animation.foldTiming calculateProgress)
        >> List.maximum
        >> Maybe.withDefault 0



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================


getBuilder : AnimState -> EngineBuilder
getBuilder (AnimState state _) =
    state.builder


getPropertyValue : String -> (Animation -> Maybe a) -> AnimGroupName -> AnimState -> Maybe a
getPropertyValue propertyKey valueExtractor animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (Animations.get propertyKey << AnimGroup.getAnimations)
        |> Maybe.andThen valueExtractor



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomPropertyRange animGroupName cssName


getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomPropertyEnd animGroupName cssName


getPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyCurrent animGroupName cssName =
    getPropertyValue ("custom:" ++ cssName)
        (\prop ->
            case prop of
                CustomProperty propName _ config ->
                    if propName == cssName then
                        config
                            |> interpolateEasedProgress interpolateFloat
                            |> Just

                    else
                        Nothing

                _ ->
                    Nothing
        )
        animGroupName



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyRange animGroupName cssName


getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyEnd animGroupName cssName


getColorPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyCurrent animGroupName cssName =
    getPropertyValue ("customColor:" ++ cssName)
        (\prop ->
            case prop of
                CustomColorProperty propName config ->
                    if propName == cssName then
                        config
                            |> interpolateEasedProgress Color.interpolate
                            |> Just

                    else
                        Nothing

                _ ->
                    Nothing
        )
        animGroupName



-- ============================
-- OPACITY
-- ============================


getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName =
    getBuilder >> Property.getOpacityRange animGroupName


getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart animGroupName =
    getBuilder >> Property.getOpacityStart animGroupName


getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd animGroupName =
    getBuilder >> Property.getOpacityEnd animGroupName


getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent =
    getPropertyValue "opacity"
        (\prop ->
            case prop of
                Opacity config ->
                    config
                        |> interpolateEasedProgress interpolateOpacity
                        |> Opacity.toFloat
                        |> Just

                _ ->
                    Nothing
        )


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity =
    Interpolation.interpolateOpacity



-- ============================
-- ROTATE
-- ============================


getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName =
    getBuilder >> Property.getRotateRange animGroupName


getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getBuilder >> Property.getRotateStart animGroupName


getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getBuilder >> Property.getRotateEnd animGroupName


getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    getPropertyValue "rotate"
        (\prop ->
            case prop of
                Rotate config ->
                    config
                        |> interpolateEasedProgress interpolateRotate
                        |> Rotate.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    Interpolation.interpolateRotate



-- ============================
-- SCALE
-- ============================


getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName state =
    case getRuntimeScale animGroupName state of
        Just cfg ->
            Just
                { start = Just (Scale.toRecord cfg.start)
                , end = Scale.toRecord cfg.end
                }

        Nothing ->
            (getBuilder >> Property.getScaleRange animGroupName) state


getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName state =
    case getRuntimeScale animGroupName state of
        Just cfg ->
            Just (Scale.toRecord cfg.start)

        Nothing ->
            (getBuilder >> Property.getScaleStart animGroupName) state


getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName state =
    case getRuntimeScale animGroupName state of
        Just cfg ->
            Just (Scale.toRecord cfg.end)

        Nothing ->
            (getBuilder >> Property.getScaleEnd animGroupName) state


getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    getPropertyValue "scale"
        (\prop ->
            case prop of
                Scale config ->
                    Just (interpolateEasedProgress interpolateScale config |> Scale.toRecord)

                _ ->
                    Nothing
        )


{-| Look up the live `PropertyAnimation Scale` for a group, if any.

Like Translate, Scale's runtime state can diverge from the builder
snapshot via [`onResize`](#onResize), so its getters consult the runtime
first and fall back to the builder.

-}
getRuntimeScale : AnimGroupName -> AnimState -> Maybe (PropertyAnimation Scale)
getRuntimeScale =
    getPropertyValue "scale"
        (\prop ->
            case prop of
                Scale cfg ->
                    Just cfg

                _ ->
                    Nothing
        )


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    Interpolation.interpolateScale



-- ============================
-- SIZE
-- ============================


getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName state =
    case getRuntimeSize animGroupName state of
        Just cfg ->
            Just
                { start = Just (Size.toRecord cfg.start)
                , end = Size.toRecord cfg.end
                }

        Nothing ->
            (getBuilder >> Property.getSizeRange animGroupName) state


getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart animGroupName state =
    case getRuntimeSize animGroupName state of
        Just cfg ->
            Just (Size.toRecord cfg.start)

        Nothing ->
            (getBuilder >> Property.getSizeStart animGroupName) state


getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName state =
    case getRuntimeSize animGroupName state of
        Just cfg ->
            Just (Size.toRecord cfg.end)

        Nothing ->
            (getBuilder >> Property.getSizeEnd animGroupName) state


getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent =
    getPropertyValue "size"
        (\prop ->
            case prop of
                Size _ config ->
                    config
                        |> interpolateEasedProgress interpolateSize
                        |> Size.toRecord
                        |> Just

                _ ->
                    Nothing
        )


{-| Look up the live `PropertyAnimation Size` for a group, if any.

Like Scale and Translate, Size's runtime state can diverge from the
builder snapshot via [`onResize`](#onResize), so its getters consult
the runtime first and fall back to the builder.

-}
getRuntimeSize : AnimGroupName -> AnimState -> Maybe (PropertyAnimation Size)
getRuntimeSize =
    getPropertyValue "size"
        (\prop ->
            case prop of
                Size _ config ->
                    Just config

                _ ->
                    Nothing
        )


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    Interpolation.interpolateSize



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


getPerspectiveOriginRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange animGroupName state =
    case getRuntimePerspectiveOrigin animGroupName state of
        Just cfg ->
            Just
                { start = Just (PerspectiveOrigin.toRecord cfg.start)
                , end = PerspectiveOrigin.toRecord cfg.end
                }

        Nothing ->
            (getBuilder >> Property.getPerspectiveOriginRange animGroupName) state


getPerspectiveOriginStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart animGroupName state =
    case getRuntimePerspectiveOrigin animGroupName state of
        Just cfg ->
            Just (PerspectiveOrigin.toRecord cfg.start)

        Nothing ->
            (getBuilder >> Property.getPerspectiveOriginStart animGroupName) state


getPerspectiveOriginEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd animGroupName state =
    case getRuntimePerspectiveOrigin animGroupName state of
        Just cfg ->
            Just (PerspectiveOrigin.toRecord cfg.end)

        Nothing ->
            (getBuilder >> Property.getPerspectiveOriginEnd animGroupName) state


getPerspectiveOriginCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginCurrent =
    getPropertyValue "perspectiveOrigin"
        (\prop ->
            case prop of
                PerspectiveOrigin _ config ->
                    config
                        |> interpolateEasedProgress interpolatePerspectiveOrigin
                        |> PerspectiveOrigin.toRecord
                        |> Just

                _ ->
                    Nothing
        )


{-| Look up the live `PropertyAnimation PerspectiveOrigin` for a group, if
any.

Like Translate and Scale, PerspectiveOrigin's runtime state can diverge
from the builder snapshot via [`onResize`](#onResize), so its getters
consult the runtime first and fall back to the builder.

-}
getRuntimePerspectiveOrigin : AnimGroupName -> AnimState -> Maybe (PropertyAnimation PerspectiveOrigin)
getRuntimePerspectiveOrigin =
    getPropertyValue "perspectiveOrigin"
        (\prop ->
            case prop of
                PerspectiveOrigin _ cfg ->
                    Just cfg

                _ ->
                    Nothing
        )


interpolatePerspectiveOrigin : Float -> PerspectiveOrigin -> PerspectiveOrigin -> PerspectiveOrigin
interpolatePerspectiveOrigin =
    Interpolation.interpolatePerspectiveOrigin



-- ============================
-- SKEW
-- ============================


getSkewRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange animGroupName =
    getBuilder >> Property.getSkewRange animGroupName


getSkewStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewStart animGroupName =
    getBuilder >> Property.getSkewStart animGroupName


getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd animGroupName =
    getBuilder >> Property.getSkewEnd animGroupName


getSkewCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewCurrent =
    getPropertyValue "skew"
        (\prop ->
            case prop of
                Skew config ->
                    config
                        |> interpolateEasedProgress interpolateSkew
                        |> Skew.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateSkew : Float -> Skew -> Skew -> Skew
interpolateSkew =
    Interpolation.interpolateSkew



-- ============================
-- TRANSLATE
-- ============================


getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just
                { start = Just (Translate.toRecord cfg.start)
                , end = Translate.toRecord cfg.end
                }

        Nothing ->
            (getBuilder >> Property.getTranslateRange animGroupName) state


getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just (Translate.toRecord cfg.start)

        Nothing ->
            (getBuilder >> Property.getTranslateStart animGroupName) state


getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just (Translate.toRecord cfg.end)

        Nothing ->
            (getBuilder >> Property.getTranslateEnd animGroupName) state


{-| Look up the live `PropertyAnimation Translate` for a group, if any.

Translate is one of the properties whose runtime state can diverge from
the builder snapshot via [`onResize`](#onResize), so its getters consult
the runtime first and fall back to the builder.

-}
getRuntimeTranslate : AnimGroupName -> AnimState -> Maybe (PropertyAnimation Translate)
getRuntimeTranslate animGroupName =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate _ cfg ->
                    Just cfg

                _ ->
                    Nothing
        )
        animGroupName


getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate _ config ->
                    config
                        |> interpolateEasedProgress interpolateTranslate
                        |> Translate.toRecord
                        |> Just

                _ ->
                    Nothing
        )


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    Interpolation.interpolateTranslate



-- ============================================================
-- INTERPOLATION (delegated to Sub.Interpolation)
-- ============================================================


calculateProgress : { a | elapsedMs : Float, delayMs : Float, totalDurationMs : Float, isComplete : Bool } -> Float
calculateProgress =
    Interpolation.calculateProgress


interpolateEasedProgress : (Float -> a -> a -> a) -> PropertyAnimation a -> a
interpolateEasedProgress =
    Interpolation.interpolateEasedProgress


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat =
    Interpolation.interpolateFloat
