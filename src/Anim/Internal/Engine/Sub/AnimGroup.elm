module Anim.Internal.Engine.Sub.AnimGroup exposing
    ( AnimGroup
    , addAnimation
    , getAnimationDirection
    , getAnimations
    , getCurrentIteration
    , getDiscreteEntry
    , getDiscreteExit
    , getIterations
    , getTransformOrder
    , getWillChange
    , init
    , isComplete
    , isPaused
    , isRunning
    , setAnimationDirection
    , setAnimations
    , setCurrentIteration
    , setDiscreteEntry
    , setDiscreteExit
    , setIterationCount
    , setPlayState
    , setTransformOrder
    , setWillChange
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder exposing (AnimationDirection(..), DiscreteExitProperty, Iterations(..))
import Anim.Internal.Engine.Shared.PlayState as PlayState exposing (PlayState)
import Anim.Internal.Engine.Sub.Animations as Animations exposing (Animations)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


type AnimGroup
    = AnimGroup
        { animations : Animations
        , playState : PlayState
        , transformOrder : List TransformProperty
        , iterations : Iterations
        , animationDirection : AnimationDirection
        , currentIteration : Int
        , discreteEntry : Dict String String
        , discreteExit : Dict String DiscreteExitProperty
        , willChange : String
        }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : AnimGroup
init =
    AnimGroup
        { animations = Animations.init
        , playState = PlayState.NotStarted
        , transformOrder = TransformProperty.default
        , iterations = Once
        , animationDirection = Normal
        , currentIteration = 0
        , discreteEntry = Dict.empty
        , discreteExit = Dict.empty
        , willChange = ""
        }



-- ============================================================
-- QUERY
-- ============================================================


getAnimationDirection : AnimGroup -> AnimationDirection
getAnimationDirection (AnimGroup group) =
    group.animationDirection


getAnimations : AnimGroup -> Animations
getAnimations (AnimGroup group) =
    group.animations


getCurrentIteration : AnimGroup -> Int
getCurrentIteration (AnimGroup group) =
    group.currentIteration


getDiscreteEntry : AnimGroup -> Dict String String
getDiscreteEntry (AnimGroup group) =
    group.discreteEntry


getDiscreteExit : AnimGroup -> Dict String DiscreteExitProperty
getDiscreteExit (AnimGroup group) =
    group.discreteExit


getIterations : AnimGroup -> Iterations
getIterations (AnimGroup group) =
    group.iterations


getTransformOrder : AnimGroup -> List TransformProperty
getTransformOrder (AnimGroup group) =
    group.transformOrder


{-| Get the deduped, comma-joined `will-change` value derived from the
properties this group animates. Empty when the group has no properties
(or is being constructed). The Sub engine writes this into the inline
style of the animated element so the browser can pre-promote the layer
before the per-frame style updates begin.
-}
getWillChange : AnimGroup -> String
getWillChange (AnimGroup group) =
    group.willChange


isComplete : AnimGroup -> Bool
isComplete (AnimGroup group) =
    PlayState.isComplete group.playState


isPaused : AnimGroup -> Bool
isPaused (AnimGroup group) =
    PlayState.isPaused group.playState


isRunning : AnimGroup -> Bool
isRunning (AnimGroup group) =
    PlayState.isRunning group.playState



-- ============================================================
-- BUILD
-- ============================================================


addAnimation : Animations -> AnimGroup -> AnimGroup
addAnimation additional (AnimGroup group) =
    AnimGroup { group | animations = Animations.add additional group.animations }


setAnimationDirection : AnimationDirection -> AnimGroup -> AnimGroup
setAnimationDirection direction (AnimGroup group) =
    AnimGroup { group | animationDirection = direction }


setCurrentIteration : Int -> AnimGroup -> AnimGroup
setCurrentIteration currentIteration (AnimGroup group) =
    AnimGroup { group | currentIteration = currentIteration }


setPlayState : PlayState -> AnimGroup -> AnimGroup
setPlayState state (AnimGroup group) =
    AnimGroup { group | playState = state }


setIterationCount : Iterations -> AnimGroup -> AnimGroup
setIterationCount iterationCount (AnimGroup group) =
    AnimGroup { group | iterations = iterationCount }


setAnimations : Animations -> AnimGroup -> AnimGroup
setAnimations animations (AnimGroup group) =
    AnimGroup { group | animations = animations }


setTransformOrder : List TransformProperty -> AnimGroup -> AnimGroup
setTransformOrder transformOrder (AnimGroup group) =
    AnimGroup { group | transformOrder = transformOrder }


{-| Set the precomputed `will-change` value for this group. See
[`getWillChange`](#getWillChange).
-}
setWillChange : String -> AnimGroup -> AnimGroup
setWillChange value (AnimGroup group) =
    AnimGroup { group | willChange = value }


setDiscreteEntry : Dict String String -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup group) =
    AnimGroup { group | discreteEntry = entry }


setDiscreteExit : Dict String DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup group) =
    AnimGroup { group | discreteExit = exit }
