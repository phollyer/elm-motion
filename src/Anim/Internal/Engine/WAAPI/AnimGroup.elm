module Anim.Internal.Engine.WAAPI.AnimGroup exposing
    ( AnimGroup
    , AnimationStatus(..)
    , AxisProportion
    , PropertyState
    , ResizeAxisState
    , Vec3
    , addPropertyStates
    , bumpPropertyVersions
    , emptyProportion
    , foldResizeStates
    , getAnimationDirection
    , getCurrentIteration
    , getDiscreteEntry
    , getDiscreteExit
    , getIterations
    , getProgress
    , getPropertySnapshot
    , getPropertyStates
    , getResizeState
    , getTransformOrder
    , init
    , isComplete
    , isPaused
    , isRunning
    , setAnimationDirection
    , setCurrentIteration
    , setDiscreteEntry
    , setDiscreteExit
    , setIterationCount
    , setProgress
    , setPropertyStates
    , setResizeProportion
    , setResizeState
    , setSnapshot
    , setStatus
    , setTransformOrder
    , updateRuntimeBaseline
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


type AnimGroup
    = AnimGroup
        { propertySnapshot : PropertyBaselines
        , propertyStates : AnimGroups PropertyState
        , transformOrder : List TransformProperty
        , progress : Float
        , iterations : Builder.Iterations
        , currentIteration : Int
        , resizeStates : Dict String ResizeAxisState
        , animationDirection : Builder.AnimationDirection
        , discreteEntry : Dict String Builder.DiscreteEntryProperty
        , discreteExit : Dict String Builder.DiscreteExitProperty
        }


type alias PropertyState =
    { version : Int
    , status : AnimationStatus
    , config : Builder.ProcessedPropertyConfig
    }


type alias Vec3 =
    { x : Float, y : Float, z : Float }


type alias AxisProportion =
    { x : Maybe Float, y : Maybe Float, z : Maybe Float }


{-| Resize-aware leg state shared by every resize-affected property
(translate, scale, perspective-origin, and any future addition such as
size or custom numeric CSS properties). `proportion` is the single
source of truth for "where on the leg are we" across resize round-trips;
`start`/`end`/`durationMs` are the resize-rebased leg endpoints and
timing used to feed WAAPI on the next resize.

For 2D properties (perspective-origin) and 1D properties (custom
scalars) the unused axes are filled with 0.

-}
type alias ResizeAxisState =
    { start : Vec3
    , end : Vec3
    , durationMs : Float
    , proportion : AxisProportion
    }


emptyProportion : AxisProportion
emptyProportion =
    { x = Nothing, y = Nothing, z = Nothing }


type AnimationStatus
    = NotStarted
    | Running
    | Paused
    | Complete



-- ============================================================
-- INITIALIZE
-- ============================================================


init : AnimGroup
init =
    AnimGroup
        { propertySnapshot = PropertyBaselines.empty
        , propertyStates = AnimGroups.init
        , transformOrder = TransformProperty.default
        , progress = 0
        , iterations = Builder.Once
        , currentIteration = 0
        , resizeStates = Dict.empty
        , animationDirection = Builder.Normal
        , discreteEntry = Dict.empty
        , discreteExit = Dict.empty
        }



-- ============================================================
-- BUILD
-- ============================================================


addPropertyStates : AnimGroup -> AnimGroup -> AnimGroup
addPropertyStates (AnimGroup newGroup) (AnimGroup existingGroup) =
    AnimGroup
        { newGroup
            | propertyStates = AnimGroups.union newGroup.propertyStates existingGroup.propertyStates
        }


{-| Bump version and reset status for each property whose name appears in
`updates`, also refreshing its stored `config` (so a restart or reset
with different easing/duration takes effect). Properties not listed in
`updates` are left untouched.
-}
bumpPropertyVersions : List ( String, Builder.ProcessedPropertyConfig ) -> AnimGroup -> AnimGroup
bumpPropertyVersions updates (AnimGroup group) =
    let
        updateLookup : Dict String Builder.ProcessedPropertyConfig
        updateLookup =
            Dict.fromList updates
    in
    AnimGroup
        { group
            | propertyStates =
                AnimGroups.map
                    (\propType propAnim ->
                        case Dict.get propType updateLookup of
                            Just newConfig ->
                                { propAnim
                                    | version = propAnim.version + 1
                                    , status = NotStarted
                                    , config = newConfig
                                }

                            Nothing ->
                                propAnim
                    )
                    group.propertyStates
        }


setAnimationDirection : Builder.AnimationDirection -> AnimGroup -> AnimGroup
setAnimationDirection direction (AnimGroup group) =
    AnimGroup { group | animationDirection = direction }


setCurrentIteration : Int -> AnimGroup -> AnimGroup
setCurrentIteration currentIteration (AnimGroup group) =
    AnimGroup { group | currentIteration = currentIteration }


{-| Store the post-resize leg state for the given property name. Any
existing entry for that property is overwritten.
-}
setResizeState : String -> ResizeAxisState -> AnimGroup -> AnimGroup
setResizeState propName newState (AnimGroup group) =
    AnimGroup
        { group | resizeStates = Dict.insert propName newState group.resizeStates }


{-| Update _only_ the per-axis proportion snapshot of the cached leg
state for the given property name, leaving `start`/`end`/`durationMs`
untouched. A no-op if no state has been cached yet for that property
(animation hasn't reported a first frame or no resize has fired).
-}
setResizeProportion : String -> AxisProportion -> AnimGroup -> AnimGroup
setResizeProportion propName proportion (AnimGroup group) =
    AnimGroup
        { group
            | resizeStates =
                Dict.update propName
                    (Maybe.map (\state -> { state | proportion = proportion }))
                    group.resizeStates
        }


setDiscreteEntry : Dict String Builder.DiscreteEntryProperty -> AnimGroup -> AnimGroup
setDiscreteEntry entry (AnimGroup group) =
    AnimGroup { group | discreteEntry = entry }


setDiscreteExit : Dict String Builder.DiscreteExitProperty -> AnimGroup -> AnimGroup
setDiscreteExit exit (AnimGroup group) =
    AnimGroup { group | discreteExit = exit }


setIterationCount : Builder.Iterations -> AnimGroup -> AnimGroup
setIterationCount iterations (AnimGroup group) =
    AnimGroup { group | iterations = iterations }


setProgress : Float -> AnimGroup -> AnimGroup
setProgress progress (AnimGroup group) =
    AnimGroup { group | progress = progress }


setPropertyStates : AnimGroups PropertyState -> AnimGroup -> AnimGroup
setPropertyStates propertyStates (AnimGroup group) =
    AnimGroup { group | propertyStates = propertyStates }


setSnapshot : PropertyBaselines -> AnimGroup -> AnimGroup
setSnapshot snapshot (AnimGroup group) =
    AnimGroup { group | propertySnapshot = snapshot }


updateRuntimeBaseline : (PropertyBaselines -> PropertyBaselines) -> AnimGroup -> AnimGroup
updateRuntimeBaseline updater (AnimGroup group) =
    AnimGroup { group | propertySnapshot = updater group.propertySnapshot }


setStatus : AnimationStatus -> AnimGroup -> AnimGroup
setStatus newStatus (AnimGroup group) =
    AnimGroup
        { group
            | propertyStates =
                AnimGroups.map
                    (\_ propAnim -> { propAnim | status = newStatus })
                    group.propertyStates
        }


setTransformOrder : List TransformProperty -> AnimGroup -> AnimGroup
setTransformOrder order (AnimGroup group) =
    AnimGroup { group | transformOrder = order }



-- ============================================================
-- QUERY
-- ============================================================


isRunning : AnimGroup -> Bool
isRunning =
    getPropertyStates
        >> AnimGroups.groups
        >> List.any (\prop -> prop.status == Running)


isComplete : AnimGroup -> Bool
isComplete =
    getPropertyStates
        >> AnimGroups.groups
        >> List.all (\prop -> prop.status == Complete)


isPaused : AnimGroup -> Bool
isPaused =
    getPropertyStates
        >> AnimGroups.groups
        >> List.any (\prop -> prop.status == Paused)


getAnimationDirection : AnimGroup -> Builder.AnimationDirection
getAnimationDirection (AnimGroup group) =
    group.animationDirection


getCurrentIteration : AnimGroup -> Int
getCurrentIteration (AnimGroup group) =
    group.currentIteration


{-| Look up the cached resize-aware leg state for a given property name
("translate", "scale", "perspectiveOrigin", ...). Returns `Nothing`
when no resize has fired yet for that property on this group.
-}
getResizeState : String -> AnimGroup -> Maybe ResizeAxisState
getResizeState propName (AnimGroup group) =
    Dict.get propName group.resizeStates


getDiscreteEntry : AnimGroup -> Dict String Builder.DiscreteEntryProperty
getDiscreteEntry (AnimGroup group) =
    group.discreteEntry


getDiscreteExit : AnimGroup -> Dict String Builder.DiscreteExitProperty
getDiscreteExit (AnimGroup group) =
    group.discreteExit


getIterations : AnimGroup -> Builder.Iterations
getIterations (AnimGroup group) =
    group.iterations


getProgress : AnimGroup -> Float
getProgress (AnimGroup group) =
    group.progress


getPropertySnapshot : AnimGroup -> PropertyBaselines
getPropertySnapshot (AnimGroup group) =
    group.propertySnapshot


getPropertyStates : AnimGroup -> AnimGroups PropertyState
getPropertyStates (AnimGroup group) =
    group.propertyStates


getTransformOrder : AnimGroup -> List TransformProperty
getTransformOrder (AnimGroup group) =
    group.transformOrder



-- ============================================================
-- Transform
-- ============================================================


{-| Fold over every cached resize-aware leg state on this group. Used by
the animate-restart flow to dispatch a per-property rebase function (one
per property name) against the most recent post-resize bounds.
-}
foldResizeStates : (String -> ResizeAxisState -> b -> b) -> b -> AnimGroup -> b
foldResizeStates f acc (AnimGroup group) =
    Dict.foldl f acc group.resizeStates
