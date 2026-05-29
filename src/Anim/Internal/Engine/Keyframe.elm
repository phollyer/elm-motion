module Anim.Internal.Engine.Keyframe exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
    , EngineBuilder
    , TimelineBuilder
    , animate
    , attributes
    , events
    , eventsStopPropagation
    , init
    , maybeKeyframesString
    , pause
    , reset
    , restart
    , resume
    , retarget
    , stop
    , styleNode
    , styleNodeFor
    , transformOrder
    , update
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS exposing (AnimState(..))
import Anim.Internal.Engine.CSS.Styles exposing (Styles)
import Anim.Internal.Engine.Keyframe.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Keyframe.Animation as Animation
import Anim.Internal.Engine.Keyframe.Generator as Generator exposing (DiscreteConfig)
import Anim.Internal.Engine.Keyframe.Styles as KeyframeStyles
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Extra.Color exposing (Color(..))
import Anim.Internal.Property.Opacity exposing (Opacity(..))
import Anim.Internal.Property.Size exposing (Size(..))
import Dict
import Html exposing (Html)
import Html.Attributes
import Shared.TimeSpec exposing (TimeSpec(..))
import Task



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimState =
    CSS.AnimState Builder.ForKeyframeEngine AnimGroup


type alias AnimGroupName =
    String


type alias TimelineBuilder engine =
    CSS.TimelineBuilder engine


type alias EngineBuilder =
    TimelineBuilder Builder.ForKeyframeEngine



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    let
        initGroup : EngineBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
        initGroup builder name config =
            let
                discrete : DiscreteConfig
                discrete =
                    { entry = Builder.getDiscreteEntryProperties builder
                    , exit = Builder.getDiscreteExitProperties builder
                    }

                resolvedOrder =
                    case config.transformOrder of
                        Just _ ->
                            config.transformOrder

                        Nothing ->
                            Builder.getTransformOrder name builder
            in
            Generator.init
                resolvedOrder
                (Builder.getIterations builder)
                (Builder.getAnimationDirection builder)
                discrete
                name
                config.properties
    in
    CSS.init initGroup



-- ============================================================
-- TRIGGER
-- ============================================================


animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate (AnimState state animGroups) transform =
    let
        builder =
            transform state.builder

        processedAnimData =
            Builder.process builder

        setPlayStateWithStyle : PlayState.PlayState -> AnimGroup -> AnimGroup
        setPlayStateWithStyle playState animGroup =
            animGroup
                |> AnimGroup.setPlayState playState
                |> AnimGroup.addStyle "animation-play-state" (PlayState.toCssString playState)

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup animGroupName config =
            let
                discrete : DiscreteConfig
                discrete =
                    { entry = Builder.getDiscreteEntryProperties builder
                    , exit = Builder.getDiscreteExitProperties builder
                    }

                currentCounter =
                    AnimGroups.get animGroupName animGroups
                        |> Maybe.map AnimGroup.getRestartCounter
                        |> Maybe.withDefault 0
            in
            Generator.generateRestart
                currentCounter
                config.transformOrder
                (Builder.getIterations builder)
                (Builder.getAnimationDirection builder)
                (Builder.getBaseline animGroupName builder)
                discrete
                animGroupName
                config.properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName newAnimGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName newAnimGroup acc

                Just currentGroup ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.mergeStyles newAnimGroup currentGroup)
                        acc
    in
    AnimState
        { builder =
            builder
                |> Builder.addAnimationToHistory processedAnimData
                |> Builder.mergeBaselines
                |> Builder.clearAnimData
        }
        (processedAnimData.groups
            |> AnimGroups.map generateAnimGroup
            |> AnimGroups.foldl insertAnimGroup animGroups
            |> AnimGroups.map (\_ animGroup -> setPlayStateWithStyle PlayState.Running animGroup)
        )


{-| Re-anchor an animation to a new target by snapping to the new end values.

The Keyframe engine drives animations entirely through CSS @keyframes
rules and has no JavaScript-side runtime snapshot of the currently
rendered values. That makes it impossible to smoothly continue an
in-flight keyframe animation when the target changes mid-flight (typical
of resize handlers).

`retarget` therefore guarantees a deterministic outcome: the build is
processed to compute the new end values, the keyframe animation is
cleared, and those end values are written inline. The element ends up
exactly where the new builder placed it - safe to call repeatedly during
a drag or resize without accumulating partial animations.

If you need smooth visual continuity instead of a snap, use the `Sub` or
`WAAPI` engines, both of which keep a runtime snapshot of the current
animated value and can interpolate from it.

-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget ((AnimState origState _) as animState) build =
    let
        touchedGroups =
            (Builder.process (build origState.builder)).groups

        animatedState =
            animate animState build
    in
    AnimGroups.foldl
        (\name _ acc -> stop name acc)
        animatedState
        touchedGroups



-- ============================================================
-- EVENTS
-- ============================================================


type alias CurrentTargetId =
    Maybe String


type alias TargetId =
    Maybe String


type alias Counter =
    Int


type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName Counter
    | Paused AnimGroupName
    | Resumed AnimGroupName
    | Restarted AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = GotStarted AnimGroupName CSS.SourceEventData
    | GotEnded AnimGroupName CSS.SourceEventData
    | GotCancelled AnimGroupName CSS.SourceEventData
    | GotIteration AnimGroupName CSS.SourceEventData
    | GotPaused AnimGroupName
    | GotResumed AnimGroupName
    | GotRestarted AnimGroupName
    | GotRun AnimGroupName CSS.SourceEventData


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    case animMsg of
        GotPaused animGroupName ->
            ( animState, Paused animGroupName )

        GotResumed animGroupName ->
            ( animState, Resumed animGroupName )

        GotRestarted animGroupName ->
            ( animState, Restarted animGroupName )

        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationStarted animGroupName) animState
            , Started currentTargetId targetId animGroupName
            )

        GotRun animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationRun animGroupName) animState
            , Run currentTargetId targetId animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationEnded animGroupName) animState
            , Ended currentTargetId targetId animGroupName
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationCancelled animGroupName) animState
            , Cancelled currentTargetId targetId animGroupName
            )

        GotIteration animGroupName { currentTargetId, targetId } ->
            let
                (AnimState state animGroups) =
                    animState
                        |> CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationIteration animGroupName)
                        |> incrementIterationCount animGroupName

                count =
                    AnimGroups.get animGroupName animGroups
                        |> Maybe.map AnimGroup.getIterationCount
                        |> Maybe.withDefault 0
            in
            ( AnimState state animGroups
            , Iteration currentTargetId targetId animGroupName count
            )


incrementIterationCount : AnimGroupName -> AnimState -> AnimState
incrementIterationCount animGroupName (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map AnimGroup.incrementIterationCount)
            animGroups



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName ((AnimState _ animGroups) as animState) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            let
                animationAttribute =
                    case AnimGroup.getAnimation animGroup of
                        Just anim ->
                            Animation.toCssString anim

                        Nothing ->
                            "none"

                willChangePairs =
                    -- `will-change` promotes the animated properties to
                    -- their own compositor layer ahead of the keyframes
                    -- starting. We clear it once the animation finishes
                    -- (infinite loops never reach this branch) so the
                    -- element doesn't keep paying the layer cost forever.
                    if AnimGroup.isComplete animGroup then
                        []

                    else
                        case AnimGroup.getWillChange animGroup of
                            "" ->
                                []

                            value ->
                                [ ( "will-change", value ) ]
            in
            CSS.attributes
                (( "animation", animationAttribute ) :: willChangePairs)
                AnimGroup.getStyles
                animGroupName
                animState
                ++ discreteEntryStyles animGroup
                ++ discreteExitStyles animGroup


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles =
    AnimGroup.getDiscreteEntry
        >> Dict.toList
        >> List.map (\( prop, value ) -> Html.Attributes.style prop value)


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


styleNode : AnimState -> Html msg
styleNode (AnimState _ animGroups) =
    let
        allKeyframes =
            AnimGroups.groups animGroups
                |> List.filterMap AnimGroup.getAnimation
                |> List.map Animation.getKeyframes
    in
    case allKeyframes of
        [] ->
            Html.text ""

        _ ->
            Html.node "style" [] <|
                [ Html.text <|
                    String.join "\n\n" allKeyframes
                ]


styleNodeFor : AnimGroupName -> AnimState -> Html msg
styleNodeFor animGroupName (AnimState _ animGroups) =
    let
        keyframes =
            AnimGroups.get animGroupName animGroups
                |> Maybe.andThen AnimGroup.getAnimation
                |> Maybe.map Animation.getKeyframes
                |> Maybe.withDefault ""
    in
    Html.node "style" [] [ Html.text keyframes ]


maybeKeyframesString : AnimGroupName -> AnimState -> Maybe String
maybeKeyframesString animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen AnimGroup.getAnimation
        |> Maybe.map Animation.getKeyframes



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ CSS.onEvent "animationstart" toMsg GotStarted
    , CSS.onEvent "animationend" toMsg GotEnded
    , CSS.onEvent "animationcancel" toMsg GotCancelled
    , CSS.onEvent "animationiteration" toMsg GotIteration
    , CSS.onEvent "animationrun" toMsg GotRun
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ CSS.onEventStopPropagation "animationstart" toMsg GotStarted
    , CSS.onEventStopPropagation "animationend" toMsg GotEnded
    , CSS.onEventStopPropagation "animationcancel" toMsg GotCancelled
    , CSS.onEventStopPropagation "animationiteration" toMsg GotIteration
    , CSS.onEventStopPropagation "animationrun" toMsg GotRun
    ]



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState -> AnimState
stop =
    CSS.stop
        AnimGroup.setPlayState
        AnimGroup.isActive
        (KeyframeStyles.fromProcessedProperties Nothing Nothing)
        setStyles


reset : AnimGroupName -> AnimState -> AnimState
reset =
    CSS.reset
        AnimGroup.setPlayState
        (KeyframeStyles.fromProcessedProperties Nothing Nothing)
        setStyles


setStyles : Styles -> AnimGroup
setStyles styles =
    AnimGroup.setStyles styles AnimGroup.init


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg ((AnimState state _) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimationConfig animGroupName state.builder
    in
    case maybeFromHistory of
        Nothing ->
            ( animState, Cmd.none )

        Just { properties } ->
            ( restartAnimation animGroupName properties animState
            , toCmd animGroupName toMsg GotRestarted
            )


restartAnimation : AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimState -> AnimState
restartAnimation animGroupName properties (AnimState state animGroups) =
    let
        counter =
            AnimGroups.get animGroupName animGroups
                |> Maybe.map AnimGroup.getRestartCounter
                |> Maybe.withDefault 0

        discrete : DiscreteConfig
        discrete =
            { entry = Builder.getDiscreteEntryProperties state.builder
            , exit = Builder.getDiscreteExitProperties state.builder
            }

        animGroup =
            Generator.generateRestart
                counter
                (Builder.getTransformOrder animGroupName state.builder)
                (Builder.getIterations state.builder)
                (Builder.getAnimationDirection state.builder)
                (Builder.getBaseline animGroupName state.builder)
                discrete
                animGroupName
                properties
    in
    AnimState state animGroups
        |> reset animGroupName
        |> updateAnimGroup animGroupName animGroup
        |> setPlayState animGroupName PlayState.Running


updateAnimGroup : AnimGroupName -> AnimGroup -> AnimState -> AnimState
updateAnimGroup animGroupName animGroup (AnimState state animGroups) =
    AnimState state <|
        AnimGroups.insert animGroupName animGroup animGroups


pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    case CSS.isRunning AnimGroup.isRunning animGroupName animState of
        Just True ->
            ( setPlayState animGroupName PlayState.Paused animState
            , toCmd animGroupName toMsg GotPaused
            )

        _ ->
            ( animState, Cmd.none )


resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    case CSS.isPaused AnimGroup.isPaused animGroupName animState of
        Just True ->
            ( setPlayState animGroupName PlayState.Running animState
            , toCmd animGroupName toMsg GotResumed
            )

        _ ->
            ( animState, Cmd.none )


setPlayState : AnimGroupName -> PlayState.PlayState -> AnimState -> AnimState
setPlayState animGroupName playState (AnimState state animGroups) =
    let
        playStateStr =
            PlayState.toCssString playState
    in
    AnimState state <|
        AnimGroups.update animGroupName
            (Maybe.map <|
                \animGroup ->
                    animGroup
                        |> AnimGroup.setPlayState playState
                        |> AnimGroup.addStyle "animation-play-state" playStateStr
            )
            animGroups


toCmd : AnimGroupName -> (AnimMsg -> msg) -> (String -> AnimMsg) -> Cmd msg
toCmd animGroupName toMsg animMsg =
    Task.succeed (toMsg (animMsg animGroupName))
        |> Task.perform identity



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Builder.transformOrder
