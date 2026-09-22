module Anim.Internal.Engine.Keyframe exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
    , EngineBuilder
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
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
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
import Set
import Shared.TimeSpec exposing (TimeSpec(..))
import Task



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimState =
    CSS.AnimState Builder.ForKeyframe AnimGroup


type alias AnimGroupName =
    String


type alias EngineBuilder =
    Builder.AnimBuilder Builder.ForKeyframe



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (EngineBuilder -> EngineBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init [] }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                processedGroups =
                    Builder.process builder
                        |> .groups

                initGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
                initGroup name config =
                    let
                        discrete : DiscreteConfig
                        discrete =
                            { entry = Builder.getDiscreteEntryPropertiesFor name builder
                            , exit = Builder.getDiscreteExitPropertiesFor name builder
                            }

                        playback =
                            Builder.resolvePlayback
                                (Builder.getIterations builder)
                                (Builder.getAnimationDirection builder)
                                config.playback
                    in
                    Generator.generateAnimation
                        config.transformOrder
                        playback.iterations
                        playback.animationDirection
                        discrete
                        name
                        config.controlledAxes
                        config.properties
            in
            AnimState
                { builder =
                    builder
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                }
                (AnimGroups.map initGroup processedGroups)



-- ============================================================
-- TRIGGER
-- ============================================================


animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    runPipeline
        (\builder processed ->
            builder
                |> Builder.addAnimationToHistory processed
                |> Builder.mergeBaselines
                |> Builder.clearAnimData
        )


retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget ((AnimState origState _) as animState) build =
    let
        touchedGroups =
            (Builder.process (build origState.builder)).groups

        retargetedState =
            runPipeline
                (\builder processed ->
                    builder
                        |> Builder.addRetargetToHistory processed
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                )
                animState
                build
    in
    AnimGroups.foldl
        (\name _ acc -> stop name acc)
        retargetedState
        touchedGroups


runPipeline :
    (EngineBuilder -> Builder.ProcessedAnimationData -> EngineBuilder)
    -> AnimState
    -> (EngineBuilder -> EngineBuilder)
    -> AnimState
runPipeline finaliseBuilder (AnimState state animGroups) transform =
    let
        builder =
            transform state.builder

        processedAnimData =
            Builder.process builder

        hasAnimateTiming : Builder.ProcessedAnimGroupConfig -> Bool
        hasAnimateTiming config =
            (Builder.partitionByMode config.properties).animate
                |> List.any
                    (\prop ->
                        let
                            timing =
                                Builder.processedTimings prop
                        in
                        timing.duration > 0 || timing.delay > 0
                    )

        initialPlayStateFor : AnimGroupName -> PlayState.PlayState
        initialPlayStateFor animGroupName =
            processedAnimData.groups
                |> AnimGroups.get animGroupName
                |> Maybe.map
                    (\config ->
                        if hasAnimateTiming config then
                            PlayState.Running

                        else
                            PlayState.Complete
                    )
                |> Maybe.withDefault PlayState.Running

        setPlayStateWithStyle : PlayState.PlayState -> AnimGroup -> AnimGroup
        setPlayStateWithStyle playState animGroup =
            let
                cssValue =
                    PlayState.toCssString playState
            in
            if String.isEmpty cssValue then
                animGroup
                    |> AnimGroup.setPlayState playState
                    |> (\group ->
                            AnimGroup.setStyles
                                (AnimGroup.getStyles group
                                    |> Styles.remove "animation-play-state"
                                )
                                group
                       )

            else
                animGroup
                    |> AnimGroup.setPlayState playState
                    |> AnimGroup.addStyle "animation-play-state" cssValue

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup animGroupName config =
            let
                discrete : DiscreteConfig
                discrete =
                    { entry = Builder.getDiscreteEntryPropertiesFor animGroupName builder
                    , exit = Builder.getDiscreteExitPropertiesFor animGroupName builder
                    }

                currentCounter =
                    AnimGroups.get animGroupName animGroups
                        |> Maybe.map AnimGroup.getRestartCounter
                        |> Maybe.withDefault 0
            in
            let
                playback =
                    Builder.resolvePlayback
                        (Builder.getIterations builder)
                        (Builder.getAnimationDirection builder)
                        config.playback
            in
            Generator.generateRestart
                currentCounter
                config.transformOrder
                playback.iterations
                playback.animationDirection
                (Builder.getBaseline animGroupName builder)
                discrete
                animGroupName
                config.controlledAxes
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
        { builder = finaliseBuilder builder processedAnimData }
        (processedAnimData.groups
            |> AnimGroups.map generateAnimGroup
            |> AnimGroups.foldl insertAnimGroup animGroups
            |> AnimGroups.map (\name animGroup -> setPlayStateWithStyle (initialPlayStateFor name) animGroup)
        )



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
    = Ended CurrentTargetId TargetId AnimGroupName
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


update : AnimMsg -> AnimState -> ( AnimState, Maybe AnimEvent )
update animMsg animState =
    case animMsg of
        GotPaused animGroupName ->
            ( animState, Just (Paused animGroupName) )

        GotResumed animGroupName ->
            ( animState, Just (Resumed animGroupName) )

        GotRestarted animGroupName ->
            ( animState, Just (Restarted animGroupName) )

        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationStarted animGroupName) animState
            , Just (Run currentTargetId targetId animGroupName)
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationEnded animGroupName) animState
            , Just (Ended currentTargetId targetId animGroupName)
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            if isGroupRunning animGroupName animState then
                ( CSS.handleEvent AnimGroup.setPlayState (CSS.AnimationCancelled animGroupName) animState
                , Just (Cancelled currentTargetId targetId animGroupName)
                )

            else
                ( animState, Nothing )

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
            , Just (Iteration currentTargetId targetId animGroupName count)
            )


isGroupRunning : AnimGroupName -> AnimState -> Bool
isGroupRunning animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map AnimGroup.isRunning
        |> Maybe.withDefault False


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
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ CSS.onEventStopPropagation "animationstart" toMsg GotStarted
    , CSS.onEventStopPropagation "animationend" toMsg GotEnded
    , CSS.onEventStopPropagation "animationcancel" toMsg GotCancelled
    , CSS.onEventStopPropagation "animationiteration" toMsg GotIteration
    ]



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


setStyles : Styles -> AnimGroup
setStyles styles =
    AnimGroup.setStyles styles AnimGroup.init


buildControlStyles : Maybe Builder.ProcessedAnimGroupConfig -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
buildControlStyles maybeConfig =
    case maybeConfig of
        Just config ->
            KeyframeStyles.fromProcessedPropertiesWithControlledAxes config.controlledAxes Nothing Nothing

        Nothing ->
            KeyframeStyles.fromProcessedProperties Nothing Nothing


stop : AnimGroupName -> AnimState -> AnimState
stop =
    CSS.stop
        AnimGroup.setPlayState
        AnimGroup.isActive
        buildControlStyles
        setStyles


reset : AnimGroupName -> AnimState -> AnimState
reset =
    CSS.reset
        AnimGroup.setPlayState
        buildControlStyles
        setStyles


restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg ((AnimState state _) as animState) =
    let
        maybeFromHistory =
            Builder.getCurrentAnimationConfig animGroupName state.builder
    in
    case maybeFromHistory of
        Nothing ->
            ( animState, Cmd.none )

        Just config ->
            ( restartAnimation animGroupName config.controlledAxes config.properties animState
            , toCmd animGroupName toMsg GotRestarted
            )


restartAnimation : AnimGroupName -> Dict.Dict String (Set.Set String) -> List Builder.ProcessedPropertyConfig -> AnimState -> AnimState
restartAnimation animGroupName controlledAxes properties (AnimState state animGroups) =
    let
        counter =
            AnimGroups.get animGroupName animGroups
                |> Maybe.map AnimGroup.getRestartCounter
                |> Maybe.withDefault 0

        discrete : DiscreteConfig
        discrete =
            { entry = Builder.getDiscreteEntryPropertiesFor animGroupName state.builder
            , exit = Builder.getDiscreteExitPropertiesFor animGroupName state.builder
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
                controlledAxes
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
