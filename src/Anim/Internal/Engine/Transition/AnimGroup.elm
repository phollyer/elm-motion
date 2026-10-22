module Anim.Internal.Engine.Transition.AnimGroup exposing
    ( AnimGroup
    , getDiscreteEntry
    , getDiscreteExit
    , getPropertyKeys
    , getStartingStyles
    , getStateId
    , getStyles
    , getStylesheetRule
    , getWillChange
    , init
    , isActive
    , isCancelled
    , isComplete
    , isRunning
    , mergeStyles
    , setDiscreteEntry
    , setDiscreteExit
    , setPlayState
    , setPropertyKeys
    , setStartingStyles
    , setStyles
    , setWillChange
    )

import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Shared.PlayState as PlayState exposing (PlayState)
import Anim.Internal.Property.Shared.Discrete as Discrete
import Dict
import Set exposing (Set)



-- ============================================================
-- TYPES
-- ============================================================


type AnimGroup
    = AnimGroup
        { styles : Styles
        , playState : PlayState
        , discreteConfig : Discrete.Config
        , startingStyles : List String
        , propertyKeys : Set String
        , willChange : String
        , stateId : Int
        }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : AnimGroup
init =
    AnimGroup
        { styles = Styles.empty
        , playState = PlayState.NotStarted
        , discreteConfig = Discrete.empty
        , startingStyles = []
        , propertyKeys = Set.empty
        , willChange = ""
        , stateId = 0
        }



-- ============================================================
-- BUILD
-- ============================================================


setDiscreteEntry : Discrete.Entry -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup animGroup) =
    AnimGroup { animGroup | discreteConfig = Discrete.setEntry entry animGroup.discreteConfig }


setDiscreteExit : Discrete.Exit -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup animGroup) =
    AnimGroup { animGroup | discreteConfig = Discrete.setExit exit animGroup.discreteConfig }


setPlayState : PlayState -> AnimGroup -> AnimGroup
setPlayState state (AnimGroup animGroup) =
    AnimGroup { animGroup | playState = state }


setPropertyKeys : Set String -> AnimGroup -> AnimGroup
setPropertyKeys keys (AnimGroup animGroup) =
    AnimGroup { animGroup | propertyKeys = keys }


setStartingStyles : List String -> AnimGroup -> AnimGroup
setStartingStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | startingStyles = styles }


setStyles : Styles -> AnimGroup -> AnimGroup
setStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | styles = styles }


{-| Set the precomputed `will-change` value for this group. See
[`getWillChange`](#getWillChange).
-}
setWillChange : String -> AnimGroup -> AnimGroup
setWillChange value (AnimGroup animGroup) =
    AnimGroup { animGroup | willChange = value }



-- ============================================================
-- QUERY
-- ============================================================


getStartingStyles : AnimGroup -> List String
getStartingStyles (AnimGroup animGroup) =
    animGroup.startingStyles


getStyles : AnimGroup -> Styles
getStyles (AnimGroup animGroup) =
    Dict.foldl Styles.insert animGroup.styles animGroup.discreteConfig.entry


{-| Compute the destination CSS for a selector-driven stylesheet rule:
base styles, with the entry value layered on top for any `discreteEntry`
property, and the exit's `to` value layered on top of that for any
property currently in `discreteExit`. The exit destination wins on the
animate call where it was freshly set; subsequent animates clear
`discreteExit` (see `mergeStyles`).
-}
getStylesheetRule : AnimGroup -> Styles
getStylesheetRule (AnimGroup animGroup) =
    animGroup.styles
        |> (\s -> Dict.foldl Styles.insert s animGroup.discreteConfig.entry)
        |> (\s ->
                Dict.foldl
                    (\key { to } acc -> Styles.insert key to acc)
                    s
                    animGroup.discreteConfig.exit
           )


getDiscreteEntry : AnimGroup -> Discrete.Entry
getDiscreteEntry (AnimGroup animGroup) =
    animGroup.discreteConfig.entry


getDiscreteExit : AnimGroup -> Discrete.Exit
getDiscreteExit (AnimGroup animGroup) =
    animGroup.discreteConfig.exit


{-| Get the set of Builder property keys (e.g. "translate", "opacity",
"custom:left") currently animated by this group. Used by `retarget` to
report which properties are mid-flight.
-}
getPropertyKeys : AnimGroup -> Set String
getPropertyKeys (AnimGroup animGroup) =
    animGroup.propertyKeys


{-| Get the deduped, comma-joined `will-change` value derived from the
properties this group animates. Empty when the group has no properties
(or is being constructed). The Transition engine writes this into the
inline style of the animated element while the animation is in flight
(see [`Anim.Internal.Engine.Transition.attributes`](Anim-Internal-Engine-Transition#attributes)).
-}
getWillChange : AnimGroup -> String
getWillChange (AnimGroup animGroup) =
    animGroup.willChange


{-| Monotonic counter that bumps on every `mergeStyles` call (i.e. on every
`animate` after init). Used to generate a unique `data-anim-state` selector
value per render so the browser sees a selector-match change and fires
`@starting-style` rules for groups that use `discreteEntry`. See
[`Anim.Internal.Engine.Transition.attributes`](Anim-Internal-Engine-Transition#attributes).
-}
getStateId : AnimGroup -> Int
getStateId (AnimGroup animGroup) =
    animGroup.stateId


isActive : AnimGroup -> Bool
isActive (AnimGroup animGroup) =
    PlayState.isActive animGroup.playState


isCancelled : AnimGroup -> Bool
isCancelled (AnimGroup animGroup) =
    PlayState.isCancelled animGroup.playState


isComplete : AnimGroup -> Bool
isComplete (AnimGroup animGroup) =
    PlayState.isComplete animGroup.playState


isRunning : AnimGroup -> Bool
isRunning (AnimGroup animGroup) =
    PlayState.isRunning animGroup.playState



-- ============================================================
-- TRANSFORM
-- ============================================================


mergeStyles :
    AnimGroup
    -> AnimGroup
    -> List String
    -> AnimGroup
mergeStyles (AnimGroup newGroup) (AnimGroup existingGroup) newCssProps =
    let
        isMetaStyle key =
            key == "transition" || key == "transition-behavior"

        partialTranslateRenderedAsTransform =
            Set.member "translate" newGroup.propertyKeys
                && (not <| Styles.member "translate" newGroup.styles)
                && Styles.member "transform" newGroup.styles

        existingStyles =
            (if partialTranslateRenderedAsTransform then
                existingGroup.styles
                    |> Styles.remove "translate"

             else
                existingGroup.styles
            )
                |> Styles.remove "transition"
                |> Styles.remove "transition-behavior"

        newPropertyStyles =
            Styles.filter (\key _ -> not (isMetaStyle key)) newGroup.styles

        splitTransitionParts value =
            if value == "none" || String.isEmpty value then
                []

            else
                splitRespectingParens value

        transitionPartCssProp part =
            String.split " " (String.trim part)
                |> List.head
                |> Maybe.withDefault ""

        oldTransitionValue =
            Styles.get "transition" existingGroup.styles
                |> Maybe.withDefault "none"

        newTransitionValue =
            Styles.get "transition" newGroup.styles
                |> Maybe.withDefault "none"

        preservedOldTransitions =
            splitTransitionParts oldTransitionValue
                |> List.filter
                    (\part -> not (List.member (transitionPartCssProp part) newCssProps))

        mergedTransition =
            case preservedOldTransitions ++ splitTransitionParts newTransitionValue of
                [] ->
                    "none"

                parts ->
                    String.join ", " parts

        hasTransitionBehavior =
            Styles.member "transition-behavior" existingGroup.styles
                || Styles.member "transition-behavior" newGroup.styles

        styles =
            Styles.merge newPropertyStyles existingStyles
                |> Styles.insert "transition" mergedTransition
                |> (\s ->
                        if hasTransitionBehavior then
                            Styles.insert "transition-behavior" "allow-discrete" s

                        else
                            s
                   )
    in
    AnimGroup
        { styles = styles
        , playState = newGroup.playState
        , startingStyles = newGroup.startingStyles
        , propertyKeys = Set.union newGroup.propertyKeys existingGroup.propertyKeys
        , discreteConfig =
            { entry = Dict.union newGroup.discreteConfig.entry existingGroup.discreteConfig.entry
            , exit = newGroup.discreteConfig.exit
            }
        , willChange = mergeWillChange existingGroup.willChange newGroup.willChange
        , stateId = existingGroup.stateId + 1
        }


{-| Merge two comma-joined `will-change` values, preserving the order of
the existing entries and appending any new entries that aren't already
listed. Empty inputs are skipped so a fresh group merging into one with
no will-change works in either direction.
-}
mergeWillChange : String -> String -> String
mergeWillChange existing new =
    case ( existing, new ) of
        ( "", _ ) ->
            new

        ( _, "" ) ->
            existing

        _ ->
            let
                split value =
                    value
                        |> String.split ","
                        |> List.map String.trim
                        |> List.filter (not << String.isEmpty)

                existingParts =
                    split existing

                newOnlyParts =
                    split new
                        |> List.filter (\p -> not (List.member p existingParts))
            in
            String.join ", " (existingParts ++ newOnlyParts)


{-| Split a CSS transition value string by commas, but only at the top level
(not inside parentheses like `cubic-bezier(0.175, 0.885, 0.32, 1.275)`).
-}
splitRespectingParens : String -> List String
splitRespectingParens value =
    let
        chars =
            String.toList value

        helper remaining depth current acc =
            case remaining of
                [] ->
                    let
                        part =
                            String.fromList (List.reverse current)
                    in
                    if String.isEmpty (String.trim part) then
                        List.reverse acc

                    else
                        List.reverse (part :: acc)

                '(' :: rest ->
                    helper rest (depth + 1) ('(' :: current) acc

                ')' :: rest ->
                    helper rest (max 0 (depth - 1)) (')' :: current) acc

                ',' :: rest ->
                    if depth == 0 then
                        let
                            part =
                                String.fromList (List.reverse current)

                            trimmedRest =
                                case rest of
                                    ' ' :: afterSpace ->
                                        afterSpace

                                    _ ->
                                        rest
                        in
                        helper trimmedRest 0 [] (part :: acc)

                    else
                        helper rest depth (',' :: current) acc

                c :: rest ->
                    helper rest depth (c :: current) acc
    in
    helper chars 0 [] []
