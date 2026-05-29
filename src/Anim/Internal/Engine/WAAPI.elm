module Anim.Internal.Engine.WAAPI exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg(..)
    , AnimState
    , EngineBuilder
    , FreezeProperty
    , TimelineBuilder
    , allComplete
    , alternate
    , animate
    , anyRunning
    , attributes
    , cssUnit
    , cssUnitX
    , cssUnitY
    , cssUnitZ
    , currentTimeForResize
    , delay
    , discreteEntry
    , discreteExit
    , duration
    , easing
    , fireAndForget
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
    , isComplete
    , isRunning
    , iterations
    , loopForever
    , onResize
    , pause
    , proportionFromProgress
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
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..))
import Anim.Internal.Builder.Opacity as Opacity
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Builder.Rotate as Rotate
import Anim.Internal.Builder.Scale as Scale
import Anim.Internal.Builder.Size as Size
import Anim.Internal.Builder.Skew as Skew
import Anim.Internal.Builder.Translate as Translate
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus, PropertyState, ResizeAxisState)
import Anim.Internal.Engine.WAAPI.Encoder exposing (..)
import Anim.Internal.Engine.WAAPI.Generator as Generator
import Anim.Internal.Engine.WAAPI.ProgressApply as ProgressApply
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Internal.Unit as InternalUnit
import Anim.Resize exposing (Bounds)
import Anim.Unit exposing (Unit(..))
import Dict
import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Motion.Spring exposing (Spring)
import Set exposing (Set)



-- ============================================================
-- TYPES
-- ============================================================


type AnimState msg
    = AnimState
        { subscriptionsActive : Bool
        , commandPort : Encode.Value -> Cmd msg
        , subscriptionPort : (Decode.Value -> msg) -> Sub msg
        , builder : EngineBuilder
        , lastResize : ResizeBuilder.Builder
        }
        (AnimGroups AnimGroup)


type alias AnimBuilder mode =
    Builder.AnimBuilder mode


type alias TimelineBuilder engine =
    Builder.AnimBuilder (Builder.ForDocumentTimeline engine)


type alias EngineBuilder =
    Builder.AnimBuilder (Builder.ForDocumentTimeline Builder.ForWAAPIEngine)


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (EngineBuilder -> EngineBuilder) -> AnimState msg
init commandPort subscriptionPort propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , subscriptionsActive = False
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                , lastResize = ResizeBuilder.empty
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
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                , lastResize = ResizeBuilder.empty
                }
                (AnimGroups.map initGroup animGroups)



-- ============================================================
-- TRIGGER
-- ============================================================


fireAndForget : (Encode.Value -> Cmd msg) -> (EngineBuilder -> EngineBuilder) -> Cmd msg
fireAndForget sendToPort pipeline =
    Builder.init [ pipeline ]
        |> Builder.process
        |> encodeProcessedData
        |> sendToPort


animate : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
animate (AnimState state animGroups) build =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates (setSnapshot animGroups)
                |> build

        processed =
            Builder.process builder

        frozenAxes =
            Builder.getAllFrozenAxes builder

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
                        (AnimGroup.addPropertyStates animGroup existing)
                        acc

        processedAnimGroups =
            processed.groups
                |> AnimGroups.map generateAnimGroup
                |> AnimGroups.foldl insertAnimGroup animGroups

        nextState =
            AnimState
                { state
                    | builder =
                        builder
                            |> Builder.addAnimationToHistory processed
                            |> Builder.mergeBaselines
                            |> Builder.clearAnimData
                    , subscriptionsActive = True
                }
                processedAnimGroups

        animateCmd =
            state.commandPort <|
                encode processedAnimGroups frozenAxes processed
    in
    ( nextState, animateCmd )


setSnapshot : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : PropertyBaselines }
setSnapshot anims =
    AnimGroups.map (\_ anim -> { propertySnapshot = AnimGroup.getPropertySnapshot anim }) anims


{-| Snap the named anim groups to the targets described by `build`, with no
animation.

For every property mentioned in `build`, the engine cancels any in-flight
WAAPI animation on that property, writes the target value as inline style
on the element, and marks the property `Complete`. Builder timing fields
(`duration`, `delay`, `easing`, `spring`) are accepted but ignored —
there is no animation to apply them to.

Frozen axes are preserved: only unfrozen axes are snapped. Untouched
properties on the same anim group continue running.

The JS side emits a `Cancelled` [AnimEvent](#AnimEvent) for every
property whose animation was previously playing and is touched by the
build. No `Started` events are emitted.

Use `retarget` to instantly reposition an element — e.g. after a layout
change, a teleport, or to seed a new starting position before a follow-up
`animate` call. For a smooth redirect from the current position toward a
new target, use [animate](#animate) with a factored builder instead.

-}
retarget : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
retarget (AnimState state animGroups) build =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates (setSnapshot animGroups)
                |> build

        processed =
            Builder.process builder

        frozenAxes =
            Builder.getAllFrozenAxes builder

        touchedAxes =
            Builder.getAllTouchedAxes builder

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

        -- Mark every property on the freshly generated (touched) group as
        -- Complete and advance its snapshot to the target value: the snap
        -- puts the property at its target with no animation pending. The
        -- JS side will emit Cancelled for any previously-Running animation
        -- when it cancels the WAAPI handle.
        --
        -- For per-axis-aware properties (translate), axes not mentioned in
        -- the retarget build keep the previously-running animation's end
        -- value rather than collapsing to the live mid-flight position.
        -- We patch both:
        --
        --   1. The new translate `PropertyState.config` so every
        --      `propertyUpdate` event from JS interpolates with
        --      `start.untouched = end.untouched = previousEnd.untouched`
        --      and snapshot.translate.untouched stays at previousEnd.
        --   2. The initial snapshot so the value is correct before the
        --      first `propertyUpdate` arrives.
        --
        -- That matches the JS continuation animation's final keyframe so
        -- the inline style Elm renders after `finish` agrees with the
        -- value WAAPI's `commitStyles` left on the element.
        snapPropertyStates : AnimGroupName -> Maybe AnimGroup -> AnimGroup -> AnimGroup
        snapPropertyStates groupName maybeExisting freshAnimGroup =
            let
                patchedGroup =
                    preserveUntouchedTranslateConfig groupName maybeExisting freshAnimGroup

                touchedStates =
                    AnimGroup.getPropertyStates patchedGroup

                fullProgress =
                    touchedStates
                        |> AnimGroups.names
                        |> List.map (\name -> ( name, 1.0 ))
                        |> Dict.fromList

                snappedSnapshot =
                    patchedGroup
                        |> AnimGroup.getPropertySnapshot
                        |> ProgressApply.applyPropertyProgress fullProgress touchedStates
            in
            patchedGroup
                |> AnimGroup.setSnapshot snappedSnapshot
                |> AnimGroup.setStatus AnimGroup.Complete

        translateTouchedAxesFor : AnimGroupName -> Set String
        translateTouchedAxesFor groupName =
            Dict.get ( groupName, "translate" ) touchedAxes
                |> Maybe.withDefault Set.empty

        preserveUntouchedTranslateConfig : AnimGroupName -> Maybe AnimGroup -> AnimGroup -> AnimGroup
        preserveUntouchedTranslateConfig groupName maybeExisting freshAnimGroup =
            let
                touched =
                    translateTouchedAxesFor groupName

                isFullyTouched =
                    Set.member "x" touched && Set.member "y" touched && Set.member "z" touched
            in
            if isFullyTouched then
                freshAnimGroup

            else
                case Maybe.andThen translateEnd maybeExisting of
                    Nothing ->
                        freshAnimGroup

                    Just previousEnd ->
                        overrideTranslateConfigEnds touched previousEnd freshAnimGroup

        overrideTranslateConfigEnds : Set String -> Translate.Translate -> AnimGroup -> AnimGroup
        overrideTranslateConfigEnds touched previousEnd group =
            let
                previousRec =
                    Translate.toRecord previousEnd

                states =
                    AnimGroup.getPropertyStates group

                patched =
                    AnimGroups.map
                        (\propType propState ->
                            if propType == "translate" then
                                case propState.config of
                                    Builder.ProcessedTranslateConfig cfg ->
                                        let
                                            newEnd =
                                                mergeTranslate touched previousRec cfg.end

                                            newStart =
                                                cfg.start
                                                    |> Maybe.map (mergeTranslate touched previousRec)
                                                    |> Maybe.withDefault newEnd
                                        in
                                        { propState
                                            | config =
                                                Builder.ProcessedTranslateConfig
                                                    { cfg | start = Just newStart, end = newEnd }
                                        }

                                    _ ->
                                        propState

                            else
                                propState
                        )
                        states
            in
            AnimGroup.setPropertyStates patched group

        mergeTranslate : Set String -> { x : Float, y : Float, z : Float } -> Translate.Translate -> Translate.Translate
        mergeTranslate touched previousRec t =
            let
                rec =
                    Translate.toRecord t

                pick axis cur prev =
                    if Set.member axis touched then
                        cur

                    else
                        prev
            in
            Translate.fromRecord
                { x = pick "x" rec.x previousRec.x
                , y = pick "y" rec.y previousRec.y
                , z = pick "z" rec.z previousRec.z
                }

        translateEnd : AnimGroup -> Maybe Translate.Translate
        translateEnd group =
            AnimGroup.getPropertyStates group
                |> AnimGroups.get "translate"
                |> Maybe.andThen
                    (\propState ->
                        case propState.config of
                            Builder.ProcessedTranslateConfig cfg ->
                                Just cfg.end

                            _ ->
                                Nothing
                    )

        insertSnap : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertSnap animGroupName freshAnimGroup acc =
            let
                maybeExisting =
                    AnimGroups.get animGroupName acc

                snapped =
                    snapPropertyStates animGroupName maybeExisting freshAnimGroup
            in
            case maybeExisting of
                Nothing ->
                    AnimGroups.insert animGroupName snapped acc

                Just existing ->
                    -- `addPropertyStates` unions snapped's states over
                    -- existing's, biasing toward snapped on key collision.
                    -- Untouched properties on `existing` carry over with
                    -- their current Running/Paused/Complete status.
                    AnimGroups.insert animGroupName
                        (AnimGroup.addPropertyStates snapped existing)
                        acc

        nextAnimGroups =
            processed.groups
                |> AnimGroups.map generateAnimGroup
                |> AnimGroups.foldl insertSnap animGroups

        nextSubscriptionsActive =
            nextAnimGroups
                |> AnimGroups.groups
                |> List.any AnimGroup.isRunning

        nextState =
            AnimState
                { state
                    | builder =
                        builder
                            |> Builder.addAnimationToHistory processed
                            |> Builder.mergeBaselines
                            |> Builder.clearAnimData
                    , subscriptionsActive = nextSubscriptionsActive
                }
                nextAnimGroups

        retargetCmd =
            state.commandPort <|
                encodeRetarget nextAnimGroups frozenAxes touchedAxes processed
    in
    ( nextState, retargetCmd )



-- ============================================================
-- EVENTS
-- ============================================================


type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Restarted AnimGroupName
    | Paused AnimGroupName Float
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = JavascriptUpdate Decode.Value


update : AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )
update msg ((AnimState state animGroups) as animState) =
    case msg of
        JavascriptUpdate jsonValue ->
            case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
                Ok "animationUpdate" ->
                    -- Ignore events from scroll/view-driven engines — they are handled
                    -- by ScrollTimeline.update and ViewTimeline.update respectively.
                    let
                        engineField =
                            Decode.decodeValue (Decode.field "engine" Decode.string) jsonValue
                    in
                    case engineField of
                        Ok "scrollTimeline" ->
                            ( animState, Nothing )

                        Ok "viewTimeline" ->
                            ( animState, Nothing )

                        _ ->
                            case Decode.decodeValue animEventDecoder jsonValue of
                                Ok animEvent ->
                                    ( handleLifecycleEvent animEvent animState
                                    , Just animEvent
                                    )

                                Err error ->
                                    ( animState
                                    , Just <|
                                        AnimError <|
                                            "Failed to decode animation event: "
                                                ++ Decode.errorToString error
                                    )

                Ok "propertyUpdate" ->
                    case Decode.decodeValue animationUpdateDecoder jsonValue of
                        Ok animUpdate ->
                            let
                                updatedAnimations =
                                    AnimGroups.update animUpdate.animGroupName
                                        (Maybe.map (updateAnimGroup animUpdate))
                                        animGroups

                                -- Update global isRunning based on animation status
                                hasRunningAnimations =
                                    AnimGroups.groups updatedAnimations
                                        |> List.any
                                            (AnimGroup.getPropertyStates
                                                >> AnimGroups.groups
                                                >> List.any (\prop -> prop.status == AnimGroup.Running)
                                            )

                                progressEvent =
                                    if Builder.getEmitProgress state.builder then
                                        Just (Progress animUpdate.animGroupName animUpdate.progress)

                                    else
                                        Nothing
                            in
                            ( AnimState { state | subscriptionsActive = hasRunningAnimations } updatedAnimations
                            , progressEvent
                            )

                        Err error ->
                            ( animState
                            , Just (AnimError ("Failed to decode animation update: " ++ Decode.errorToString error))
                            )

                Ok unknown ->
                    ( animState
                    , Just (AnimError ("Unknown message type: " ++ unknown))
                    )

                Err error ->
                    ( animState
                    , Just (AnimError ("Unknown message type: " ++ Decode.errorToString error))
                    )


handleLifecycleEvent : AnimEvent -> AnimState msg -> AnimState msg
handleLifecycleEvent animEvent (AnimState state animGroups) =
    let
        animGroupName =
            animEventGroupName animEvent

        newStatus =
            animEventToStatus animEvent

        applyIteration : AnimGroup -> AnimGroup
        applyIteration =
            case animEvent of
                Iteration _ iter ->
                    AnimGroup.setCurrentIteration iter

                _ ->
                    identity

        updatedAnimGroups =
            AnimGroups.update animGroupName
                (Maybe.map
                    (AnimGroup.setStatus newStatus
                        >> AnimGroup.setProgress
                            (case animEvent of
                                Paused _ progress ->
                                    progress

                                Cancelled _ progress ->
                                    progress

                                Progress _ progress ->
                                    progress

                                _ ->
                                    0
                            )
                        >> applyIteration
                    )
                )
                animGroups
    in
    AnimState
        { state
            | subscriptionsActive =
                AnimGroups.groups updatedAnimGroups
                    |> List.any AnimGroup.isRunning
        }
        updatedAnimGroups


updateAnimGroup : AnimationUpdate -> AnimGroup -> AnimGroup
updateAnimGroup animUpdate animGroup =
    let
        updateStatus : String -> PropertyState -> PropertyState
        updateStatus propType propAnim =
            case AnimGroups.get propType animUpdate.propertyVersions of
                Nothing ->
                    propAnim

                Just currentVersion ->
                    if currentVersion == propAnim.version then
                        { propAnim
                            | status =
                                if animUpdate.isAnimating then
                                    AnimGroup.Running

                                else
                                    AnimGroup.Complete
                        }

                    else
                        propAnim
    in
    animGroup
        |> AnimGroup.setProgress animUpdate.progress
        |> AnimGroup.setPropertyStates (AnimGroups.map updateStatus (AnimGroup.getPropertyStates animGroup))
        |> AnimGroup.setSnapshot
            (animGroup
                |> AnimGroup.getPropertySnapshot
                |> ProgressApply.applyPropertyProgress animUpdate.propertyProgress (AnimGroup.getPropertyStates animGroup)
            )


{-| Decoder for AnimEvent from lifecycle events.
-}
animEventDecoder : Decode.Decoder AnimEvent
animEventDecoder =
    Decode.map3 statusToAnimEvent
        (Decode.oneOf [ Decode.at [ "payload", "animGroup" ] Decode.string, Decode.at [ "payload", "elementId" ] Decode.string ])
        (Decode.at [ "payload", "status" ] Decode.string)
        (Decode.at [ "payload", "progress" ] Decode.float)


{-| Map a decoded status string to the appropriate AnimEvent constructor.
-}
statusToAnimEvent : String -> String -> Float -> AnimEvent
statusToAnimEvent animGroupName status progress =
    case status of
        "started" ->
            Started animGroupName

        "paused" ->
            Paused animGroupName progress

        "resumed" ->
            Resumed animGroupName

        "completed" ->
            Ended animGroupName

        "cancelled" ->
            Cancelled animGroupName progress

        "stopped" ->
            Ended animGroupName

        "reset" ->
            Cancelled animGroupName progress

        "restarted" ->
            Restarted animGroupName

        "iteration" ->
            Iteration animGroupName (round progress)

        invalid ->
            AnimError ("Unknown status: " ++ invalid)


animEventGroupName : AnimEvent -> String
animEventGroupName animEvent =
    case animEvent of
        Started name ->
            name

        Ended name ->
            name

        Cancelled name _ ->
            name

        Restarted name ->
            name

        Paused name _ ->
            name

        Resumed name ->
            name

        Iteration name _ ->
            name

        Progress name _ ->
            name

        AnimError _ ->
            ""


animEventToStatus : AnimEvent -> AnimationStatus
animEventToStatus animEvent =
    case animEvent of
        Started _ ->
            AnimGroup.Running

        Ended _ ->
            AnimGroup.Complete

        Cancelled _ _ ->
            AnimGroup.Complete

        Restarted _ ->
            AnimGroup.Running

        Paused _ _ ->
            AnimGroup.Paused

        Resumed _ ->
            AnimGroup.Running

        Iteration _ _ ->
            AnimGroup.Running

        Progress _ _ ->
            AnimGroup.Running

        AnimError _ ->
            AnimGroup.Complete



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions toMsg (AnimState state _) =
    state.subscriptionPort <|
        (toMsg << JavascriptUpdate)



-- ============================================================
-- RESIZE
-- ============================================================


{-| Adjust the in-flight properties of every anim group named in the builder
to new bounding ranges, using the directives composed in a
[`Anim.Resize.Builder`](Anim-Resize#Builder).
-}
onResize : AnimState msg -> (ResizeBuilder.Builder -> ResizeBuilder.Builder) -> ( AnimState msg, Cmd msg )
onResize (AnimState state animGroups) buildResize =
    let
        builder =
            ResizeBuilder.build buildResize

        previousBuilder =
            state.lastResize

        merged =
            ResizeBuilder.merge previousBuilder builder

        animStateWithCache =
            AnimState { state | lastResize = merged } animGroups

        ( finalState, accCmds ) =
            List.foldl (applyGroupResize previousBuilder builder)
                ( animStateWithCache, [] )
                (ResizeBuilder.groups builder)
    in
    ( finalState, Cmd.batch (List.reverse accCmds) )


applyGroupResize :
    ResizeBuilder.Builder
    -> ResizeBuilder.Builder
    -> AnimGroupName
    -> ( AnimState msg, List (Cmd msg) )
    -> ( AnimState msg, List (Cmd msg) )
applyGroupResize previousBuilder builder animGroupName ( animState, accCmds ) =
    let
        prevBoundsFor lookup =
            lookup animGroupName previousBuilder
                |> Maybe.map .bounds
                |> Maybe.withDefault emptyBounds

        ( afterTranslate, translateCmd ) =
            case ResizeBuilder.getTranslate animGroupName builder of
                Nothing ->
                    ( animState, Cmd.none )

                Just { bounds } ->
                    applyTranslateResize animGroupName (prevBoundsFor ResizeBuilder.getTranslate) bounds animState

        ( afterTranslatePosition, translatePositionCmd ) =
            case ResizeBuilder.getTranslatePosition animGroupName builder of
                Nothing ->
                    ( afterTranslate, Cmd.none )

                Just pos ->
                    applyTranslatePositionResize animGroupName pos afterTranslate

        ( afterScale, scaleCmd ) =
            case ResizeBuilder.getScale animGroupName builder of
                Nothing ->
                    ( afterTranslatePosition, Cmd.none )

                Just { bounds } ->
                    applyScaleResize animGroupName (prevBoundsFor ResizeBuilder.getScale) bounds afterTranslatePosition

        ( afterPerspectiveOrigin, perspectiveOriginCmd ) =
            case ResizeBuilder.getPerspectiveOrigin animGroupName builder of
                Nothing ->
                    ( afterScale, Cmd.none )

                Just { bounds } ->
                    applyPerspectiveOriginResize animGroupName (prevBoundsFor ResizeBuilder.getPerspectiveOrigin) bounds afterScale

        ( afterPerspectiveOriginPosition, perspectiveOriginPositionCmd ) =
            case ResizeBuilder.getPerspectiveOriginPosition animGroupName builder of
                Nothing ->
                    ( afterPerspectiveOrigin, Cmd.none )

                Just pos ->
                    applyPerspectiveOriginPositionResize animGroupName pos afterPerspectiveOrigin
    in
    ( afterPerspectiveOriginPosition, perspectiveOriginPositionCmd :: perspectiveOriginCmd :: scaleCmd :: translatePositionCmd :: translateCmd :: accCmds )


emptyBounds : Bounds
emptyBounds =
    { x = Nothing, y = Nothing, z = Nothing }


applyTranslateResize : AnimGroupName -> Bounds -> Bounds -> AnimState msg -> ( AnimState msg, Cmd msg )
applyTranslateResize animGroupName previousBounds bounds ((AnimState state animGroups) as animState) =
    if ResizeBuilder.isEmpty bounds then
        ( animState, Cmd.none )

    else
        case computeResizePayload animGroupName previousBounds bounds animState of
            Nothing ->
                ( animState, Cmd.none )

            Just payload ->
                let
                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map
                                (AnimGroup.setSnapshot payload.newSnapshot
                                    >> AnimGroup.setResizeState "translate"
                                        { start = payload.command.start
                                        , end = payload.command.end
                                        , durationMs = payload.command.durationMs
                                        , proportion = payload.proportion
                                        }
                                )
                            )
                            animGroups

                    -- Sync the stored baseline to the resized end. `Builder.getBaseline`
                    -- feeds `Translate.for` so the next `animate` reads the post-resize
                    -- target — otherwise `toY h` / `toX w` would inherit the pre-resize
                    -- coordinate for the axis it doesn't explicitly set and animate the
                    -- box off-screen.
                    updatedBuilder =
                        state.builder
                            |> Builder.updateBaselines animGroupName
                                (PropertyBaselines.setTranslate
                                    (Translate.fromRecord payload.command.end)
                                )
                in
                ( AnimState { state | builder = updatedBuilder } updatedAnimGroups
                , state.commandPort (encodeResize payload.command)
                )


{-| Apply a `Translate.position` directive for a group's translate.

For each axis with `Just newPos`, write `newPos` into the snapshot's
translate baseline and the builder baseline, then ship the directive
to JS via the `translatePosition` port command. JS validates the
static-axis precondition (running animation's `startX == endX`) and
either snaps the live animation's keyframes + persists the inline
transform, or no-ops the axis silently. Axes set to `Nothing` are
left alone.

Always returns a port command when any axis is `Just`; JS owns the
static-vs-animating decision so the Elm side never has to consult
`AnimGroup.getResizeState` or thread per-axis live state through.

-}
applyTranslatePositionResize : AnimGroupName -> ResizeBuilder.Position -> AnimState msg -> ( AnimState msg, Cmd msg )
applyTranslatePositionResize animGroupName pos ((AnimState state animGroups) as animState) =
    if pos.x == Nothing && pos.y == Nothing && pos.z == Nothing then
        ( animState, Cmd.none )

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                ( animState, Cmd.none )

            Just animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup

                    current =
                        PropertyBaselines.getTranslate snapshot
                            |> Maybe.map Translate.toRecord
                            |> Maybe.withDefault { x = 0, y = 0, z = 0 }

                    -- Snapshot follows the live current value for axes not
                    -- being snapped, so `current` is the right default here.
                    newSnapshotT =
                        Translate.fromRecord
                            { x = Maybe.withDefault current.x pos.x
                            , y = Maybe.withDefault current.y pos.y
                            , z = Maybe.withDefault current.z pos.z
                            }

                    -- Baseline must follow the existing baseline (the leg's
                    -- end target, freshly updated by `Translate.bounds`) for
                    -- axes not being snapped — not the live snapshot, which
                    -- holds the mid-flight current value.
                    existingBaselineT =
                        Builder.getBaseline animGroupName state.builder
                            |> Maybe.andThen PropertyBaselines.getTranslate
                            |> Maybe.map Translate.toRecord
                            |> Maybe.withDefault current

                    newBaselineT =
                        Translate.fromRecord
                            { x = Maybe.withDefault existingBaselineT.x pos.x
                            , y = Maybe.withDefault existingBaselineT.y pos.y
                            , z = Maybe.withDefault existingBaselineT.z pos.z
                            }

                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map (AnimGroup.setSnapshot (PropertyBaselines.setTranslate newSnapshotT snapshot)))
                            animGroups

                    updatedBuilder =
                        state.builder
                            |> Builder.updateBaselines animGroupName
                                (PropertyBaselines.setTranslate newBaselineT)
                in
                ( AnimState { state | builder = updatedBuilder } updatedAnimGroups
                , state.commandPort
                    (encodeTranslatePosition
                        { animGroupName = animGroupName
                        , x = pos.x
                        , y = pos.y
                        , z = pos.z
                        }
                    )
                )


{-| Apply a `PerspectiveOrigin.position` directive for a group's
perspective-origin. Mirror of [`applyTranslatePositionResize`](#applyTranslatePositionResize):
writes per-axis `Just newPos` into the snapshot's perspective-origin baseline
and the builder baseline, then ships a `perspectiveOriginPosition` port
command. JS validates the static-axis precondition and either snaps the
live perspective-origin animation's keyframes in place (no cancel, no
seek) or no-ops the axis. Axes set to `Nothing` are left alone.
-}
applyPerspectiveOriginPositionResize : AnimGroupName -> ResizeBuilder.Position -> AnimState msg -> ( AnimState msg, Cmd msg )
applyPerspectiveOriginPositionResize animGroupName pos ((AnimState state animGroups) as animState) =
    if pos.x == Nothing && pos.y == Nothing then
        ( animState, Cmd.none )

    else
        case AnimGroups.get animGroupName animGroups of
            Nothing ->
                ( animState, Cmd.none )

            Just animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup

                    currentPO =
                        PropertyBaselines.getPerspectiveOrigin snapshot

                    -- Pull the actual stored unit from the snapshot - the
                    -- baseline was tagged with the resolved unit by
                    -- `Generator.propertyBounds` when the animation was
                    -- created. Hard-coding `Percent` here would emit a `%`
                    -- suffix on a payload whose X/Y are in `px` (or any
                    -- other unit), producing perspective-origin values
                    -- like `400% 300%` that send the rendered cube off
                    -- screen during a drag-resize.
                    unit =
                        PropertyBaselines.getPerspectiveOriginUnits snapshot
                            |> Maybe.map .x
                            |> Maybe.withDefault InternalUnit.default

                    current =
                        currentPO
                            |> Maybe.map PerspectiveOrigin.toRecord
                            |> Maybe.withDefault { x = 50, y = 50 }

                    -- Snapshot follows the live current value for axes not
                    -- being snapped, so `current` is the right default here.
                    newSnapshotPO =
                        PerspectiveOrigin.fromRecord
                            { x = Maybe.withDefault current.x pos.x
                            , y = Maybe.withDefault current.y pos.y
                            }

                    -- Baseline must follow the existing baseline (the leg's
                    -- end target, freshly updated by `PerspectiveOrigin.bounds`)
                    -- for axes not being snapped — not the live snapshot,
                    -- which holds the mid-flight current value.
                    existingBaselinePO =
                        Builder.getBaseline animGroupName state.builder
                            |> Maybe.andThen PropertyBaselines.getPerspectiveOrigin
                            |> Maybe.map PerspectiveOrigin.toRecord
                            |> Maybe.withDefault current

                    newBaselinePO =
                        PerspectiveOrigin.fromRecord
                            { x = Maybe.withDefault existingBaselinePO.x pos.x
                            , y = Maybe.withDefault existingBaselinePO.y pos.y
                            }

                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map (AnimGroup.setSnapshot (PropertyBaselines.setPerspectiveOrigin newSnapshotPO snapshot)))
                            animGroups

                    updatedBuilder =
                        state.builder
                            |> Builder.updateBaselines animGroupName
                                (PropertyBaselines.setPerspectiveOrigin newBaselinePO)

                    unitStr =
                        InternalUnit.toCssSuffix unit
                in
                ( AnimState { state | builder = updatedBuilder } updatedAnimGroups
                , state.commandPort
                    (encodePerspectiveOriginPosition
                        { animGroupName = animGroupName
                        , x = pos.x
                        , y = pos.y
                        , unit = unitStr
                        }
                    )
                )


computeResizePayload :
    AnimGroupName
    -> Bounds
    -> Bounds
    -> AnimState msg
    ->
        Maybe
            { command :
                { animGroupName : AnimGroupName
                , property : String
                , start : { x : Float, y : Float, z : Float }
                , end : { x : Float, y : Float, z : Float }
                , current : { x : Float, y : Float, z : Float }
                , durationMs : Float
                , currentTimeMs : Maybe Float
                , hasAnimationBaseline : Bool
                , unit : Maybe String
                }
            , newSnapshot : PropertyBaselines
            , proportion : AnimGroup.AxisProportion
            }
computeResizePayload animGroupName previousBounds bounds (AnimState state animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup
                in
                PropertyBaselines.getTranslate snapshot
                    |> Maybe.andThen
                        (\currentTranslate ->
                            let
                                resolvedBaseline =
                                    resolveResizeBaseline animGroupName animGroup state.builder

                                hasAnimationBaseline =
                                    resolvedBaseline /= Nothing

                                baseline =
                                    resolvedBaseline
                                        |> Maybe.withDefault
                                            -- No animation config registered for this group's
                                            -- translate (init-only property). Synthesize a
                                            -- degenerate baseline from the current snapshot so
                                            -- `applyAxis` can clamp the value into the new bounds
                                            -- via its `oldRange == 0` branch. The snapshot update
                                            -- in `applyTranslateResize` causes `WAAPI.attributes`
                                            -- to re-render the new transform inline.
                                            { start = Translate.toRecord currentTranslate
                                            , end = Translate.toRecord currentTranslate
                                            , durationMs = 0
                                            , proportion = AnimGroup.emptyProportion
                                            }
                            in
                            let
                                oldStart =
                                    baseline.start

                                oldEnd =
                                    baseline.end

                                oldCurrent =
                                    Translate.toRecord currentTranslate

                                rx =
                                    ResizeBuilder.applyAxis previousBounds.x bounds.x oldStart.x oldEnd.x oldCurrent.x

                                ry =
                                    ResizeBuilder.applyAxis previousBounds.y bounds.y oldStart.y oldEnd.y oldCurrent.y

                                rz =
                                    ResizeBuilder.applyAxis previousBounds.z bounds.z oldStart.z oldEnd.z oldCurrent.z

                                newStart =
                                    { x = rx.start, y = ry.start, z = rz.start }

                                newEnd =
                                    { x = rx.end, y = ry.end, z = rz.end }

                                -- Forward-axis proportion (0..1) derived from the frozen
                                -- per-iteration progress + direction. Stable across
                                -- resize round-trips because it bypasses the
                                -- `(oldCurrent - oldMin) / oldRange` recomputation that
                                -- drifted on repeated orientation switches (Bug 4).
                                direction =
                                    AnimGroup.getAnimationDirection animGroup

                                iter =
                                    AnimGroup.getCurrentIteration animGroup

                                progressValue =
                                    AnimGroup.getProgress animGroup

                                axisProportion =
                                    { x = proportionFromProgress direction iter progressValue oldStart.x oldEnd.x
                                    , y = proportionFromProgress direction iter progressValue oldStart.y oldEnd.y
                                    , z = proportionFromProgress direction iter progressValue oldStart.z oldEnd.z
                                    }

                                newCurrent =
                                    { x = applyProportionToBounds axisProportion.x bounds.x rx.current
                                    , y = applyProportionToBounds axisProportion.y bounds.y ry.current
                                    , z = applyProportionToBounds axisProportion.z bounds.z rz.current
                                    }

                                newDurationMs =
                                    scaleDurationForResize
                                        { oldStart = baseline.start |> Translate.fromRecord
                                        , oldEnd = baseline.end |> Translate.fromRecord
                                        , newStart = Translate.fromRecord newStart
                                        , newEnd = Translate.fromRecord newEnd
                                        , oldDurationMs = baseline.durationMs
                                        }

                                oldCurrentTimeMs =
                                    currentTimeForResize
                                        { durationMs = baseline.durationMs
                                        , currentIteration = AnimGroup.getCurrentIteration animGroup
                                        , progress = AnimGroup.getProgress animGroup
                                        }

                                currentTimeMs =
                                    currentTimeForResize
                                        { durationMs = newDurationMs
                                        , currentIteration = AnimGroup.getCurrentIteration animGroup
                                        , progress = AnimGroup.getProgress animGroup
                                        }

                                noChange =
                                    translateRecordsNearlyEqual newStart baseline.start
                                        && translateRecordsNearlyEqual newEnd baseline.end
                                        && translateRecordsNearlyEqual newCurrent oldCurrent
                                        && floatNearlyEqual newDurationMs baseline.durationMs
                                        && maybeFloatNearlyEqual currentTimeMs oldCurrentTimeMs
                            in
                            if noChange then
                                Nothing

                            else
                                Just
                                    { command =
                                        { animGroupName = animGroupName
                                        , property = "translate"
                                        , start = newStart
                                        , end = newEnd
                                        , current = newCurrent
                                        , durationMs = newDurationMs
                                        , currentTimeMs = currentTimeMs
                                        , hasAnimationBaseline = hasAnimationBaseline
                                        , unit = Nothing
                                        }
                                    , newSnapshot =
                                        PropertyBaselines.setTranslate
                                            (Translate.fromRecord newCurrent)
                                            snapshot
                                    , proportion = axisProportion
                                    }
                        )
            )


{-| Rescale the leg duration so the box keeps the same speed (px/ms) when
the bounding range changes. Returns the original duration when either the
old or new leg distance is zero (no motion to scale against).

The JS side uses this duration as input to `effect.updateTiming`, then
preserves the animation's fractional `currentTime` so the visual progress
within the current iteration stays put across the resize. WAAPI itself
preserves `currentIteration` and the alternating-leg phase, so no
forward/reverse-leg math is needed here.

-}
scaleDurationForResize :
    { oldStart : Translate.Translate
    , oldEnd : Translate.Translate
    , newStart : Translate.Translate
    , newEnd : Translate.Translate
    , oldDurationMs : Float
    }
    -> Float
scaleDurationForResize r =
    let
        oldDistance =
            Translate.distance r.oldStart r.oldEnd

        newDistance =
            Translate.distance r.newStart r.newEnd
    in
    if oldDistance > 0 && newDistance > 0 && r.oldDurationMs > 0 then
        (newDistance / oldDistance) * r.oldDurationMs

    else
        r.oldDurationMs


resizeNoopEpsilon : Float
resizeNoopEpsilon =
    0.001


floatNearlyEqual : Float -> Float -> Bool
floatNearlyEqual a b =
    abs (a - b) <= resizeNoopEpsilon


maybeFloatNearlyEqual : Maybe Float -> Maybe Float -> Bool
maybeFloatNearlyEqual a b =
    case ( a, b ) of
        ( Nothing, Nothing ) ->
            True

        ( Just av, Just bv ) ->
            floatNearlyEqual av bv

        _ ->
            False


translateRecordsNearlyEqual : { x : Float, y : Float, z : Float } -> { x : Float, y : Float, z : Float } -> Bool
translateRecordsNearlyEqual a b =
    floatNearlyEqual a.x b.x
        && floatNearlyEqual a.y b.y
        && floatNearlyEqual a.z b.z


perspectiveOriginRecordsNearlyEqual : { x : Float, y : Float } -> { x : Float, y : Float } -> Bool
perspectiveOriginRecordsNearlyEqual a b =
    floatNearlyEqual a.x b.x
        && floatNearlyEqual a.y b.y


{-| Compute the WAAPI `currentTime` (in ms) to seek to after a resize.

Unified across looping and non-looping animations: the seek is always
`(currentIteration + progress) * newDur`. Because [`applyAxis`](Anim-Internal-Resize-Builder#applyAxis)
returns canonical leg geometry (`legStart -> legEnd`) regardless of
animation kind, and [`scaleDurationForResize`](#scaleDurationForResize)
preserves px/ms by scaling `newDur` against the full-leg distance, this
formula lands the dot at exactly `easing(progress)` of the new leg -
the same proportional visual position it occupied before the resize.

Drag-resize (many resizes in quick succession) and orientation flip
(one resize) drive identical math: each tick recomputes `newDur` against
the _cached_ resize baseline (the previous tick's `(start, end)`), so
successive ticks self-stabilize.

-}
currentTimeForResize :
    { durationMs : Float
    , currentIteration : Int
    , progress : Float
    }
    -> Maybe Float
currentTimeForResize cfg =
    Just <|
        (toFloat cfg.currentIteration + cfg.progress)
            * cfg.durationMs


{-| Derive forward-axis position-as-proportion (0 = at `b.min`, 1 = at
`b.max`) from the animation's frozen per-iteration `progress`, its
`direction`, the current iteration index and the per-axis leg endpoints.

This is the single source of truth for "where on the leg is the box" so
resize round-trips stay exact: each Proportional resize computes the new
absolute position as `b.min + p * (b.max - b.min)` without ever feeding
the previous resize's `current` value back through a floating-point
subtraction & division (which is what compounded into visible drift on
repeated orientation switches - see Responsive Bug 4).

Returns `Nothing` for an axis with no motion (`startV == endV`) so the
caller can fall back to the existing degenerate-leg handling.

-}
proportionFromProgress :
    Builder.AnimationDirection
    -> Int
    -> Float
    -> Float
    -> Float
    -> Maybe Float
proportionFromProgress direction iter progress startV endV =
    if startV == endV then
        Nothing

    else
        let
            forwardAligned =
                startV < endV

            isAltReverseIter =
                case direction of
                    Builder.Alternate ->
                        modBy 2 iter == 1

                    Builder.Normal ->
                        False

            isForwardLeg =
                forwardAligned /= isAltReverseIter
        in
        Just <|
            if isForwardLeg then
                progress

            else
                1 - progress


{-| Apply a forward-axis proportion to a set of new bounds, yielding the
absolute position. Falls back to `fallbackCurrent` when no proportion is
available for the axis or when the new bounds aren't defined for that
axis (Clamp-only on that side, degenerate leg, etc.).
-}
applyProportionToBounds : Maybe Float -> Maybe ResizeBuilder.AxisBounds -> Float -> Float
applyProportionToBounds maybeP maybeBounds fallbackCurrent =
    case ( maybeP, maybeBounds ) of
        ( Just p, Just b ) ->
            b.min + p * (b.max - b.min)

        _ ->
            fallbackCurrent


{-| Resolve the resize baseline for a group's translate. Prefers the
last-applied resize state (cached on the AnimGroup) so successive resizes
see the _current_ effective bounds & duration rather than the original
`animate()` configuration. Falls back to the builder config for the very
first resize on a freshly-animated group, since `animate` resets the
cached state on the new AnimGroup.
-}
resolveResizeBaseline :
    AnimGroupName
    -> AnimGroup
    -> Builder.AnimBuilder mode
    -> Maybe ResizeAxisState
resolveResizeBaseline animGroupName animGroup builder =
    case AnimGroup.getResizeState "translate" animGroup of
        Just cached ->
            rejectDegenerateBaseline cached

        Nothing ->
            findCurrentTranslate animGroupName builder
                |> Maybe.map
                    (\cfg ->
                        let
                            startR =
                                cfg.start
                                    |> Maybe.withDefault Translate.default
                                    |> Translate.toRecord

                            endR =
                                Translate.toRecord cfg.end
                        in
                        { start = startR
                        , end = endR
                        , durationMs = toFloat cfg.duration
                        , proportion = AnimGroup.emptyProportion
                        }
                    )
                |> Maybe.andThen rejectDegenerateBaseline


findCurrentTranslate : AnimGroupName -> Builder.AnimBuilder mode -> Maybe (Builder.ProcessedAnimationConfig Translate.Translate)
findCurrentTranslate animGroupName builder =
    Builder.getAnimationConfigs animGroupName builder
        |> List.filterMap
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    Just cfg

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )
        |> List.head


{-| Filter out "degenerate" resize baselines — ones whose `durationMs <= 0`
indicate no real animation timeline (e.g. a synthesized cached state for
an init-only `Scale.init` / `Translate.init` value). These are kept on
the AnimGroup so `applyAxis` can still clamp into new bounds, but they
must not signal `hasAnimationBaseline = True` to JS, which would trigger
a `currentTime` seek on the shared merged-transform animation and reset
co-running animations (e.g. a spinning Rotate) to the start.
-}
rejectDegenerateBaseline : ResizeAxisState -> Maybe ResizeAxisState
rejectDegenerateBaseline baseline =
    if baseline.durationMs <= 0 then
        Nothing

    else
        Just baseline


{-| Dispatch a property name to its `rebaseXConfig` function for the
animate-restart flow. Returns `Nothing` for properties that have no
runtime resize-aware state to rebase against. To make a new property
resize-aware, add a `rebaseXConfig` for it and an arm here.
-}
rebaseFor :
    String
    ->
        Maybe
            (ResizeAxisState
             -> Builder.ProcessedPropertyConfig
             -> Builder.ProcessedPropertyConfig
            )
rebaseFor propName =
    case propName of
        "translate" ->
            Just rebaseTranslateConfig

        "scale" ->
            Just rebaseScaleConfig

        "perspectiveOrigin" ->
            Just rebasePerspectiveOriginConfig

        _ ->
            Nothing


{-| Replace a translate config's `start`/`end`/`duration` with the
post-resize values cached on the group. Called by the animate flow's
`restart` so a Restart triggered after a resize re-animates within the
current bounds rather than the original (pre-resize) ones.
-}
rebaseTranslateConfig :
    ResizeAxisState
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
rebaseTranslateConfig cached config =
    case config of
        Builder.ProcessedTranslateConfig cfg ->
            Builder.ProcessedTranslateConfig
                { cfg
                    | start = Just (Translate.fromRecord cached.start)
                    , end = Translate.fromRecord cached.end
                    , duration = round cached.durationMs
                }

        _ ->
            config


applyScaleResize : AnimGroupName -> Bounds -> Bounds -> AnimState msg -> ( AnimState msg, Cmd msg )
applyScaleResize animGroupName previousBounds bounds ((AnimState state animGroups) as animState) =
    if ResizeBuilder.isEmpty bounds then
        ( animState, Cmd.none )

    else
        case computeScaleResizePayload animGroupName previousBounds bounds animState of
            Nothing ->
                ( animState, Cmd.none )

            Just payload ->
                let
                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map
                                (AnimGroup.setSnapshot payload.newSnapshot
                                    >> AnimGroup.setResizeState "scale"
                                        { start = payload.command.start
                                        , end = payload.command.end
                                        , durationMs = payload.command.durationMs
                                        , proportion = payload.proportion
                                        }
                                )
                            )
                            animGroups

                    -- Sync the stored baseline to the resized end so the next builder
                    -- inherits the post-resize scale target. See the matching comment
                    -- in `applyTranslateResize` for the full rationale.
                    updatedBuilder =
                        state.builder
                            |> Builder.updateBaselines animGroupName
                                (PropertyBaselines.setScale
                                    (Scale.fromRecord payload.command.end)
                                )
                in
                ( AnimState { state | builder = updatedBuilder } updatedAnimGroups
                , state.commandPort (encodeResize payload.command)
                )


computeScaleResizePayload :
    AnimGroupName
    -> Bounds
    -> Bounds
    -> AnimState msg
    ->
        Maybe
            { command :
                { animGroupName : AnimGroupName
                , property : String
                , start : { x : Float, y : Float, z : Float }
                , end : { x : Float, y : Float, z : Float }
                , current : { x : Float, y : Float, z : Float }
                , durationMs : Float
                , currentTimeMs : Maybe Float
                , hasAnimationBaseline : Bool
                , unit : Maybe String
                }
            , newSnapshot : PropertyBaselines
            , proportion : AnimGroup.AxisProportion
            }
computeScaleResizePayload animGroupName previousBounds bounds (AnimState state animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup
                in
                PropertyBaselines.getScale snapshot
                    |> Maybe.andThen
                        (\currentScale ->
                            let
                                resolvedBaseline =
                                    resolveScaleResizeBaseline animGroupName animGroup state.builder

                                hasAnimationBaseline =
                                    resolvedBaseline /= Nothing

                                baseline =
                                    resolvedBaseline
                                        |> Maybe.withDefault
                                            -- No animation config registered for this group's
                                            -- scale (init-only property). Synthesize a degenerate
                                            -- baseline from the current snapshot so `applyAxis`
                                            -- can clamp the value into the new bounds via its
                                            -- `oldRange == 0` branch. The snapshot update in
                                            -- `applyScaleResize` causes `WAAPI.attributes` to
                                            -- re-render the new transform inline.
                                            { start = Scale.toRecord currentScale
                                            , end = Scale.toRecord currentScale
                                            , durationMs = 0
                                            , proportion = AnimGroup.emptyProportion
                                            }
                            in
                            let
                                oldStart =
                                    baseline.start

                                oldEnd =
                                    baseline.end

                                oldCurrent =
                                    Scale.toRecord currentScale

                                rx =
                                    ResizeBuilder.applyAxis previousBounds.x bounds.x oldStart.x oldEnd.x oldCurrent.x

                                ry =
                                    ResizeBuilder.applyAxis previousBounds.y bounds.y oldStart.y oldEnd.y oldCurrent.y

                                rz =
                                    ResizeBuilder.applyAxis previousBounds.z bounds.z oldStart.z oldEnd.z oldCurrent.z

                                newStart =
                                    { x = rx.start, y = ry.start, z = rz.start }

                                newEnd =
                                    { x = rx.end, y = ry.end, z = rz.end }

                                -- Mirror translate: forward-axis proportion from frozen progress
                                -- + direction, so scale resize round-trips are exact (Bug 4).
                                direction =
                                    AnimGroup.getAnimationDirection animGroup

                                iter =
                                    AnimGroup.getCurrentIteration animGroup

                                progressValue =
                                    AnimGroup.getProgress animGroup

                                axisProportion =
                                    { x = proportionFromProgress direction iter progressValue oldStart.x oldEnd.x
                                    , y = proportionFromProgress direction iter progressValue oldStart.y oldEnd.y
                                    , z = proportionFromProgress direction iter progressValue oldStart.z oldEnd.z
                                    }

                                newCurrent =
                                    { x = applyProportionToBounds axisProportion.x bounds.x rx.current
                                    , y = applyProportionToBounds axisProportion.y bounds.y ry.current
                                    , z = applyProportionToBounds axisProportion.z bounds.z rz.current
                                    }

                                newDurationMs =
                                    scaleScaleDurationForResize
                                        { oldStart = baseline.start |> Scale.fromRecord
                                        , oldEnd = baseline.end |> Scale.fromRecord
                                        , newStart = Scale.fromRecord newStart
                                        , newEnd = Scale.fromRecord newEnd
                                        , oldDurationMs = baseline.durationMs
                                        }

                                oldCurrentTimeMs =
                                    currentTimeForResize
                                        { durationMs = baseline.durationMs
                                        , currentIteration = AnimGroup.getCurrentIteration animGroup
                                        , progress = AnimGroup.getProgress animGroup
                                        }

                                currentTimeMs =
                                    currentTimeForResize
                                        { durationMs = newDurationMs
                                        , currentIteration = AnimGroup.getCurrentIteration animGroup
                                        , progress = AnimGroup.getProgress animGroup
                                        }

                                noChange =
                                    translateRecordsNearlyEqual newStart baseline.start
                                        && translateRecordsNearlyEqual newEnd baseline.end
                                        && translateRecordsNearlyEqual newCurrent oldCurrent
                                        && floatNearlyEqual newDurationMs baseline.durationMs
                                        && maybeFloatNearlyEqual currentTimeMs oldCurrentTimeMs
                            in
                            if noChange then
                                Nothing

                            else
                                Just
                                    { command =
                                        { animGroupName = animGroupName
                                        , property = "scale"
                                        , start = newStart
                                        , end = newEnd
                                        , current = newCurrent
                                        , durationMs = newDurationMs
                                        , currentTimeMs = currentTimeMs
                                        , hasAnimationBaseline = hasAnimationBaseline
                                        , unit = Nothing
                                        }
                                    , newSnapshot =
                                        PropertyBaselines.setScale
                                            (Scale.fromRecord newCurrent)
                                            snapshot
                                    , proportion = axisProportion
                                    }
                        )
            )


{-| Scale's mirror of [`scaleDurationForResize`](#scaleDurationForResize).
-}
scaleScaleDurationForResize :
    { oldStart : Scale.Scale
    , oldEnd : Scale.Scale
    , newStart : Scale.Scale
    , newEnd : Scale.Scale
    , oldDurationMs : Float
    }
    -> Float
scaleScaleDurationForResize r =
    let
        oldDistance =
            Scale.distance r.oldStart r.oldEnd

        newDistance =
            Scale.distance r.newStart r.newEnd
    in
    if oldDistance > 0 && newDistance > 0 && r.oldDurationMs > 0 then
        (newDistance / oldDistance) * r.oldDurationMs

    else
        r.oldDurationMs


resolveScaleResizeBaseline :
    AnimGroupName
    -> AnimGroup
    -> Builder.AnimBuilder mode
    -> Maybe ResizeAxisState
resolveScaleResizeBaseline animGroupName animGroup builder =
    case AnimGroup.getResizeState "scale" animGroup of
        Just cached ->
            rejectDegenerateBaseline cached

        Nothing ->
            findCurrentScale animGroupName builder
                |> Maybe.map
                    (\cfg ->
                        let
                            startR =
                                cfg.start
                                    |> Maybe.withDefault Scale.default
                                    |> Scale.toRecord

                            endR =
                                Scale.toRecord cfg.end
                        in
                        { start = startR
                        , end = endR
                        , durationMs = toFloat cfg.duration
                        , proportion = AnimGroup.emptyProportion
                        }
                    )
                |> Maybe.andThen rejectDegenerateBaseline


findCurrentScale : AnimGroupName -> Builder.AnimBuilder mode -> Maybe (Builder.ProcessedAnimationConfig Scale.Scale)
findCurrentScale animGroupName builder =
    Builder.getAnimationConfigs animGroupName builder
        |> List.filterMap
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedScaleConfig cfg ->
                                    Just cfg

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )
        |> List.head


{-| Scale's mirror of [`rebaseTranslateConfig`](#rebaseTranslateConfig).
-}
rebaseScaleConfig :
    ResizeAxisState
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
rebaseScaleConfig cached config =
    case config of
        Builder.ProcessedScaleConfig cfg ->
            Builder.ProcessedScaleConfig
                { cfg
                    | start = Just (Scale.fromRecord cached.start)
                    , end = Scale.fromRecord cached.end
                    , duration = round cached.durationMs
                }

        _ ->
            config


applyPerspectiveOriginResize : AnimGroupName -> Bounds -> Bounds -> AnimState msg -> ( AnimState msg, Cmd msg )
applyPerspectiveOriginResize animGroupName previousBounds bounds ((AnimState state animGroups) as animState) =
    if ResizeBuilder.isEmpty bounds then
        ( animState, Cmd.none )

    else
        case computePerspectiveOriginResizePayload animGroupName previousBounds bounds animState of
            Nothing ->
                ( animState, Cmd.none )

            Just payload ->
                let
                    updatedAnimGroups =
                        AnimGroups.update animGroupName
                            (Maybe.map
                                (AnimGroup.setSnapshot payload.newSnapshot
                                    >> AnimGroup.setResizeState "perspectiveOrigin"
                                        { start = payload.command.start
                                        , end = payload.command.end
                                        , durationMs = payload.command.durationMs
                                        , proportion = payload.proportion
                                        }
                                )
                            )
                            animGroups

                    updatedBuilder =
                        state.builder
                            |> Builder.updateBaselines animGroupName
                                (PropertyBaselines.setPerspectiveOrigin payload.newBaseline)
                in
                ( AnimState { state | builder = updatedBuilder } updatedAnimGroups
                , state.commandPort (encodeResize payload.command)
                )


computePerspectiveOriginResizePayload :
    AnimGroupName
    -> Bounds
    -> Bounds
    -> AnimState msg
    ->
        Maybe
            { command :
                { animGroupName : AnimGroupName
                , property : String
                , start : { x : Float, y : Float, z : Float }
                , end : { x : Float, y : Float, z : Float }
                , current : { x : Float, y : Float, z : Float }
                , durationMs : Float
                , currentTimeMs : Maybe Float
                , hasAnimationBaseline : Bool
                , unit : Maybe String
                }
            , newSnapshot : PropertyBaselines
            , newBaseline : PerspectiveOrigin.PerspectiveOrigin
            , proportion : AnimGroup.AxisProportion
            }
computePerspectiveOriginResizePayload animGroupName previousBounds bounds (AnimState state animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                let
                    snapshot =
                        AnimGroup.getPropertySnapshot animGroup
                in
                PropertyBaselines.getPerspectiveOrigin snapshot
                    |> Maybe.andThen
                        (\currentPerspectiveOrigin ->
                            let
                                resolvedBaseline =
                                    resolvePerspectiveOriginResizeBaseline animGroupName animGroup state.builder

                                hasAnimationBaseline =
                                    resolvedBaseline /= Nothing

                                baseline =
                                    resolvedBaseline
                                        |> Maybe.withDefault
                                            -- No animation config registered for this group's
                                            -- perspective origin (init-only property). Synthesize
                                            -- a degenerate baseline from the current snapshot so
                                            -- `applyAxis` can still clamp the value into the new
                                            -- bounds via its `oldRange == 0` branch.
                                            (let
                                                cur =
                                                    PerspectiveOrigin.toRecord currentPerspectiveOrigin

                                                cur3d =
                                                    { x = cur.x, y = cur.y, z = 0 }
                                             in
                                             { start = cur3d
                                             , end = cur3d
                                             , durationMs = 0
                                             , proportion = AnimGroup.emptyProportion
                                             }
                                            )

                                oldStart =
                                    { x = baseline.start.x, y = baseline.start.y }

                                oldEnd =
                                    { x = baseline.end.x, y = baseline.end.y }

                                oldCurrent =
                                    PerspectiveOrigin.toRecord currentPerspectiveOrigin

                                rx =
                                    ResizeBuilder.applyAxis previousBounds.x bounds.x oldStart.x oldEnd.x oldCurrent.x

                                ry =
                                    ResizeBuilder.applyAxis previousBounds.y bounds.y oldStart.y oldEnd.y oldCurrent.y

                                newStart2d =
                                    { x = rx.start, y = ry.start }

                                newEnd2d =
                                    { x = rx.end, y = ry.end }

                                direction =
                                    AnimGroup.getAnimationDirection animGroup

                                iter =
                                    AnimGroup.getCurrentIteration animGroup

                                progressValue =
                                    AnimGroup.getProgress animGroup

                                axisProportion =
                                    { x = proportionFromProgress direction iter progressValue oldStart.x oldEnd.x
                                    , y = proportionFromProgress direction iter progressValue oldStart.y oldEnd.y
                                    , z = Nothing
                                    }

                                newCurrent2d =
                                    { x = applyProportionToBounds axisProportion.x bounds.x rx.current
                                    , y = applyProportionToBounds axisProportion.y bounds.y ry.current
                                    }

                                unit =
                                    -- Use the unit stored on the snapshot
                                    -- by `Generator.propertyBounds` when
                                    -- the animation was created, so a
                                    -- resize emits matching `px`/`%`/etc.
                                    -- suffixes on the keyframes JS rebuilds.
                                    PropertyBaselines.getPerspectiveOriginUnits snapshot
                                        |> Maybe.map .x
                                        |> Maybe.withDefault InternalUnit.default

                                liveOldStart2d =
                                    oldStart

                                liveOldEnd2d =
                                    oldEnd

                                newDurationMs =
                                    scalePerspectiveOriginDurationForResize
                                        { oldStart = PerspectiveOrigin.fromRecord liveOldStart2d
                                        , oldEnd = PerspectiveOrigin.fromRecord liveOldEnd2d
                                        , newStart = PerspectiveOrigin.fromRecord newStart2d
                                        , newEnd = PerspectiveOrigin.fromRecord newEnd2d
                                        , oldDurationMs = baseline.durationMs
                                        }

                                oldCurrentTimeMs =
                                    currentTimeForResize
                                        { durationMs = baseline.durationMs
                                        , currentIteration = AnimGroup.getCurrentIteration animGroup
                                        , progress = AnimGroup.getProgress animGroup
                                        }

                                currentTimeMs =
                                    currentTimeForResize
                                        { durationMs = newDurationMs
                                        , currentIteration = AnimGroup.getCurrentIteration animGroup
                                        , progress = AnimGroup.getProgress animGroup
                                        }

                                noChange =
                                    perspectiveOriginRecordsNearlyEqual newStart2d liveOldStart2d
                                        && perspectiveOriginRecordsNearlyEqual newEnd2d liveOldEnd2d
                                        && perspectiveOriginRecordsNearlyEqual newCurrent2d oldCurrent
                                        && floatNearlyEqual newDurationMs baseline.durationMs
                                        && maybeFloatNearlyEqual currentTimeMs oldCurrentTimeMs

                                unitStr =
                                    InternalUnit.toCssSuffix unit
                            in
                            if noChange then
                                Nothing

                            else
                                Just
                                    { command =
                                        { animGroupName = animGroupName
                                        , property = "perspectiveOrigin"
                                        , start = { x = newStart2d.x, y = newStart2d.y, z = 0 }
                                        , end = { x = newEnd2d.x, y = newEnd2d.y, z = 0 }
                                        , current = { x = newCurrent2d.x, y = newCurrent2d.y, z = 0 }
                                        , durationMs = newDurationMs
                                        , currentTimeMs = currentTimeMs
                                        , hasAnimationBaseline = hasAnimationBaseline
                                        , unit = Just unitStr
                                        }
                                    , newSnapshot =
                                        PropertyBaselines.setPerspectiveOrigin
                                            (PerspectiveOrigin.fromRecord newCurrent2d)
                                            snapshot
                                    , newBaseline = PerspectiveOrigin.fromRecord newEnd2d
                                    , proportion = axisProportion
                                    }
                        )
            )


{-| Like [`resolveScaleResizeBaseline`](#resolveScaleResizeBaseline) for
perspective origin. Prefers the AnimGroup's cached `currentPerspectiveOriginState`
so resize-rebased bounds persist across multiple resizes; otherwise
synthesizes a baseline from the most recent `animate` config.
-}
resolvePerspectiveOriginResizeBaseline :
    AnimGroupName
    -> AnimGroup
    -> Builder.AnimBuilder mode
    -> Maybe ResizeAxisState
resolvePerspectiveOriginResizeBaseline animGroupName animGroup builder =
    case AnimGroup.getResizeState "perspectiveOrigin" animGroup of
        Just cached ->
            rejectDegenerateBaseline cached

        Nothing ->
            findCurrentPerspectiveOrigin animGroupName builder
                |> Maybe.map
                    (\cfg ->
                        let
                            startR =
                                { x = cfg.start.x, y = cfg.start.y, z = 0 }

                            endR =
                                { x = cfg.end.x, y = cfg.end.y, z = 0 }
                        in
                        { start = startR
                        , end = endR
                        , durationMs = cfg.durationMs
                        , proportion = AnimGroup.emptyProportion
                        }
                    )
                |> Maybe.andThen rejectDegenerateBaseline


{-| Perspective origin's mirror of [`rebaseTranslateConfig`](#rebaseTranslateConfig).
-}
rebasePerspectiveOriginConfig :
    ResizeAxisState
    -> Builder.ProcessedPropertyConfig
    -> Builder.ProcessedPropertyConfig
rebasePerspectiveOriginConfig cached config =
    case config of
        Builder.ProcessedPerspectiveOriginConfig cfg ->
            Builder.ProcessedPerspectiveOriginConfig
                { cfg
                    | start = Just (PerspectiveOrigin.fromRecord { x = cached.start.x, y = cached.start.y })
                    , end = PerspectiveOrigin.fromRecord { x = cached.end.x, y = cached.end.y }
                    , duration = round cached.durationMs
                }

        _ ->
            config


findCurrentPerspectiveOrigin :
    AnimGroupName
    -> Builder.AnimBuilder mode
    -> Maybe { start : { x : Float, y : Float }, end : { x : Float, y : Float }, durationMs : Float }
findCurrentPerspectiveOrigin animGroupName builder =
    Builder.getAnimationConfigs animGroupName builder
        |> List.filterMap
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedPerspectiveOriginConfig cfg ->
                                    Just
                                        { start =
                                            cfg.start
                                                |> Maybe.withDefault PerspectiveOrigin.default
                                                |> PerspectiveOrigin.toRecord
                                        , end = PerspectiveOrigin.toRecord cfg.end
                                        , durationMs = toFloat cfg.duration
                                        }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )
        |> List.head


scalePerspectiveOriginDurationForResize :
    { oldStart : PerspectiveOrigin.PerspectiveOrigin
    , oldEnd : PerspectiveOrigin.PerspectiveOrigin
    , newStart : PerspectiveOrigin.PerspectiveOrigin
    , newEnd : PerspectiveOrigin.PerspectiveOrigin
    , oldDurationMs : Float
    }
    -> Float
scalePerspectiveOriginDurationForResize r =
    let
        oldDistance =
            PerspectiveOrigin.distance r.oldStart r.oldEnd

        newDistance =
            PerspectiveOrigin.distance r.newStart r.newEnd
    in
    if oldDistance > 0 && newDistance > 0 && r.oldDurationMs > 0 then
        (newDistance / oldDistance) * r.oldDurationMs

    else
        r.oldDurationMs



-- ============================================================
-- VIEW
-- ============================================================


{-| Get the list of HTML attributes to apply to an element for a given animation group.

The `data-anim-target` attribute allows the JavaScript companion to find the
element without requiring an HTML `id`. It is always present, even when no
animation is active, so the element is discoverable as soon as an animation
is triggered.

This also ensures initial values set via `init` are rendered synchronously,
avoiding a flash of unstyled content before JavaScript processes the port command.

-}
attributes : AnimGroupName -> AnimState msg -> List (Html.Attribute msg)
attributes animGroupName (AnimState state data) =
    let
        dataAttr =
            Html.Attributes.attribute "data-anim-target" animGroupName
    in
    case AnimGroups.get animGroupName data of
        Nothing ->
            [ dataAttr ]

        Just animGroup ->
            let
                snapshot =
                    AnimGroup.getPropertySnapshot animGroup

                propertyStates =
                    AnimGroup.getPropertyStates animGroup

                -- A property key is "JS-owned" once it has an entry in
                -- `propertyStates`. `Generator.init` only writes to the
                -- snapshot, leaving `propertyStates` empty for that key, so
                -- `init`-only properties remain Elm-owned. `WAAPI.animate`
                -- adds an entry, flipping ownership to JS for the lifetime
                -- of the group (JS `commitAnimatedStyles` keeps the visual
                -- after the animation finishes).
                isElmOwned propType =
                    not (AnimGroups.member propType propertyStates)

                simpleStyles =
                    List.filterMap identity
                        [ if isElmOwned "opacity" then
                            PropertyBaselines.getOpacity snapshot
                                |> Maybe.map (\o -> Html.Attributes.style "opacity" (Opacity.toString o))

                          else
                            Nothing
                        , if isElmOwned "perspectiveOrigin" then
                            PropertyBaselines.getPerspectiveOrigin snapshot
                                |> Maybe.map
                                    (\po ->
                                        Html.Attributes.style "perspective-origin"
                                            (PerspectiveOrigin.toCssString
                                                (PropertyBaselines.getPerspectiveOriginUnits snapshot
                                                    |> Maybe.withDefault
                                                        { x = Percent, y = Percent, z = Percent }
                                                )
                                                po
                                            )
                                    )

                          else
                            Nothing
                        ]

                sizeStyles =
                    if isElmOwned "size" then
                        PropertyBaselines.getSize snapshot
                            |> Maybe.map
                                (\s ->
                                    let
                                        sizeUnits =
                                            PropertyBaselines.getSizeUnits snapshot
                                                |> Maybe.withDefault
                                                    { x = InternalUnit.default, y = InternalUnit.default, z = InternalUnit.default }
                                    in
                                    [ Html.Attributes.style "width" (Size.widthToCssString sizeUnits s)
                                    , Html.Attributes.style "height" (Size.heightToCssString sizeUnits s)
                                    ]
                                )
                            |> Maybe.withDefault []

                    else
                        []

                customPropertyStyles =
                    PropertyBaselines.getAllCustomProperties snapshot
                        |> List.filter (\( name, _ ) -> isElmOwned ("custom:" ++ name))
                        |> List.map (\( name, cssValue ) -> Html.Attributes.style name cssValue)

                customColorPropertyStyles =
                    PropertyBaselines.getAllCustomColorProperties snapshot
                        |> List.filter (\( name, _ ) -> isElmOwned ("customColor:" ++ name))
                        |> List.map (\( name, color ) -> Html.Attributes.style name (Color.toCssString color))

                -- The CSS `transform` slot is monolithic: only one inline
                -- value can exist. We always emit it from the snapshot,
                -- which tracks the latest value for every sub-property
                -- (init values, the pre-animation start value merged in
                -- by `Generator.generateAnimation`, and per-frame
                -- `propertyUpdate` values from JS while WAAPI runs).
                --
                -- Emitting unconditionally closes the one-frame gap that
                -- existed when ownership of any sub-property flipped to
                -- JS: previously Elm dropped the `transform` attribute on
                -- that render, the browser could paint the element with
                -- no transform (collapsed to identity) before the JS
                -- bridge synchronously rewrote the inline style. The
                -- running CSS animation effect supersedes inline values
                -- during playback, and `commitAnimatedStyles` writes the
                -- final WAAPI value back to inline before `cancel()`,
                -- so re-emitting from the snapshot never produces a
                -- visible snap.
                transformStyles =
                    buildTransformStyles
                        (AnimGroup.getTransformOrder animGroup)
                        snapshot
                        (PropertyBaselines.getTranslateUnits snapshot
                            |> Maybe.withDefault
                                (findCurrentTranslate animGroupName state.builder
                                    |> Maybe.map .cssUnit
                                    |> Maybe.withDefault { x = InternalUnit.default, y = InternalUnit.default, z = InternalUnit.default }
                                )
                        )
            in
            dataAttr
                :: transformStyles
                ++ simpleStyles
                ++ sizeStyles
                ++ customPropertyStyles
                ++ customColorPropertyStyles
                ++ discreteEntryStyles animGroup
                ++ discreteExitStyles animGroup


buildTransformStyles : List TransformProperty -> PropertyBaselines -> InternalUnit.ResolvedCssUnitAxes -> List (Html.Attribute msg)
buildTransformStyles order snapshot translateLength =
    let
        translatePart =
            PropertyBaselines.getTranslate snapshot
                |> Maybe.map (Translate.toCssString translateLength)
                |> Maybe.withDefault ""

        rotatePart =
            PropertyBaselines.getRotate snapshot
                |> Maybe.map Rotate.toCssString
                |> Maybe.withDefault ""

        scalePart =
            PropertyBaselines.getScale snapshot
                |> Maybe.map Scale.toCssString
                |> Maybe.withDefault ""

        skewPart =
            PropertyBaselines.getSkew snapshot
                |> Maybe.map Skew.toCssString
                |> Maybe.withDefault ""

        transformString =
            order
                |> List.map (transformOrderToPart translatePart rotatePart skewPart scalePart)
                |> List.filter (not << String.isEmpty)
                |> String.join " "
    in
    if String.isEmpty transformString then
        []

    else
        [ Html.Attributes.style "transform" transformString ]


{-| Convert a TransformProperty to its corresponding CSS string part.
-}
transformOrderToPart : String -> String -> String -> String -> TransformProperty -> String
transformOrderToPart translatePart rotatePart skewPart scalePart order =
    case order of
        TransformProperty.Translate ->
            translatePart

        TransformProperty.Rotate ->
            rotatePart

        TransformProperty.Skew ->
            skewPart

        TransformProperty.Scale ->
            scalePart


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles =
    AnimGroup.getDiscreteEntry
        >> Dict.toList
        >> List.map (\( prop, value ) -> Html.Attributes.style prop value)


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    animGroup
        |> AnimGroup.getDiscreteExit
        |> Dict.toList
        |> List.map
            (\( prop, { from, to } ) ->
                if AnimGroup.isComplete animGroup then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
iterations =
    Builder.iterations


loopForever : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
loopForever =
    Builder.loopForever


alternate : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
alternate =
    Builder.alternate



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
delay =
    Builder.delay


duration : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
duration =
    Builder.duration


speed : Float -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
speed =
    Builder.speed



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
easing =
    Builder.easing



-- ============================================================
-- UNIT
-- ============================================================


cssUnit : Unit -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
cssUnit =
    Builder.cssUnit


cssUnitX : Unit -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
cssUnitX =
    Builder.cssUnitX


cssUnitY : Unit -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
cssUnitY =
    Builder.cssUnitY


cssUnitZ : Unit -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
cssUnitZ =
    Builder.cssUnitZ



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
spring =
    Builder.spring



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop animGroupName (AnimState state animGroups) =
    let
        endStates =
            Builder.getCurrentAnimationConfig animGroupName state.builder
                |> Maybe.map (.properties >> Generator.propertyBounds >> .end)
                |> Maybe.withDefault PropertyBaselines.empty

        updatedElementAnimations =
            AnimGroups.update animGroupName
                (Maybe.map
                    (\anim ->
                        AnimGroup.setSnapshot
                            (PropertyBaselines.merge
                                (AnimGroup.getPropertySnapshot anim)
                                endStates
                            )
                            anim
                    )
                )
                animGroups
    in
    ( AnimState state updatedElementAnimations
    , state.commandPort <|
        encodeCommandWithProperties "stop" animGroupName Nothing
    )


pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause animGroupName (AnimState state animGroups) =
    ( AnimState state animGroups
    , state.commandPort <|
        encodeCommandWithProperties "pause" animGroupName Nothing
    )


reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset animGroupName animState =
    resetSingleKey animGroupName animState


resetSingleKey : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
resetSingleKey animGroupName (AnimState state animGroups) =
    case Builder.getCurrentAnimationConfig animGroupName state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just { properties } ->
            let
                startStates =
                    (Generator.propertyBounds properties).start

                propertyConfigs : List ( String, Builder.ProcessedPropertyConfig )
                propertyConfigs =
                    List.map (\p -> ( Generator.propertyTypeString p, p )) properties

                resetCmd =
                    state.commandPort <|
                        encodeCommandWithProperties "reset" animGroupName Nothing
            in
            case AnimGroups.get animGroupName animGroups of
                Nothing ->
                    let
                        newPropertyStates =
                            propertyConfigs
                                |> List.map
                                    (\( propType, config ) ->
                                        ( propType
                                        , { version = 1
                                          , status = AnimGroup.NotStarted
                                          , config = config
                                          }
                                        )
                                    )
                                |> AnimGroups.fromList

                        newAnimGroup =
                            AnimGroup.init
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates newPropertyStates
                    in
                    ( AnimState
                        { state | subscriptionsActive = False }
                        (AnimGroups.insert animGroupName newAnimGroup animGroups)
                    , resetCmd
                    )

                Just animGroup ->
                    let
                        -- Bump versions so any in-flight `propertyUpdate` from
                        -- the now-cancelled animation is rejected as stale.
                        -- Config is refreshed only to satisfy `bumpPropertyVersions`;
                        -- no animation will be run against it after a reset.
                        resetAnimGroup =
                            animGroup
                                |> AnimGroup.bumpPropertyVersions propertyConfigs
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setProgress 0

                        updatedAnimGroups =
                            AnimGroups.insert animGroupName resetAnimGroup animGroups
                    in
                    ( AnimState
                        { state
                            | subscriptionsActive =
                                AnimGroups.groups updatedAnimGroups
                                    |> List.any AnimGroup.isRunning
                        }
                        updatedAnimGroups
                    , resetCmd
                    )


restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart animGroup animState =
    restartSingleKey animGroup animState


restartSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restartSingleKey resolvedKey (AnimState state animGroups) =
    case Builder.getCurrentAnimationConfig resolvedKey state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just processedData ->
            -- Get properties that are being restarted
            let
                startStates =
                    (Generator.propertyBounds processedData.properties).start
            in
            case AnimGroups.get resolvedKey animGroups of
                Nothing ->
                    -- No tracking entry exists, create one with property versions
                    let
                        newProperties =
                            processedData.properties
                                |> List.map (\p -> ( Generator.propertyTypeString p, { version = 1, status = AnimGroup.NotStarted, config = p } ))
                                |> AnimGroups.fromList

                        newAnimGroup =
                            AnimGroup.init
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates newProperties

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newAnimGroup animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestart
                            (AnimGroup.getIterations newAnimGroup)
                            (AnimGroup.getAnimationDirection newAnimGroup)
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey processedData)
                    )

                Just animGroup ->
                    -- Update existing entry, incrementing versions for restarted properties
                    let
                        -- A previous resize may have shifted resize-aware
                        -- property bounds since the original `animate` call.
                        -- The cached state per property is the resize-aware
                        -- truth (computed via `Resize.applyAxis` and stored
                        -- on the group); use it to override the stale
                        -- `start`/`end`/`duration` baked into `processedData`,
                        -- otherwise Restart re-animates to the original
                        -- (pre-resize) target. Dispatch by property name —
                        -- adding a new resize-aware property only requires
                        -- extending `rebaseFor` below.
                        rebasedProcessedData =
                            AnimGroup.foldResizeStates
                                (\propName cached acc ->
                                    case rebaseFor propName of
                                        Just rebase ->
                                            { acc
                                                | properties =
                                                    List.map (rebase cached) acc.properties
                                            }

                                        Nothing ->
                                            acc
                                )
                                processedData
                                animGroup

                        rebasedStartStates =
                            (Generator.propertyBounds rebasedProcessedData.properties).start

                        updatedProperties =
                            rebasedProcessedData.properties
                                |> List.foldl
                                    (\property acc ->
                                        let
                                            propType =
                                                Generator.propertyTypeString property

                                            newVersion =
                                                animGroup
                                                    |> AnimGroup.getPropertyStates
                                                    |> AnimGroups.get propType
                                                    |> Maybe.map .version
                                                    |> Maybe.map ((+) 1)
                                                    |> Maybe.withDefault 1
                                        in
                                        AnimGroups.insert propType
                                            { version = newVersion, status = AnimGroup.NotStarted, config = property }
                                            acc
                                    )
                                    (AnimGroup.getPropertyStates animGroup)

                        resetElementAnimation =
                            animGroup
                                |> AnimGroup.setSnapshot rebasedStartStates
                                |> AnimGroup.setPropertyStates updatedProperties
                                |> AnimGroup.setProgress 0

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey resetElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestart
                            (AnimGroup.getIterations animGroup)
                            (AnimGroup.getAnimationDirection animGroup)
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey rebasedProcessedData)
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume animGroup (AnimState state animGroups) =
    ( AnimState state animGroups
    , state.commandPort <|
        encodeCommandWithProperties "resume" animGroup Nothing
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



-- ============================================================
-- FREEZE
-- ============================================================


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


allComplete : AnimState msg -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        AnimGroups.groups animGroups
            |> List.all AnimGroup.isComplete
            |> Just


anyRunning : AnimState msg -> Maybe Bool
anyRunning (AnimState state animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        Just state.subscriptionsActive


isComplete : AnimGroupName -> AnimState msg -> Maybe Bool
isComplete animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.isComplete


getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.getProgress


isRunning : AnimGroupName -> AnimState msg -> Maybe Bool
isRunning animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.isRunning



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================


getBuilder : AnimState msg -> EngineBuilder
getBuilder (AnimState state _) =
    state.builder



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomPropertyEnd animGroupName cssName


getPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyCurrent animGroupName cssName (AnimState _ animGroups) =
    getSnapshotProperty (PropertyBaselines.getCustomProperty cssName) animGroupName animGroups


{-| Pull a property value out of a group's current snapshot, if the group
exists and the snapshot has a value for the requested property.
-}
getSnapshotProperty :
    (PropertyBaselines.PropertyBaselines -> Maybe a)
    -> AnimGroupName
    -> AnimGroups.AnimGroups AnimGroup.AnimGroup
    -> Maybe a
getSnapshotProperty getter animGroupName animGroups =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> getter)


getPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomPropertyRange animGroupName cssName



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


getColorPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyEnd animGroupName cssName


getColorPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyCurrent animGroupName cssName (AnimState _ animGroups) =
    getSnapshotProperty (PropertyBaselines.getCustomColorProperty cssName) animGroupName animGroups


getColorPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getBuilder >> Property.getCustomColorPropertyRange animGroupName cssName



-- ============================
-- OPACITY
-- ============================


getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart animGroupName =
    getBuilder >> Property.getOpacityStart animGroupName


getOpacityEnd : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityEnd animGroupName =
    getBuilder >> Property.getOpacityEnd animGroupName


getOpacityCurrent : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getOpacity animGroupName animGroups
        |> Maybe.map Opacity.toFloat


getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName =
    getBuilder >> Property.getOpacityRange animGroupName



-- ============================
-- ROTATE
-- ============================


getRotateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getBuilder >> Property.getRotateStart animGroupName


getRotateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getBuilder >> Property.getRotateEnd animGroupName


getRotateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getRotate animGroupName animGroups
        |> Maybe.map Rotate.toRecord


getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName =
    getBuilder >> Property.getRotateRange animGroupName



-- ============================
-- SCALE
-- ============================


getScaleStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName state =
    case getRuntimeScale animGroupName state of
        Just cfg ->
            Just cfg.start

        Nothing ->
            (getBuilder >> Property.getScaleStart animGroupName) state


getScaleEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName state =
    case getRuntimeScale animGroupName state of
        Just cfg ->
            Just cfg.end

        Nothing ->
            (getBuilder >> Property.getScaleEnd animGroupName) state


getScaleCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getScale animGroupName animGroups
        |> Maybe.map Scale.toRecord


getScaleRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName state =
    case getRuntimeScale animGroupName state of
        Just cfg ->
            Just { start = Just cfg.start, end = cfg.end }

        Nothing ->
            (getBuilder >> Property.getScaleRange animGroupName) state


{-| Look up the live post-resize scale state for a group, if any.

Scale is one of the properties whose runtime state can diverge from the
builder snapshot (via [`onResize`](#onResize) or a mid-animation policy swap),
so its getters consult the runtime first and fall back to the builder.

-}
getRuntimeScale : AnimGroupName -> AnimState msg -> Maybe AnimGroup.ResizeAxisState
getRuntimeScale animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getResizeState "scale")



-- ============================
-- SIZE
-- ============================


getSizeStart : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart animGroupName =
    getBuilder >> Property.getSizeStart animGroupName


getSizeEnd : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName =
    getBuilder >> Property.getSizeEnd animGroupName


getSizeCurrent : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getSize animGroupName animGroups
        |> Maybe.map Size.toRecord


getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName =
    getBuilder >> Property.getSizeRange animGroupName



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


getPerspectiveOriginStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart animGroupName state =
    case getRuntimePerspectiveOrigin animGroupName state of
        Just cfg ->
            Just { x = cfg.start.x, y = cfg.start.y }

        Nothing ->
            (getBuilder >> Property.getPerspectiveOriginStart animGroupName) state


getPerspectiveOriginEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd animGroupName state =
    case getRuntimePerspectiveOrigin animGroupName state of
        Just cfg ->
            Just { x = cfg.end.x, y = cfg.end.y }

        Nothing ->
            (getBuilder >> Property.getPerspectiveOriginEnd animGroupName) state


getPerspectiveOriginCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getPerspectiveOriginCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getPerspectiveOrigin animGroupName animGroups
        |> Maybe.map PerspectiveOrigin.toRecord


getPerspectiveOriginRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange animGroupName state =
    case getRuntimePerspectiveOrigin animGroupName state of
        Just cfg ->
            Just
                { start = Just { x = cfg.start.x, y = cfg.start.y }
                , end = { x = cfg.end.x, y = cfg.end.y }
                }

        Nothing ->
            (getBuilder >> Property.getPerspectiveOriginRange animGroupName) state


{-| Look up the live post-resize perspective-origin state for a group, if
any.

Like Translate and Scale, PerspectiveOrigin's runtime state can diverge
from the builder snapshot via [`onResize`](#onResize) or a mid-animation
policy swap, so its getters consult the runtime first and fall back to
the builder. The cached state's `z` component is unused and always 0.

-}
getRuntimePerspectiveOrigin : AnimGroupName -> AnimState msg -> Maybe AnimGroup.ResizeAxisState
getRuntimePerspectiveOrigin animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getResizeState "perspectiveOrigin")



-- ============================
-- SKEW
-- ============================


getSkewStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewStart animGroupName =
    getBuilder >> Property.getSkewStart animGroupName


getSkewEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewEnd animGroupName =
    getBuilder >> Property.getSkewEnd animGroupName


getSkewCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getSkew animGroupName animGroups
        |> Maybe.map Skew.toRecord


getSkewRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange animGroupName =
    getBuilder >> Property.getSkewRange animGroupName



-- ============================
-- TRANSLATE
-- ============================


getTranslateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just cfg.start

        Nothing ->
            (getBuilder >> Property.getTranslateStart animGroupName) state


getTranslateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just cfg.end

        Nothing ->
            (getBuilder >> Property.getTranslateEnd animGroupName) state


getTranslateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent animGroupName (AnimState _ animGroups) =
    getSnapshotProperty PropertyBaselines.getTranslate animGroupName animGroups
        |> Maybe.map Translate.toRecord


getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName state =
    case getRuntimeTranslate animGroupName state of
        Just cfg ->
            Just { start = Just cfg.start, end = cfg.end }

        Nothing ->
            (getBuilder >> Property.getTranslateRange animGroupName) state


{-| Look up the live post-resize translate state for a group, if any.

Translate is one of the properties whose runtime state can diverge from the
builder snapshot (via [`onResize`](#onResize) or a mid-animation policy swap),
so its getters consult the runtime first and fall back to the builder.

-}
getRuntimeTranslate : AnimGroupName -> AnimState msg -> Maybe AnimGroup.ResizeAxisState
getRuntimeTranslate animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getResizeState "translate")



-- ============================
-- DECODERS
-- ============================


type alias AnimationUpdate =
    { animGroupName : String
    , progress : Float
    , isAnimating : Bool
    , propertyVersions : AnimGroups Int -- Maps property type to version number
    , propertyProgress : Dict.Dict String Float -- Per-property raw progress for Elm-side interpolation
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.oneOf [ Decode.field "animGroup" Decode.string, Decode.field "elementId" Decode.string ])
        |> andMap (Decode.oneOf [ Decode.field "progress" Decode.float, Decode.succeed 0 ])
        |> andMap (Decode.field "isAnimating" Decode.bool)
        |> andMap propertyVersionDecoder
        |> andMap (Decode.oneOf [ Decode.field "propertyProgress" (Decode.dict Decode.float), Decode.succeed Dict.empty ])


propertyVersionDecoder : Decoder (AnimGroups Int)
propertyVersionDecoder =
    Decode.field "propertyVersions" (Decode.dict Decode.int)
        |> Decode.map AnimGroups.fromDict


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
