module Anim.Internal.Engine.Transition exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
    , EngineBuilder
    , TimelineBuilder
    , animate
    , attributes
    , events
    , eventsStopPropagation
    , init
    , reset
    , retarget
    , startingStyleNode
    , startingStyleNodeFor
    , stop
    , update
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS exposing (AnimState(..))
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Transition.Generator as Generator exposing (AnimGroupName)
import Anim.Internal.Engine.Transition.Styles as TransitionStyles
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Dict
import Html exposing (Html)
import Html.Attributes



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimState =
    CSS.AnimState Builder.ForTransition AnimGroup


type alias AnimGroupName =
    String


type alias AnimBuilder eng =
    CSS.AnimBuilder eng


type alias TimelineBuilder engine =
    CSS.TimelineBuilder engine


type alias EngineBuilder =
    Builder.AnimBuilder Builder.ForTransition



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    let
        initGroup : EngineBuilder -> AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
        initGroup builder _ { properties } =
            Generator.init
                (Builder.discreteTransitionsEnabled builder)
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                properties
    in
    CSS.init initGroup



-- ============================================================
-- TRIGGER
-- ============================================================


animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    let
        generateAnimGroup : Maybe (List TransformProperty) -> EngineBuilder -> AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
        generateAnimGroup _ builder _ { properties } =
            let
                freshEntry =
                    Builder.getDiscreteEntryProperties builder

                -- `@starting-style` is only useful for ENTRY transitions
                -- (element becoming rendered). Only emit starting styles
                -- on the animate call that freshly set `discreteEntry`;
                -- on exit (Hide) or plain animates we skip them so we
                -- don't pollute the stylesheet with dead rules.
                startingStylesForThisAnimate =
                    if Dict.isEmpty freshEntry then
                        []

                    else
                        extractStartingStyles properties
            in
            Generator.generateAnimation
                (Builder.discreteTransitionsEnabled builder)
                freshEntry
                (Builder.getDiscreteExitProperties builder)
                properties
                |> AnimGroup.setStartingStyles startingStylesForThisAnimate

        insertAnimGroup : AnimGroups Builder.ProcessedAnimGroupConfig -> AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupsConfig animGroupName newAnimGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName newAnimGroup acc

                Just currentGroup ->
                    let
                        animatedCssProps =
                            AnimGroups.get animGroupName animGroupsConfig
                                |> Maybe.map (.properties >> toCssPropertyNames)
                                |> Maybe.withDefault []

                        -- Include discrete property names so old `display Xms`
                        -- entries are evicted from the merged transition list
                        -- when this animate retouches the discrete property.
                        discreteCssProps =
                            Dict.keys (AnimGroup.getDiscreteEntry newAnimGroup)
                                ++ Dict.keys (AnimGroup.getDiscreteExit newAnimGroup)

                        styles =
                            AnimGroup.mergeStyles newAnimGroup currentGroup (animatedCssProps ++ discreteCssProps)
                    in
                    AnimGroups.insert animGroupName styles acc
    in
    CSS.animate AnimGroup.setPlayState generateAnimGroup insertAnimGroup


{-| Re-anchor an animation to a new target by snapping to the new end values.
-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget ((AnimState origState _) as animState) build =
    let
        touchedGroups =
            (Builder.process (build origState.builder)).groups

        (AnimState newState newGroups) =
            animate animState build

        snapGroup group =
            group
                |> AnimGroup.setStyles
                    (AnimGroup.getStyles group
                        |> Styles.insert "transition" "none"
                        |> Styles.remove "transition-behavior"
                    )
                |> AnimGroup.setPlayState PlayState.Complete

        snappedGroups =
            AnimGroups.foldl
                (\name _ acc ->
                    case AnimGroups.get name acc of
                        Just group ->
                            AnimGroups.insert name (snapGroup group) acc

                        Nothing ->
                            acc
                )
                newGroups
                touchedGroups
    in
    AnimState newState snappedGroups


toCssPropertyNames : List Builder.ProcessedPropertyConfig -> List String
toCssPropertyNames props =
    List.concatMap
        (\prop ->
            case prop of
                Builder.ProcessedCustomPropertyConfig cssName _ _ ->
                    [ cssName ]

                Builder.ProcessedCustomColorPropertyConfig cssName _ ->
                    [ cssName ]

                Builder.ProcessedOpacityConfig _ ->
                    [ "opacity" ]

                Builder.ProcessedPerspectiveOriginConfig _ ->
                    [ "perspective-origin" ]

                Builder.ProcessedRotateConfig _ ->
                    [ "transform" ]

                Builder.ProcessedScaleConfig _ ->
                    [ "scale" ]

                Builder.ProcessedSizeConfig _ ->
                    [ "width", "height" ]

                Builder.ProcessedSkewConfig _ ->
                    [ "transform" ]

                Builder.ProcessedTranslateConfig _ ->
                    [ "translate" ]
        )
        props


type StartingStylePart
    = TransformPart String
    | CssDeclaration String


propertyToStartingStylePart : Builder.ProcessedPropertyConfig -> Maybe StartingStylePart
propertyToStartingStylePart prop =
    case prop of
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration (cssName ++ ": " ++ String.fromFloat start ++ unit ++ ";"))

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration (cssName ++ ": " ++ Color.toCssString start ++ ";"))

        Builder.ProcessedOpacityConfig config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration ("opacity: " ++ Opacity.toString start ++ ";"))

        Builder.ProcessedPerspectiveOriginConfig config ->
            config.start
                |> Maybe.map (\start -> CssDeclaration ("perspective-origin: " ++ PerspectiveOrigin.toCssString config.cssUnit start ++ ";"))

        Builder.ProcessedRotateConfig config ->
            config.start
                |> Maybe.map (Rotate.toCssString >> TransformPart)

        Builder.ProcessedScaleConfig config ->
            config.start
                |> Maybe.map (Scale.toCssString >> TransformPart)

        Builder.ProcessedSizeConfig config ->
            config.start
                |> Maybe.map
                    (\start ->
                        CssDeclaration (Size.toCssString config.cssUnit start ++ ";")
                    )

        Builder.ProcessedSkewConfig config ->
            config.start
                |> Maybe.map (Skew.toCssString >> TransformPart)

        Builder.ProcessedTranslateConfig config ->
            config.start
                |> Maybe.map (Translate.toCssString config.cssUnit >> TransformPart)


extractStartingStyles : List Builder.ProcessedPropertyConfig -> List String
extractStartingStyles properties =
    let
        parts =
            List.filterMap propertyToStartingStylePart properties

        ( transformParts, cssDeclarations ) =
            List.foldl
                (\part ( transforms, declarations ) ->
                    case part of
                        TransformPart t ->
                            ( t :: transforms, declarations )

                        CssDeclaration d ->
                            ( transforms, d :: declarations )
                )
                ( [], [] )
                parts

        transformStyle =
            if List.isEmpty transformParts then
                []

            else
                [ "transform: " ++ String.join " " (List.reverse transformParts) ++ ";" ]
    in
    transformStyle ++ List.reverse cssDeclarations



-- ============================================================
-- EVENTS
-- ============================================================


type alias CurrentTargetId =
    Maybe String


type alias TargetId =
    Maybe String


type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = GotStarted AnimGroupName CSS.SourceEventData
    | GotEnded AnimGroupName CSS.SourceEventData
    | GotCancelled AnimGroupName CSS.SourceEventData
    | GotRun AnimGroupName CSS.SourceEventData


update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update animMsg animState =
    case animMsg of
        GotStarted animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionStarted animGroupName) animState
            , Started currentTargetId targetId animGroupName
            )

        GotEnded animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionEnded animGroupName) animState
            , Ended currentTargetId targetId animGroupName
            )

        GotRun animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionRun animGroupName) animState
            , Run currentTargetId targetId animGroupName
            )

        GotCancelled animGroupName { currentTargetId, targetId } ->
            ( CSS.handleEvent AnimGroup.setPlayState (CSS.TransitionCancelled animGroupName) animState
            , Cancelled currentTargetId targetId animGroupName
            )



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName ((AnimState _ data) as animState) =
    case AnimGroups.get animGroupName data of
        Nothing ->
            []

        Just animGroup ->
            let
                isComplete =
                    AnimGroup.isComplete animGroup

                willChangeAttrs =
                    -- `will-change` promotes the animated properties to
                    -- their own compositor layer ahead of the transition
                    -- starting. We clear it once the transition finishes so
                    -- the element doesn't keep paying the layer cost
                    -- forever (the classic `will-change` anti-pattern).
                    if isComplete then
                        []

                    else
                        case AnimGroup.getWillChange animGroup of
                            "" ->
                                []

                            value ->
                                [ Html.Attributes.style "will-change" value ]
            in
            if AnimGroup.usesDiscrete animGroup then
                -- Selector-driven mode: all animated styles live in the
                -- stylesheet rule emitted by `startingStyleNode`, scoped
                -- by `[data-anim-group-name="X"][data-anim-state="sN"]`.
                -- The element only needs the data attributes (so the
                -- selector matches change on each animate, triggering
                -- `@starting-style` for entry transitions) plus the
                -- in-flight `will-change` hint.
                Html.Attributes.attribute "data-anim-group-name" animGroupName
                    :: Html.Attributes.attribute "data-anim-state" (stateAttrValue animGroup)
                    :: willChangeAttrs

            else
                let
                    discreteExitAttrs =
                        AnimGroup.getDiscreteExit animGroup
                            |> Dict.toList
                            |> List.map
                                (\( prop, { from, to } ) ->
                                    if isComplete then
                                        Html.Attributes.style prop to

                                    else
                                        Html.Attributes.style prop from
                                )
                in
                CSS.attributes
                    []
                    AnimGroup.getStyles
                    animGroupName
                    animState
                    ++ discreteExitAttrs
                    ++ willChangeAttrs


stateAttrValue : AnimGroup -> String
stateAttrValue animGroup =
    "s" ++ String.fromInt (AnimGroup.getStateId animGroup)


startingStyleNode : AnimState -> Html.Html msg
startingStyleNode ((AnimState _ animGroups) as animState) =
    let
        css =
            animGroups
                |> AnimGroups.names
                |> List.filterMap (\id -> generateGroupCss id animState)
                |> String.join "\n"
    in
    if String.isEmpty css then
        Html.text ""

    else
        Html.node "style" [] [ Html.text css ]


startingStyleNodeFor : AnimGroupName -> AnimState -> Html msg
startingStyleNodeFor animGroupName animState =
    case generateGroupCss animGroupName animState of
        Just css ->
            Html.node "style" [] [ Html.text css ]

        Nothing ->
            Html.text ""


{-| For a discrete-mode group, render the full per-animate stylesheet:

  - A destination rule scoped by `[data-anim-group-name][data-anim-state]`
    containing all the styles that drive the transition (including
    `transition`, `transition-behavior`, the animated property values,
    and the resolved entry / exit destinations).
  - An `@starting-style` block scoped by the same selector when this
    animate freshly set `discreteEntry` (i.e. it's an entry transition).

For non-discrete groups this returns `Nothing` - their styles continue
to flow through the inline `style` attribute via `attributes`, the same
as before.

-}
generateGroupCss : AnimGroupName -> AnimState -> Maybe String
generateGroupCss animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen
            (\animGroup ->
                if AnimGroup.usesDiscrete animGroup then
                    let
                        selector =
                            "[data-anim-group-name=\""
                                ++ animGroupName
                                ++ "\"][data-anim-state=\"s"
                                ++ String.fromInt (AnimGroup.getStateId animGroup)
                                ++ "\"]"

                        destinationDecls =
                            AnimGroup.getStylesheetRule animGroup
                                |> Styles.toList
                                |> List.map (\( k, v ) -> "    " ++ k ++ ": " ++ v ++ ";")

                        destinationRule =
                            if List.isEmpty destinationDecls then
                                ""

                            else
                                selector ++ " {\n" ++ String.join "\n" destinationDecls ++ "\n}"

                        startingStyles =
                            AnimGroup.getStartingStyles animGroup

                        startingStyleBlock =
                            if List.isEmpty startingStyles then
                                ""

                            else
                                "@starting-style {\n  "
                                    ++ selector
                                    ++ " {\n"
                                    ++ String.join "\n" (List.map (\s -> "    " ++ s) startingStyles)
                                    ++ "\n  }\n}"
                    in
                    case ( destinationRule, startingStyleBlock ) of
                        ( "", "" ) ->
                            Nothing

                        ( d, "" ) ->
                            Just d

                        ( "", s ) ->
                            Just s

                        ( d, s ) ->
                            Just (d ++ "\n" ++ s)

                else
                    Nothing
            )



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ CSS.onEvent "transitionstart" toMsg GotStarted
    , CSS.onEvent "transitionend" toMsg GotEnded
    , CSS.onEvent "transitionrun" toMsg GotRun
    , CSS.onEvent "transitioncancel" toMsg GotCancelled
    ]


eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ CSS.onEventStopPropagation "transitionstart" toMsg GotStarted
    , CSS.onEventStopPropagation "transitionend" toMsg GotEnded
    , CSS.onEventStopPropagation "transitionrun" toMsg GotRun
    , CSS.onEventStopPropagation "transitioncancel" toMsg GotCancelled
    ]



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState -> AnimState
stop =
    CSS.stop
        AnimGroup.setPlayState
        AnimGroup.isActive
        TransitionStyles.fromProcessedProperties
        setStyles


reset : AnimGroupName -> AnimState -> AnimState
reset =
    CSS.reset
        AnimGroup.setPlayState
        TransitionStyles.fromProcessedProperties
        setStyles


setStyles : Styles -> AnimGroup
setStyles styles =
    AnimGroup.setStyles styles AnimGroup.init
