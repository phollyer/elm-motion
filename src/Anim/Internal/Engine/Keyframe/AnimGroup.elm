module Anim.Internal.Engine.Keyframe.AnimGroup exposing
    ( AnimGroup
    , addStyle
    , clearAnimation
    , getAnimation
    , getDiscreteEntry
    , getDiscreteExit
    , getIterationCount
    , getRestartCounter
    , getStyles
    , getWillChange
    , incrementIterationCount
    , init
    , isActive
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , mergeStyles
    , setAnimation
    , setDiscreteEntry
    , setDiscreteExit
    , setIterationCount
    , setPlayState
    , setRestartCounter
    , setStyles
    , setWillChange
    )

import Anim.Internal.Builder exposing (DiscreteExitProperty)
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Keyframe.Animation exposing (Animation)
import Anim.Internal.Engine.Shared.PlayState as PlayState exposing (PlayState)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


type AnimGroup
    = AnimGroup
        { styles : Styles
        , playState : PlayState
        , restartCounter : Int
        , iterationCount : Int
        , maybeAnimation : Maybe Animation
        , willChange : String
        , discreteEntry : Dict String String
        , discreteExit : Dict String DiscreteExitProperty
        }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : AnimGroup
init =
    AnimGroup
        { styles = Styles.empty
        , playState = PlayState.NotStarted
        , restartCounter = 0
        , iterationCount = 0
        , maybeAnimation = Nothing
        , willChange = ""
        , discreteEntry = Dict.empty
        , discreteExit = Dict.empty
        }



-- ============================================================
-- ANIMATION
-- ============================================================


clearAnimation : AnimGroup -> AnimGroup
clearAnimation (AnimGroup animGroup) =
    AnimGroup { animGroup | maybeAnimation = Nothing }


getAnimation : AnimGroup -> Maybe Animation
getAnimation (AnimGroup animGroup) =
    animGroup.maybeAnimation


setAnimation : Animation -> AnimGroup -> AnimGroup
setAnimation animation (AnimGroup animGroup) =
    AnimGroup { animGroup | maybeAnimation = Just animation }



-- ============================================================
-- ITERATION COUNT
-- ============================================================


getIterationCount : AnimGroup -> Int
getIterationCount (AnimGroup animGroup) =
    animGroup.iterationCount


incrementIterationCount : AnimGroup -> AnimGroup
incrementIterationCount (AnimGroup animGroup) =
    AnimGroup { animGroup | iterationCount = animGroup.iterationCount + 1 }


setIterationCount : Int -> AnimGroup -> AnimGroup
setIterationCount iterationCount (AnimGroup animGroup) =
    AnimGroup { animGroup | iterationCount = iterationCount }



-- ============================================================
-- PLAY STATE
-- ============================================================


setPlayState : PlayState -> AnimGroup -> AnimGroup
setPlayState state (AnimGroup animGroup) =
    AnimGroup { animGroup | playState = state }



-- ============================================================
-- RESTART COUNTER
-- ============================================================


getRestartCounter : AnimGroup -> Int
getRestartCounter (AnimGroup animGroup) =
    animGroup.restartCounter


setRestartCounter : Int -> AnimGroup -> AnimGroup
setRestartCounter restartCounter (AnimGroup animGroup) =
    AnimGroup { animGroup | restartCounter = restartCounter }



-- ============================================================
-- STATE QUERIES
-- ============================================================


isActive : AnimGroup -> Bool
isActive (AnimGroup animGroup) =
    PlayState.isActive animGroup.playState


isCancelled : AnimGroup -> Bool
isCancelled (AnimGroup animGroup) =
    PlayState.isCancelled animGroup.playState


isComplete : AnimGroup -> Bool
isComplete (AnimGroup animGroup) =
    PlayState.isComplete animGroup.playState


isPaused : AnimGroup -> Bool
isPaused (AnimGroup animGroup) =
    PlayState.isPaused animGroup.playState


isRunning : AnimGroup -> Bool
isRunning (AnimGroup animGroup) =
    PlayState.isRunning animGroup.playState



-- ============================================================
-- STYLES
-- ============================================================


addStyle : String -> String -> AnimGroup -> AnimGroup
addStyle key value (AnimGroup animGroup) =
    AnimGroup
        { animGroup
            | styles =
                Styles.insert key value animGroup.styles
        }


getStyles : AnimGroup -> Styles
getStyles (AnimGroup animGroup) =
    animGroup.styles


{-| Get the deduped, comma-joined `will-change` value derived from the
properties this group animates. Empty when the group has no properties
(or is being constructed). The Keyframe engine writes this into the
inline style of the animated element so the browser can pre-promote
the layer before the animation kicks off.
-}
getWillChange : AnimGroup -> String
getWillChange (AnimGroup animGroup) =
    animGroup.willChange


{-| Set the precomputed `will-change` value for this group. See
[`getWillChange`](#getWillChange).
-}
setWillChange : String -> AnimGroup -> AnimGroup
setWillChange value (AnimGroup animGroup) =
    AnimGroup { animGroup | willChange = value }


mergeStyles : AnimGroup -> AnimGroup -> AnimGroup
mergeStyles (AnimGroup new) (AnimGroup existing) =
    AnimGroup { new | styles = Styles.merge new.styles existing.styles }


setStyles : Styles -> AnimGroup -> AnimGroup
setStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | styles = styles }



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


getDiscreteEntry : AnimGroup -> Dict String String
getDiscreteEntry (AnimGroup animGroup) =
    animGroup.discreteEntry


getDiscreteExit : AnimGroup -> Dict String DiscreteExitProperty
getDiscreteExit (AnimGroup animGroup) =
    animGroup.discreteExit


setDiscreteEntry : Dict String String -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup animGroup) =
    AnimGroup { animGroup | discreteEntry = entry }


setDiscreteExit : Dict String DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup animGroup) =
    AnimGroup { animGroup | discreteExit = exit }
