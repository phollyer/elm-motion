module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimGroupConfig
    , AnimationConfig
    , AnimationDirection(..)
    , AnimationMode(..)
    , AxisBounds
    , Bounds
    , DefaultsConfig
    , DiscreteEntryProperty
    , DiscreteExitProperty
    , ForKeyframe
    , ForResizeSub
    , ForResizeWAAPI
    , ForScroll
    , ForSub
    , ForTransition
    , ForView
    , ForWAAPI
    , FreezeProperty(..)
    , HistoryKind(..)
    , Iterations(..)
    , PlaybackConfig
    , ProcessedAnimGroupConfig
    , ProcessedAnimationConfig
    , ProcessedAnimationData
    , ProcessedPropertyConfig(..)
    , PropertyConfig(..)
    , ScrollDrivenConfig
    , TransformParts
    , addAnimationToHistory
    , addRetargetToHistory
    , alternate
    , clearAnimData
    , clearClamp
    , cssUnit
    , cssUnitHeight
    , cssUnitWidth
    , cssUnitX
    , cssUnitY
    , cssUnitZ
    , delay
    , discreteEntry
    , discreteExit
    , discreteTransitionsEnabled
    , duration
    , easing
    , emptyTransformParts
    , extractTransformsFromProcessed
    , extractTransformsFromProperty
    , for
    , freezeAxes
    , getAllFrozenAxes
    , getAllTouchedAxes
    , getAnimGroupConfig
    , getAnimGroups
    , getAnimTarget
    , getAnimationConfigs
    , getAnimationDirection
    , getBaseline
    , getClamp
    , getCurrentAnimGroupConfig
    , getCurrentAnimGroupName
    , getCurrentAnimationConfig
    , getDelay
    , getDelayWithDefault
    , getDiscreteEntryProperties
    , getDiscreteExitProperties
    , getEasing
    , getEasingWithDefault
    , getEmitProgress
    , getFrozenAxes
    , getIterations
    , getLatestAnimateConfig
    , getPerspectiveOriginInitCssUnit
    , getRuntimeBaseline
    , getScrollAxis
    , getScrollEmitProgress
    , getScrollSource
    , getSizeInitCssUnit
    , getSpring
    , getTimeSpec
    , getTimeSpecWithDefault
    , getTransformOrder
    , getTranslateInitCssUnit
    , getViewRangeEnd
    , getViewRangeStart
    , init
    , initDefaults
    , initPlayback
    , injectCurrentStates
    , iterations
    , loopForever
    , markAxes
    , markTouchedAxes
    , mergeBaselines
    , normalizeTransformOrder
    , partitionByMode
    , partitionForResize
    , process
    , processProperties
    , processedPropertyMode
    , processedPropertyType
    , processedTimings
    , setAnimTarget
    , setBaselinesFromProcessedEnds
    , setClamp
    , setEmitProgress
    , setPerspectiveOriginInitCssUnit
    , setPerspectiveOriginInitCssUnitX
    , setPerspectiveOriginInitCssUnitY
    , setScrollAxis
    , setScrollEmitProgress
    , setScrollSource
    , setSizeInitCssUnit
    , setSizeInitCssUnitHeight
    , setSizeInitCssUnitWidth
    , setTranslateInitCssUnit
    , setTranslateInitCssUnitX
    , setTranslateInitCssUnitY
    , setTranslateInitCssUnitZ
    , setViewRangeEnd
    , setViewRangeStart
    , speed
    , spring
    , transformOrder
    , transitionMode
    , unfreezeAxes
    , updateBaselines
    , updateCurrentConfig
    , willChangeComposite
    , willChangeIndividual
    , withCurrentAnimGroup
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Unit as InternalUnit
import Anim.Unit exposing (Unit(..))
import Dict exposing (Dict)
import Motion.Easing exposing (Easing(..))
import Motion.Internal.Spring as SpringInt exposing (Spring)
import Set exposing (Set)
import Shared.Spring as SpringSolver
import Shared.TimeSpec as TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type AnimBuilder eng
    = AnimBuilder BuilderData



-- Available `eng`s


type alias ForTransition =
    { forTransition : ()
    , withTiming : ()
    }


type alias ForKeyframe =
    { forKeyframe : ()
    , withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    }


type alias ForSub =
    { forSub : ()
    , withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    , withLiveDelta : ()
    }


type alias ForWAAPI =
    { forWAAPI : ()
    , withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    , withLiveDelta : ()
    }


type alias ForScroll =
    { forScroll : ()
    , withSpring : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    }


type alias ForView =
    { forView : ()
    , withSpring : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    }


{-| Engine capability tag for a `Sub.onResize` builder callback. Same
shape as [`ForSub`](#ForSub) plus `withBounds`, which unlocks the
resize-only [`bounds`](Anim-Property-Translate#bounds) /
[`position`](Anim-Property-Translate#position) functions. Inside a
regular `Sub.animate` callback (which receives a `ForSub` builder), the
absence of `withBounds` makes those calls a compile error.
-}
type alias ForResizeSub =
    { forSub : ()
    , withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    , withLiveDelta : ()
    , withBounds : ()
    }


{-| Engine capability tag for a `WAAPI.onResize` builder callback. Same
shape as [`ForWAAPI`](#ForWAAPI) plus `withBounds`, which unlocks the
resize-only [`bounds`](Anim-Property-Translate#bounds) /
[`position`](Anim-Property-Translate#position) functions. Inside a
regular `WAAPI.animate` callback (which receives a `ForWAAPI` builder),
the absence of `withBounds` makes those calls a compile error.
-}
type alias ForResizeWAAPI =
    { forWAAPI : ()
    , withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    , withLiveDelta : ()
    , withBounds : ()
    }



-- Configuration records


type alias BuilderData =
    { defaults : DefaultsConfig
    , animation : AnimGroupData
    , playback : PlaybackConfig
    , state : PersistentState
    , scrollDriven : ScrollDrivenConfig
    , emitProgress : Bool
    }



-- Defaults Configuration


{-| Global timing, easing, delay, length unit, and transform order defaults.
-}
type alias DefaultsConfig =
    { globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalSpring : Maybe Spring
    , globalDelay : Maybe Int
    , globalCssUnit : InternalUnit.CssUnitAxes
    , globalSizeCssUnit : InternalUnit.CssUnitAxes
    , globalTransformOrder : Maybe (List TransformProperty)
    , translateInitCssUnit : InternalUnit.CssUnitAxes
    , sizeInitCssUnit : InternalUnit.CssUnitAxes
    , perspectiveOriginInitCssUnit : InternalUnit.CssUnitAxes
    }



-- Animation Group Data


type alias AnimGroupName =
    String


{-| Current animation group data cleared between animate calls.
-}
type alias AnimGroupData =
    { currentAnimGroup : Maybe AnimGroupName
    , animGroups : AnimGroups AnimGroupConfig
    , frozenAxes : Dict String (List String)
    , touchedAxes : Dict ( AnimGroupName, String ) (Set String)
    }


type alias AnimGroupConfig =
    { properties : List PropertyConfig
    , transformOrder : Maybe (List TransformProperty)
    }


type alias ProcessedAnimGroupConfig =
    { properties : List ProcessedPropertyConfig
    , transformOrder : Maybe (List TransformProperty)
    }


type PropertyConfig
    = CustomPropertyConfig String String (AnimationConfig Float)
    | CustomColorPropertyConfig String (AnimationConfig Color)
    | OpacityConfig (AnimationConfig Opacity)
    | PerspectiveOriginConfig (AnimationConfig PerspectiveOrigin)
    | RotateConfig (AnimationConfig Rotate)
    | ScaleConfig (AnimationConfig Scale)
    | SizeConfig (AnimationConfig Size)
    | SkewConfig (AnimationConfig Skew)
    | TranslateConfig (AnimationConfig Translate)


type alias AnimationConfig targetProperty =
    { start : Maybe targetProperty
    , end : targetProperty
    , distance : Float
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , spring : Maybe Spring
    , delay : Maybe Int
    , cssUnit : InternalUnit.CssUnitAxes
    , mode : AnimationMode
    }


{-| How an engine should consume an `AnimationConfig`.

  - `Animate` — normal interpolated transition.
  - `Snap` — silently cancel any in-flight animation on the affected
    axis and jump to `end`.
  - `RemapToBounds` — resize-only directive: proportionally remap the
    current animation onto the supplied bounds (preserving in-flight
    progress) and pin its endpoints to the new range.

Engines outside `onResize` (i.e. the `animate` path of every engine)
ignore `RemapToBounds`. The `withBounds` phantom on engine tags makes
that the compiler's job, but the partition helpers also defensively
filter, so a stray Bounds entry in a regular `animate` builder is a
no-op rather than a crash.

-}
type AnimationMode
    = Animate
    | Snap
    | RemapToBounds AxisBounds


{-| Inclusive numeric range for one axis.
-}
type alias Bounds =
    { min : Float, max : Float }


{-| Per-axis resize bounds. `Nothing` leaves an axis untouched.
-}
type alias AxisBounds =
    { x : Maybe Bounds
    , y : Maybe Bounds
    , z : Maybe Bounds
    }


type ProcessedPropertyConfig
    = ProcessedCustomPropertyConfig String String (ProcessedAnimationConfig Float)
    | ProcessedCustomColorPropertyConfig String (ProcessedAnimationConfig Color)
    | ProcessedOpacityConfig (ProcessedAnimationConfig Opacity)
    | ProcessedPerspectiveOriginConfig (ProcessedAnimationConfig PerspectiveOrigin)
    | ProcessedRotateConfig (ProcessedAnimationConfig Rotate)
    | ProcessedScaleConfig (ProcessedAnimationConfig Scale)
    | ProcessedSizeConfig (ProcessedAnimationConfig Size)
    | ProcessedSkewConfig (ProcessedAnimationConfig Skew)
    | ProcessedTranslateConfig (ProcessedAnimationConfig Translate)


type alias ProcessedAnimationConfig targetProperty =
    { start : Maybe targetProperty
    , end : targetProperty
    , duration : Int
    , speed : Float
    , distance : Float
    , timing : TimeSpec
    , easing : Easing
    , spring : Maybe Spring
    , cssUnit : InternalUnit.ResolvedCssUnitAxes
    , delay : Int
    , mode : AnimationMode
    }


type alias ProcessedAnimationData =
    { groups : AnimGroups ProcessedAnimGroupConfig
    , globalTiming : Maybe TimeSpec
    , globalEasing : Maybe Easing
    , globalSpring : Maybe Spring
    , globalDelay : Maybe Int
    , globalCssUnit : InternalUnit.CssUnitAxes
    , iterations : Iterations
    , animationDirection : AnimationDirection
    }


{-| Persistent state preserved across animate calls.
-}
type alias PersistentState =
    { animationHistories : AnimGroups AnimationHistory
    , baselines : AnimGroups PropertyBaselines
    , runtimeBaselines : AnimGroups PropertyBaselines
    , propertyClamps : Dict ( AnimGroupName, String, String ) ( Float, Float )
    }


{-| Animation history for a single element.

  - current: The most recent animation (if any)
  - history: Previous animations (most recent first)

Each entry is tagged with its `HistoryKind` so that `reset` can distinguish
a user-initiated `animate` (the rest position to return to) from a
mid-flight `retarget` (whose synthesised `start` reflects the in-flight
position, not the original anchor).

-}
type alias AnimationHistory =
    { current : HistoryEntry
    , history : List HistoryEntry
    }


type alias HistoryEntry =
    { kind : HistoryKind
    , config : ProcessedAnimGroupConfig
    }


type HistoryKind
    = AnimateKind
    | RetargetKind



-- Playback Configuration


type alias DiscreteEntryProperty =
    String


{-| A discrete CSS property for exit keyframe animations.

  - `from` - The value to hold during the animation
  - `to` - The value to flip to at the final step (100%)

-}
type alias DiscreteExitProperty =
    { from : String
    , to : String
    }


{-| Playback configuration for iteration, direction, and discrete transitions.
-}
type alias PlaybackConfig =
    { iterations : Iterations
    , animationDirection : AnimationDirection
    , discreteTransitions : Bool
    , discreteEntryProperties : Dict String DiscreteEntryProperty
    , discreteExitProperties : Dict String DiscreteExitProperty
    }


{-| Specifies how many times an animation should repeat.

  - `Once` - Animation plays once and stops (default)
  - `Times n` - Animation repeats exactly n times
  - `Infinite` - Animation loops forever

-}
type Iterations
    = Once
    | Times Int
    | Infinite


{-| Specifies the direction an animation should play.

  - `Normal` - Animation plays forwards each iteration (default)
  - `Alternate` - Animation alternates direction each iteration (ping-pong)

-}
type AnimationDirection
    = Normal
    | Alternate



-- Scroll-Driven Animation Configuration


type alias ScrollDrivenConfig =
    { source : Maybe String
    , axis : Maybe String
    , viewRangeStart : Maybe String
    , viewRangeEnd : Maybe String
    , emitProgress : Bool
    , targets : AnimGroups String
    }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (AnimBuilder eng -> AnimBuilder eng) -> AnimBuilder eng
init =
    List.foldl (\f b -> f b) <|
        AnimBuilder
            { defaults = initDefaults
            , animation = initAnimation
            , playback = initPlayback
            , state = initState
            , scrollDriven = initScrollDrivenConfig
            , emitProgress = False
            }


initDefaults : DefaultsConfig
initDefaults =
    { globalTiming = Nothing
    , globalEasing = Nothing
    , globalSpring = Nothing
    , globalDelay = Nothing
    , globalCssUnit = InternalUnit.emptyCssUnitAxes
    , globalSizeCssUnit = InternalUnit.emptyCssUnitAxes
    , globalTransformOrder = Nothing
    , translateInitCssUnit = InternalUnit.emptyCssUnitAxes
    , sizeInitCssUnit = InternalUnit.emptyCssUnitAxes
    , perspectiveOriginInitCssUnit = InternalUnit.emptyCssUnitAxes
    }


initAnimation : AnimGroupData
initAnimation =
    { currentAnimGroup = Nothing
    , animGroups = AnimGroups.init
    , frozenAxes = Dict.empty
    , touchedAxes = Dict.empty
    }


initPlayback : PlaybackConfig
initPlayback =
    { iterations = Once
    , animationDirection = Normal
    , discreteTransitions = False
    , discreteEntryProperties = Dict.empty
    , discreteExitProperties = Dict.empty
    }


initState : PersistentState
initState =
    { animationHistories = AnimGroups.init
    , baselines = AnimGroups.init
    , runtimeBaselines = AnimGroups.init
    , propertyClamps = Dict.empty
    }


initScrollDrivenConfig : ScrollDrivenConfig
initScrollDrivenConfig =
    { source = Nothing
    , axis = Nothing
    , viewRangeStart = Nothing
    , viewRangeEnd = Nothing
    , emitProgress = False
    , targets = AnimGroups.init
    }



-- ============================================================
-- DEFAULTS
-- ============================================================


duration : Int -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
duration ms (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Duration ms) } }


speed : Float -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
speed value (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Speed value) } }


easing : Easing -> AnimBuilder eng -> AnimBuilder eng
easing easingValue (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalEasing = Just easingValue
                    , globalSpring = Nothing
                }
        }


spring : Spring -> AnimBuilder { eng | withSpring : () } -> AnimBuilder { eng | withSpring : () }
spring springValue (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalSpring = Just springValue
                    , globalEasing = Nothing
                }
        }


delay : Int -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
delay ms (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalDelay =
                        Just <|
                            ms
                }
        }


cssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data
            | defaults =
                { defs
                    | globalCssUnit = InternalUnit.setAllCssUnitAxes unit defs.globalCssUnit
                    , globalSizeCssUnit = InternalUnit.setAllCssUnitAxes unit defs.globalSizeCssUnit
                }
        }


cssUnitX : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitX unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalCssUnit = InternalUnit.setCssUnitX unit defs.globalCssUnit } }


cssUnitY : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitY unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalCssUnit = InternalUnit.setCssUnitY unit defs.globalCssUnit } }


cssUnitZ : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitZ unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalCssUnit = InternalUnit.setCssUnitZ unit defs.globalCssUnit } }


cssUnitWidth : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitWidth unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalSizeCssUnit = InternalUnit.setCssUnitX unit defs.globalSizeCssUnit } }


cssUnitHeight : Unit -> AnimBuilder eng -> AnimBuilder eng
cssUnitHeight unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalSizeCssUnit = InternalUnit.setCssUnitY unit defs.globalSizeCssUnit } }



-- Per-property init-time CSS unit defaults. Set by the public
-- `Translate.initUnit*` / `Size.initUnit*` / `PerspectiveOrigin.initUnit*`
-- families; consumed by the corresponding `init*` value helpers when they
-- create the AnimationConfig.


setTranslateInitCssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
setTranslateInitCssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setAllCssUnitAxes unit defs.translateInitCssUnit } }


setTranslateInitCssUnitX : Unit -> AnimBuilder eng -> AnimBuilder eng
setTranslateInitCssUnitX unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setCssUnitX unit defs.translateInitCssUnit } }


setTranslateInitCssUnitY : Unit -> AnimBuilder eng -> AnimBuilder eng
setTranslateInitCssUnitY unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setCssUnitY unit defs.translateInitCssUnit } }


setTranslateInitCssUnitZ : Unit -> AnimBuilder eng -> AnimBuilder eng
setTranslateInitCssUnitZ unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setCssUnitZ unit defs.translateInitCssUnit } }


getTranslateInitCssUnit : AnimBuilder eng -> InternalUnit.CssUnitAxes
getTranslateInitCssUnit (AnimBuilder data) =
    data.defaults.translateInitCssUnit


setSizeInitCssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
setSizeInitCssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | sizeInitCssUnit = InternalUnit.setAllCssUnitAxes unit defs.sizeInitCssUnit } }


setSizeInitCssUnitWidth : Unit -> AnimBuilder eng -> AnimBuilder eng
setSizeInitCssUnitWidth unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | sizeInitCssUnit = InternalUnit.setCssUnitX unit defs.sizeInitCssUnit } }


setSizeInitCssUnitHeight : Unit -> AnimBuilder eng -> AnimBuilder eng
setSizeInitCssUnitHeight unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | sizeInitCssUnit = InternalUnit.setCssUnitY unit defs.sizeInitCssUnit } }


getSizeInitCssUnit : AnimBuilder eng -> InternalUnit.CssUnitAxes
getSizeInitCssUnit (AnimBuilder data) =
    data.defaults.sizeInitCssUnit


setPerspectiveOriginInitCssUnit : Unit -> AnimBuilder eng -> AnimBuilder eng
setPerspectiveOriginInitCssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | perspectiveOriginInitCssUnit = InternalUnit.setAllCssUnitAxes unit defs.perspectiveOriginInitCssUnit } }


setPerspectiveOriginInitCssUnitX : Unit -> AnimBuilder eng -> AnimBuilder eng
setPerspectiveOriginInitCssUnitX unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | perspectiveOriginInitCssUnit = InternalUnit.setCssUnitX unit defs.perspectiveOriginInitCssUnit } }


setPerspectiveOriginInitCssUnitY : Unit -> AnimBuilder eng -> AnimBuilder eng
setPerspectiveOriginInitCssUnitY unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | perspectiveOriginInitCssUnit = InternalUnit.setCssUnitY unit defs.perspectiveOriginInitCssUnit } }


getPerspectiveOriginInitCssUnit : AnimBuilder eng -> InternalUnit.CssUnitAxes
getPerspectiveOriginInitCssUnit (AnimBuilder data) =
    data.defaults.perspectiveOriginInitCssUnit


transformOrder : List TransformProperty -> AnimBuilder { eng | withTransformOrder : () } -> AnimBuilder { eng | withTransformOrder : () }
transformOrder order (AnimBuilder data) =
    let
        normalizedOrder =
            Just (normalizeTransformOrder order)

        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTransformOrder = normalizedOrder } }


normalizeTransformOrder : List TransformProperty -> List TransformProperty
normalizeTransformOrder order =
    let
        removeDuplicates : List TransformProperty -> List TransformProperty -> List TransformProperty
        removeDuplicates seen remaining =
            case remaining of
                [] ->
                    List.reverse seen

                x :: xs ->
                    if List.member x seen then
                        removeDuplicates seen xs

                    else
                        removeDuplicates (x :: seen) xs

        deduped =
            removeDuplicates [] order

        defaultOrder =
            [ Translate, Rotate, Skew, Scale ]

        missing =
            List.filter (\t -> not (List.member t deduped)) defaultOrder
    in
    deduped ++ missing



-- ============================================================
-- ANIMATION TARGETING
-- ============================================================


for : String -> AnimBuilder eng -> AnimBuilder eng
for elementId (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder
        { data | animation = { anim | currentAnimGroup = Just elementId } }


{-| Get the current (most recent) animation for a group.
-}
getCurrentAnimationConfig : AnimGroupName -> AnimBuilder eng -> Maybe ProcessedAnimGroupConfig
getCurrentAnimationConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.state.animationHistories
        |> Maybe.map (.current >> .config)


getAnimationConfigs : AnimGroupName -> AnimBuilder eng -> List ProcessedAnimGroupConfig
getAnimationConfigs animGroupName (AnimBuilder data) =
    case AnimGroups.get animGroupName data.state.animationHistories of
        Nothing ->
            []

        Just h ->
            (h.current :: h.history) |> List.map .config


{-| Walk current then history, returning the most recent entry tagged as
`AnimateKind` - i.e. the last user-initiated `animate` call, ignoring any
subsequent `retarget` entries. Used by `reset` so it returns to the rest
position established by the original animate, not to the synthesised
mid-flight `start` produced by a retarget.

Falls back to the most recent entry of any kind (matching legacy behaviour)
when no `AnimateKind` entry exists - e.g. if retarget were ever invoked
before any animate.

-}
getLatestAnimateConfig : AnimGroupName -> AnimBuilder eng -> Maybe ProcessedAnimGroupConfig
getLatestAnimateConfig animGroupName (AnimBuilder data) =
    data.state.animationHistories
        |> AnimGroups.get animGroupName
        |> Maybe.andThen
            (\h ->
                let
                    isAnimate entry =
                        case entry.kind of
                            AnimateKind ->
                                True

                            RetargetKind ->
                                False
                in
                (h.current :: h.history)
                    |> List.filter isAnimate
                    |> List.head
                    |> Maybe.map .config
                    |> (\result ->
                            case result of
                                Just _ ->
                                    result

                                Nothing ->
                                    Just h.current.config
                       )
            )



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> AnimBuilder { eng | withIterations : () } -> AnimBuilder { eng | withIterations : () }
iterations count (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | iterations = Times count } }


loopForever : AnimBuilder { eng | withLoopForever : () } -> AnimBuilder { eng | withLoopForever : () }
loopForever (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | iterations = Infinite } }


alternate : AnimBuilder { eng | withAlternate : () } -> AnimBuilder { eng | withAlternate : () }
alternate (AnimBuilder data) =
    let
        pb =
            data.playback

        bumpedIterations =
            case pb.iterations of
                Once ->
                    Times 2

                _ ->
                    pb.iterations
    in
    AnimBuilder
        { data
            | playback =
                { pb
                    | animationDirection = Alternate
                    , iterations = bumpedIterations
                }
        }


discreteTransitionsEnabled : AnimBuilder eng -> Bool
discreteTransitionsEnabled (AnimBuilder data) =
    data.playback.discreteTransitions


{-| Add a discrete CSS property for entry animations.

The value is applied when the animation starts, ensuring the element is
immediately in the target state.

    discreteEntry "display" "block"

-}
discreteEntry : String -> String -> AnimBuilder eng -> AnimBuilder eng
discreteEntry propertyName value (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder
        { data
            | playback =
                { pb
                    | discreteTransitions = True
                    , discreteEntryProperties =
                        Dict.insert propertyName value pb.discreteEntryProperties
                }
        }


{-| Add a discrete CSS property for exit animations.

The `from` value is held during the animation and flips to the `to` value
when the animation ends.

    discreteExit "display" "block" "none"

-}
discreteExit : String -> String -> String -> AnimBuilder eng -> AnimBuilder eng
discreteExit propertyName from to (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder
        { data
            | playback =
                { pb
                    | discreteTransitions = True
                    , discreteExitProperties =
                        Dict.insert propertyName { from = from, to = to } pb.discreteExitProperties
                }
        }


getDiscreteEntryProperties : AnimBuilder eng -> Dict String String
getDiscreteEntryProperties (AnimBuilder data) =
    data.playback.discreteEntryProperties


getDiscreteExitProperties : AnimBuilder eng -> Dict String DiscreteExitProperty
getDiscreteExitProperties (AnimBuilder data) =
    data.playback.discreteExitProperties


getIterations : AnimBuilder eng -> Iterations
getIterations (AnimBuilder data) =
    data.playback.iterations


getAnimationDirection : AnimBuilder eng -> AnimationDirection
getAnimationDirection (AnimBuilder data) =
    data.playback.animationDirection



-- ============================================================
-- FREEZE AXES
-- ============================================================


type FreezeProperty
    = FreezeTranslate
    | FreezeRotate
    | FreezeScale
    | FreexeSkew


freezeAxes : List String -> List FreezeProperty -> AnimBuilder eng -> AnimBuilder eng
freezeAxes axes properties (AnimBuilder data) =
    let
        propNames =
            List.map freezePropertyName properties

        anim =
            data.animation

        newFrozenAxes =
            List.foldl
                (\propName dict ->
                    Dict.update propName
                        (\maybeAxes ->
                            case maybeAxes of
                                Just existing ->
                                    Just (List.foldl addIfMissing existing axes)

                                Nothing ->
                                    Just axes
                        )
                        dict
                )
                anim.frozenAxes
                propNames
    in
    AnimBuilder { data | animation = { anim | frozenAxes = newFrozenAxes } }


unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder eng -> AnimBuilder eng
unfreezeAxes axes properties (AnimBuilder data) =
    let
        propNames =
            List.map freezePropertyName properties

        anim =
            data.animation

        newFrozenAxes =
            List.foldl
                (\propName dict ->
                    Dict.update propName
                        (Maybe.map <|
                            List.filter (\a -> not (List.member a axes))
                        )
                        dict
                )
                anim.frozenAxes
                propNames
    in
    AnimBuilder { data | animation = { anim | frozenAxes = newFrozenAxes } }


{-| Get the list of frozen axes for a property. Returns [] if none are frozen.
-}
getFrozenAxes : String -> AnimBuilder eng -> List String
getFrozenAxes propName (AnimBuilder data) =
    Dict.get propName data.animation.frozenAxes |> Maybe.withDefault []


{-| Get the full frozen-axes dictionary keyed by property name. Used by
engines that need to forward freeze information to a downstream consumer
(e.g. the WAAPI JS layer, which overrides frozen axes with live-rendered
values to avoid snap-back from stale Elm snapshots).
-}
getAllFrozenAxes : AnimBuilder eng -> Dict String (List String)
getAllFrozenAxes (AnimBuilder data) =
    data.animation.frozenAxes


{-| Mark axes of a property as having been explicitly set by the user's
builder pipeline (via `toX`, `toY`, etc.). Used by `WAAPI.retarget` to
distinguish user-targeted axes (which snap to the new target) from
untouched axes (which continue their in-flight animation to its
existing end target). Cleared between animate calls via `initAnimation`.
-}
markTouchedAxes : AnimGroupName -> String -> List String -> AnimBuilder eng -> AnimBuilder eng
markTouchedAxes animGroupName propName axes (AnimBuilder data) =
    let
        anim =
            data.animation

        newTouchedAxes =
            Dict.update ( animGroupName, propName )
                (\maybeSet ->
                    case maybeSet of
                        Just existing ->
                            Just (List.foldl Set.insert existing axes)

                        Nothing ->
                            Just (Set.fromList axes)
                )
                anim.touchedAxes
    in
    AnimBuilder { data | animation = { anim | touchedAxes = newTouchedAxes } }


{-| Get the full touched-axes dictionary keyed by (animGroupName, propertyName).
-}
getAllTouchedAxes : AnimBuilder eng -> Dict ( AnimGroupName, String ) (Set String)
getAllTouchedAxes (AnimBuilder data) =
    data.animation.touchedAxes


addIfMissing : a -> List a -> List a
addIfMissing item list =
    if List.member item list then
        list

    else
        item :: list


freezePropertyName : FreezeProperty -> String
freezePropertyName prop =
    case prop of
        FreezeTranslate ->
            "translate"

        FreezeRotate ->
            "rotate"

        FreezeScale ->
            "scale"

        FreexeSkew ->
            "skew"



-- ============================================================
-- QUERY
-- ============================================================


getAnimGroups : AnimBuilder eng -> AnimGroups AnimGroupConfig
getAnimGroups (AnimBuilder data) =
    data.animation.animGroups


{-| Name of the animGroup the next pipeline step will configure, or `Nothing` if not set.
-}
getCurrentAnimGroupName : AnimBuilder eng -> Maybe AnimGroupName
getCurrentAnimGroupName (AnimBuilder data) =
    data.animation.currentAnimGroup


getCurrentAnimGroupConfig : AnimBuilder eng -> AnimGroupConfig
getCurrentAnimGroupConfig (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            { properties = [], transformOrder = data.defaults.globalTransformOrder }

        Just animGroupName ->
            AnimGroups.get animGroupName data.animation.animGroups
                |> Maybe.map
                    (\config ->
                        { config
                            | transformOrder =
                                case data.defaults.globalTransformOrder of
                                    Just globalOrder ->
                                        Just globalOrder

                                    Nothing ->
                                        config.transformOrder
                        }
                    )
                |> Maybe.withDefault { properties = [], transformOrder = data.defaults.globalTransformOrder }


getAnimGroupConfig : AnimGroupName -> AnimBuilder eng -> Maybe AnimGroupConfig
getAnimGroupConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.animation.animGroups


{-| Get baseline states for a group.
Baselines reflect the last known property values - either animation targets
or runtime snapshots from active animations.
-}
getBaseline : String -> AnimBuilder eng -> Maybe PropertyBaselines
getBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.baselines


getRuntimeBaseline : String -> AnimBuilder eng -> Maybe PropertyBaselines
getRuntimeBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.runtimeBaselines


getTransformOrder : AnimGroupName -> AnimBuilder eng -> Maybe (List TransformProperty)
getTransformOrder animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.animation.animGroups
        |> Maybe.andThen .transformOrder
        |> orElse data.defaults.globalTransformOrder


orElse : Maybe a -> Maybe a -> Maybe a
orElse fallback primary =
    case primary of
        Just _ ->
            primary

        Nothing ->
            fallback


getTimeSpec : AnimBuilder eng -> Maybe TimeSpec
getTimeSpec (AnimBuilder data) =
    data.defaults.globalTiming


getTimeSpecWithDefault : AnimBuilder eng -> TimeSpec
getTimeSpecWithDefault (AnimBuilder data) =
    data.defaults.globalTiming |> Maybe.withDefault (Duration 0)


getEasing : AnimBuilder eng -> Maybe Easing
getEasing (AnimBuilder data) =
    data.defaults.globalEasing


getSpring : AnimBuilder eng -> Maybe Spring
getSpring (AnimBuilder data) =
    data.defaults.globalSpring


getEasingWithDefault : AnimBuilder eng -> Easing
getEasingWithDefault (AnimBuilder data) =
    data.defaults.globalEasing |> Maybe.withDefault QuintOut


getDelay : AnimBuilder eng -> Maybe Int
getDelay (AnimBuilder data) =
    data.defaults.globalDelay


getDelayWithDefault : AnimBuilder eng -> Int
getDelayWithDefault (AnimBuilder data) =
    data.defaults.globalDelay |> Maybe.withDefault 0



-- ============================================================
-- STATE MANAGEMENT
-- ============================================================


{-| Inject current animated states as baselines for the next animation.
This prevents mid-flight animation jumps by ensuring property builders copy from
current animated positions rather than old animation end positions.

Merges runtime snapshots into baselines rather than replacing them, so completed
groups' baselines are preserved.

-}
injectCurrentStates : AnimGroups { a | propertySnapshot : PropertyBaselines } -> AnimBuilder eng -> AnimBuilder eng
injectCurrentStates animGroups (AnimBuilder data) =
    let
        state =
            data.state

        runtimeSnapshots =
            AnimGroups.map
                (\_ animation -> animation.propertySnapshot)
                animGroups

        mergedRuntimeBaselines =
            AnimGroups.merge
                AnimGroups.insert
                (\key new old -> AnimGroups.insert key (PropertyBaselines.merge old new))
                AnimGroups.insert
                (AnimGroups.toDict runtimeSnapshots)
                (AnimGroups.toDict state.baselines)
                AnimGroups.init
    in
    AnimBuilder
        { data
            | state =
                { state | runtimeBaselines = mergedRuntimeBaselines }
        }


{-| Get a clamp range for a (animGroup, propertyKey, axis) triple, if any.
-}
getClamp : AnimGroupName -> String -> String -> AnimBuilder eng -> Maybe ( Float, Float )
getClamp animGroupName propertyKey axis (AnimBuilder data) =
    Dict.get ( animGroupName, propertyKey, axis ) data.state.propertyClamps


{-| Set a clamp range. Bounds are normalised so the smaller value becomes
the lower bound regardless of argument order.
-}
setClamp : AnimGroupName -> String -> String -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng
setClamp animGroupName propertyKey axis lo hi (AnimBuilder data) =
    let
        state =
            data.state

        nextDict =
            Dict.insert ( animGroupName, propertyKey, axis ) (orderedRange lo hi) state.propertyClamps
    in
    AnimBuilder { data | state = { state | propertyClamps = nextDict } }


{-| Remove a clamp range for a (animGroup, propertyKey, axis) triple.
-}
clearClamp : AnimGroupName -> String -> String -> AnimBuilder eng -> AnimBuilder eng
clearClamp animGroupName propertyKey axis (AnimBuilder data) =
    let
        state =
            data.state

        nextDict =
            Dict.remove ( animGroupName, propertyKey, axis ) state.propertyClamps
    in
    AnimBuilder { data | state = { state | propertyClamps = nextDict } }


orderedRange : Float -> Float -> ( Float, Float )
orderedRange a b =
    if a <= b then
        ( a, b )

    else
        ( b, a )


clearAnimData : AnimBuilder eng -> AnimBuilder eng
clearAnimData (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder
        { data
            | animation = initAnimation
            , playback =
                { pb
                    | discreteEntryProperties = Dict.empty
                    , discreteExitProperties = Dict.empty
                }
        }


mergeBaselines : AnimBuilder eng -> AnimBuilder eng
mergeBaselines (AnimBuilder ({ state, animation, defaults } as data)) =
    let
        newBaselines =
            animation.animGroups
                |> AnimGroups.map (\_ config -> extractBaselinesFromConfig defaults config)

        mergeBoth key new old =
            AnimGroups.insert key (PropertyBaselines.merge old new)

        newState =
            { state
                | baselines =
                    AnimGroups.merge
                        AnimGroups.insert
                        mergeBoth
                        AnimGroups.insert
                        (AnimGroups.toDict newBaselines)
                        (AnimGroups.toDict state.baselines)
                        AnimGroups.init
            }
    in
    AnimBuilder { data | state = newState }


markAxes : String -> List String -> AnimBuilder eng -> AnimBuilder eng
markAxes key axes builder =
    withCurrentAnimGroup (\animGroupName -> markTouchedAxes animGroupName key axes) builder


{-| Run `f` against the current animation group's name when one is set;
otherwise return the builder unchanged. Used by per-property builders to
thread the current group name into operations like clamp updates and
touched-axis marking without each call site reimplementing the
`Maybe` plumbing.
-}
withCurrentAnimGroup : (String -> AnimBuilder eng -> AnimBuilder eng) -> AnimBuilder eng -> AnimBuilder eng
withCurrentAnimGroup f builder =
    case getCurrentAnimGroupName builder of
        Just animGroupName ->
            f animGroupName builder

        Nothing ->
            builder


{-| Amend the stored baselines for a single animGroup using a transform
function.

Used by engines that need to update baselines outside the normal `animate`
pipeline — for example, after a resize that shifts the in-flight
animation's end target. Subsequent builders look up the new end via
`getBaseline` (so that `Translate.for >> Translate.toY` and friends inherit
the resized X/Z values), and that lookup must reflect the post-resize
target rather than the pre-resize one captured by the prior `animate`.

-}
updateBaselines : String -> (PropertyBaselines -> PropertyBaselines) -> AnimBuilder eng -> AnimBuilder eng
updateBaselines key f (AnimBuilder data) =
    let
        state =
            data.state

        current =
            AnimGroups.get key state.baselines
                |> Maybe.withDefault PropertyBaselines.empty
    in
    AnimBuilder
        { data
            | state =
                { state | baselines = AnimGroups.insert key (f current) state.baselines }
        }


extractBaselinesFromConfig : DefaultsConfig -> AnimGroupConfig -> PropertyBaselines
extractBaselinesFromConfig defaults elementConfig =
    List.foldl (extractPropertyBaseline defaults) PropertyBaselines.empty elementConfig.properties


extractPropertyBaseline : DefaultsConfig -> PropertyConfig -> PropertyBaselines -> PropertyBaselines
extractPropertyBaseline defaults propConfig baselines =
    case propConfig of
        TranslateConfig cfg ->
            baselines
                |> PropertyBaselines.setTranslate cfg.end
                |> PropertyBaselines.setTranslateUnits
                    (InternalUnit.resolveCssUnitAxes cfg.cssUnit defaults.globalCssUnit InternalUnit.default)
                |> PropertyBaselines.setTranslateConfiguredUnits cfg.cssUnit

        RotateConfig cfg ->
            PropertyBaselines.setRotate cfg.end baselines

        ScaleConfig cfg ->
            PropertyBaselines.setScale cfg.end baselines

        SkewConfig cfg ->
            PropertyBaselines.setSkew cfg.end baselines

        OpacityConfig cfg ->
            PropertyBaselines.setOpacity cfg.end baselines

        PerspectiveOriginConfig cfg ->
            baselines
                |> PropertyBaselines.setPerspectiveOrigin cfg.end
                |> PropertyBaselines.setPerspectiveOriginUnits
                    (InternalUnit.resolveCssUnitAxes cfg.cssUnit defaults.globalCssUnit Percent)
                |> PropertyBaselines.setPerspectiveOriginConfiguredUnits cfg.cssUnit

        SizeConfig cfg ->
            baselines
                |> PropertyBaselines.setSize cfg.end
                |> PropertyBaselines.setSizeUnits
                    (InternalUnit.resolveCssUnitAxes cfg.cssUnit defaults.globalSizeCssUnit InternalUnit.default)
                |> PropertyBaselines.setSizeConfiguredUnits cfg.cssUnit

        CustomPropertyConfig cssName unit cfg ->
            PropertyBaselines.setCustomProperty cssName cfg.end unit baselines

        CustomColorPropertyConfig cssName cfg ->
            PropertyBaselines.setCustomColorProperty cssName cfg.end baselines


{-| Like `extractPropertyBaseline` but for already-processed property
configs. Reads `.end` and the resolved cssUnit, writing them into the
running baselines.

Used by `setBaselinesFromProcessedEnds` so engines can rewind the stored
baselines after a `reset` snaps the element back to its rest position -
otherwise the next `animate` would synthesise `.start` from the
pre-reset (post-animate) baseline and visually jump to the previous end
value before animating.

-}
extractProcessedPropertyBaseline : ProcessedPropertyConfig -> PropertyBaselines -> PropertyBaselines
extractProcessedPropertyBaseline propConfig baselines =
    case propConfig of
        ProcessedTranslateConfig cfg ->
            baselines
                |> PropertyBaselines.setTranslate cfg.end
                |> PropertyBaselines.setTranslateUnits cfg.cssUnit

        ProcessedRotateConfig cfg ->
            PropertyBaselines.setRotate cfg.end baselines

        ProcessedScaleConfig cfg ->
            PropertyBaselines.setScale cfg.end baselines

        ProcessedSkewConfig cfg ->
            PropertyBaselines.setSkew cfg.end baselines

        ProcessedOpacityConfig cfg ->
            PropertyBaselines.setOpacity cfg.end baselines

        ProcessedPerspectiveOriginConfig cfg ->
            baselines
                |> PropertyBaselines.setPerspectiveOrigin cfg.end
                |> PropertyBaselines.setPerspectiveOriginUnits cfg.cssUnit

        ProcessedSizeConfig cfg ->
            baselines
                |> PropertyBaselines.setSize cfg.end
                |> PropertyBaselines.setSizeUnits cfg.cssUnit

        ProcessedCustomPropertyConfig cssName unit cfg ->
            PropertyBaselines.setCustomProperty cssName cfg.end unit baselines

        ProcessedCustomColorPropertyConfig cssName cfg ->
            PropertyBaselines.setCustomColorProperty cssName cfg.end baselines


{-| Merge a list of processed property configs into the stored baselines
for the given animGroup, taking `.end` from each. Used by `reset` to
rewind baselines to the rest position so the next `animate` reads the
correct anchor for its synthesised `.start`.
-}
setBaselinesFromProcessedEnds : AnimGroupName -> List ProcessedPropertyConfig -> AnimBuilder eng -> AnimBuilder eng
setBaselinesFromProcessedEnds animGroupName props (AnimBuilder data) =
    let
        state =
            data.state

        existing =
            AnimGroups.get animGroupName state.baselines
                |> Maybe.withDefault PropertyBaselines.empty

        merged =
            List.foldl extractProcessedPropertyBaseline existing props
    in
    AnimBuilder
        { data
            | state =
                { state
                    | baselines =
                        AnimGroups.insert animGroupName merged state.baselines
                }
        }


updateCurrentConfig : AnimGroupConfig -> AnimBuilder eng -> AnimBuilder eng
updateCurrentConfig config (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            AnimBuilder data

        Just animKey ->
            let
                anim =
                    data.animation

                -- Get types of new properties to avoid duplicates
                newPropertyTypes =
                    List.map propertyType config.properties

                -- Replace properties of same type (not just append) to avoid accumulation
                mergedConfig =
                    case AnimGroups.get animKey anim.animGroups of
                        Just existing ->
                            let
                                -- Filter out existing properties that would be replaced by new ones
                                filteredExisting =
                                    existing.properties
                                        |> List.filter
                                            (\p -> not (List.member (propertyType p) newPropertyTypes))

                                mergedOrder =
                                    case config.transformOrder of
                                        Just _ ->
                                            config.transformOrder

                                        Nothing ->
                                            existing.transformOrder
                            in
                            { existing
                                | properties = filteredExisting ++ config.properties
                                , transformOrder = mergedOrder
                            }

                        Nothing ->
                            config
            in
            AnimBuilder
                { data | animation = { anim | animGroups = AnimGroups.insert animKey mergedConfig anim.animGroups } }


{-| Get the type tag of a PropertyConfig for comparison.
-}
propertyType : PropertyConfig -> String
propertyType prop =
    case prop of
        CustomPropertyConfig cssName _ _ ->
            "custom:" ++ cssName

        CustomColorPropertyConfig cssName _ ->
            "customColor:" ++ cssName

        OpacityConfig _ ->
            "opacity"

        PerspectiveOriginConfig _ ->
            "perspectiveOrigin"

        RotateConfig _ ->
            "rotate"

        ScaleConfig _ ->
            "scale"

        SizeConfig _ ->
            "size"

        SkewConfig _ ->
            "skew"

        TranslateConfig _ ->
            "translate"


{-| Get the type tag of a ProcessedPropertyConfig. Mirrors `propertyType`
but for the post-process variant.
-}
processedPropertyType : ProcessedPropertyConfig -> String
processedPropertyType prop =
    case prop of
        ProcessedCustomPropertyConfig cssName _ _ ->
            "custom:" ++ cssName

        ProcessedCustomColorPropertyConfig cssName _ ->
            "customColor:" ++ cssName

        ProcessedOpacityConfig _ ->
            "opacity"

        ProcessedPerspectiveOriginConfig _ ->
            "perspectiveOrigin"

        ProcessedRotateConfig _ ->
            "rotate"

        ProcessedScaleConfig _ ->
            "scale"

        ProcessedSizeConfig _ ->
            "size"

        ProcessedSkewConfig _ ->
            "skew"

        ProcessedTranslateConfig _ ->
            "translate"


{-| Extract the [`AnimationMode`](#AnimationMode) from a
[`ProcessedPropertyConfig`](#ProcessedPropertyConfig), regardless of which
property variant it wraps. Used by engines to branch interpolated vs
snapped rendering.
-}
processedPropertyMode : ProcessedPropertyConfig -> AnimationMode
processedPropertyMode prop =
    case prop of
        ProcessedCustomPropertyConfig _ _ cfg ->
            cfg.mode

        ProcessedCustomColorPropertyConfig _ cfg ->
            cfg.mode

        ProcessedOpacityConfig cfg ->
            cfg.mode

        ProcessedPerspectiveOriginConfig cfg ->
            cfg.mode

        ProcessedRotateConfig cfg ->
            cfg.mode

        ProcessedScaleConfig cfg ->
            cfg.mode

        ProcessedSizeConfig cfg ->
            cfg.mode

        ProcessedSkewConfig cfg ->
            cfg.mode

        ProcessedTranslateConfig cfg ->
            cfg.mode


{-| Partition a list of [`ProcessedPropertyConfig`](#ProcessedPropertyConfig)
by [`AnimationMode`](#AnimationMode):

  - `animate` — properties with `mode = Animate` (regular interpolated path).
  - `snap` — properties with `mode = Snap` (jump-to-end path).

`RemapToBounds` entries are dropped: they are resize-time directives
consumed by [`partitionForResize`](#partitionForResize), not by any
`animate` engine path. The `withBounds` phantom on engine tags prevents
these variants from being constructed in the regular `animate` builder
pipeline; this filter is the runtime backstop.

-}
partitionByMode :
    List ProcessedPropertyConfig
    -> { animate : List ProcessedPropertyConfig, snap : List ProcessedPropertyConfig }
partitionByMode props =
    let
        step prop acc =
            case processedPropertyMode prop of
                Animate ->
                    { acc | animate = prop :: acc.animate }

                Snap ->
                    { acc | snap = prop :: acc.snap }

                RemapToBounds _ ->
                    acc
    in
    List.foldr step { animate = [], snap = [] } props


{-| Partition a list of [`ProcessedPropertyConfig`](#ProcessedPropertyConfig)
into the three buckets consumed by an engine's `onResize` path. The list's
input order is preserved within each bucket so that engines can implement
"last entry wins" semantics per (group, property) by replaying the
combined stream in source order.

  - `animate` — `mode = Animate` (regular animation, started inside resize).
  - `snap` — `mode = Snap` (instantaneous jump-to-end).
  - `bounds` — `mode = RemapToBounds bounds`.

-}
partitionForResize :
    List ProcessedPropertyConfig
    ->
        { animate : List ProcessedPropertyConfig
        , snap : List ProcessedPropertyConfig
        , bounds : List ( ProcessedPropertyConfig, AxisBounds )
        }
partitionForResize props =
    let
        step prop acc =
            case processedPropertyMode prop of
                Animate ->
                    { acc | animate = prop :: acc.animate }

                Snap ->
                    { acc | snap = prop :: acc.snap }

                RemapToBounds ranges ->
                    { acc | bounds = ( prop, ranges ) :: acc.bounds }
    in
    List.foldr step
        { animate = [], snap = [], bounds = [] }
        props


{-| Extract `duration` and `delay` (in milliseconds) from a
[`ProcessedPropertyConfig`](#ProcessedPropertyConfig), regardless of which
property variant it wraps.
-}
processedTimings : ProcessedPropertyConfig -> { duration : Int, delay : Int }
processedTimings prop =
    case prop of
        ProcessedCustomPropertyConfig _ _ cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedCustomColorPropertyConfig _ cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedOpacityConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedPerspectiveOriginConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedRotateConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedScaleConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedSizeConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedSkewConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }

        ProcessedTranslateConfig cfg ->
            { duration = cfg.duration, delay = cfg.delay }


{-| Comma-joined `will-change` value for an animation that renders
transforms as the modern individual properties (`translate`, `scale`).
Used by the Transition engine, which writes `translate: ...` and
`scale: ...` directly rather than packing them into `transform: ...`.

Rotate and Skew still collapse to `transform` because there is no
broadly-supported individual `rotate` / `skew` _animatable_ shorthand on
the same rendering path. The returned string preserves the order of
first appearance and is `""` for an empty list.

    willChangeIndividual
        [ ProcessedOpacityConfig cfg
        , ProcessedTranslateConfig cfg
        , ProcessedRotateConfig cfg
        ]
        --> "opacity, translate, transform"

-}
willChangeIndividual : List ProcessedPropertyConfig -> String
willChangeIndividual =
    toWillChangeString cssNamesIndividual


{-| Comma-joined `will-change` value for an animation that renders
transforms via the composite `transform` property. Used by the Keyframe
and Sub engines, which build a single `transform: translate(...) rotate(...)
scale(...) skew(...)` declaration.

All transform-family properties collapse to a single `transform` entry.
The returned string preserves the order of first appearance and is
`""` for an empty list.

    willChangeComposite
        [ ProcessedOpacityConfig cfg
        , ProcessedTranslateConfig cfg
        , ProcessedRotateConfig cfg
        ]
        --> "opacity, transform"

-}
willChangeComposite : List ProcessedPropertyConfig -> String
willChangeComposite =
    toWillChangeString cssNamesComposite


toWillChangeString : (ProcessedPropertyConfig -> List String) -> List ProcessedPropertyConfig -> String
toWillChangeString toNames props =
    props
        |> List.concatMap toNames
        |> dedupePreservingOrder
        |> String.join ", "


cssNamesIndividual : ProcessedPropertyConfig -> List String
cssNamesIndividual prop =
    case prop of
        ProcessedCustomPropertyConfig cssName _ _ ->
            [ cssName ]

        ProcessedCustomColorPropertyConfig cssName _ ->
            [ cssName ]

        ProcessedOpacityConfig _ ->
            [ "opacity" ]

        ProcessedPerspectiveOriginConfig _ ->
            [ "perspective-origin" ]

        ProcessedRotateConfig _ ->
            [ "transform" ]

        ProcessedScaleConfig _ ->
            [ "scale" ]

        ProcessedSizeConfig _ ->
            [ "width", "height" ]

        ProcessedSkewConfig _ ->
            [ "transform" ]

        ProcessedTranslateConfig _ ->
            [ "translate" ]


cssNamesComposite : ProcessedPropertyConfig -> List String
cssNamesComposite prop =
    case prop of
        ProcessedCustomPropertyConfig cssName _ _ ->
            [ cssName ]

        ProcessedCustomColorPropertyConfig cssName _ ->
            [ cssName ]

        ProcessedOpacityConfig _ ->
            [ "opacity" ]

        ProcessedPerspectiveOriginConfig _ ->
            [ "perspective-origin" ]

        ProcessedRotateConfig _ ->
            [ "transform" ]

        ProcessedScaleConfig _ ->
            [ "transform" ]

        ProcessedSizeConfig _ ->
            [ "width", "height" ]

        ProcessedSkewConfig _ ->
            [ "transform" ]

        ProcessedTranslateConfig _ ->
            [ "transform" ]


dedupePreservingOrder : List String -> List String
dedupePreservingOrder =
    List.foldl
        (\name ( seen, acc ) ->
            if Set.member name seen then
                ( seen, acc )

            else
                ( Set.insert name seen, name :: acc )
        )
        ( Set.empty, [] )
        >> Tuple.second
        >> List.reverse



-- ============================================================
-- PROCESSING
-- ============================================================


process : AnimBuilder eng -> ProcessedAnimationData
process (AnimBuilder data) =
    { globalTiming = data.defaults.globalTiming
    , globalEasing = data.defaults.globalEasing
    , globalSpring = data.defaults.globalSpring
    , globalDelay = data.defaults.globalDelay
    , globalCssUnit = data.defaults.globalCssUnit
    , iterations = data.playback.iterations
    , animationDirection = data.playback.animationDirection
    , groups =
        AnimGroups.map
            (\_ group ->
                { properties = processProperties data.defaults group.properties
                , transformOrder =
                    case group.transformOrder of
                        Just _ ->
                            group.transformOrder

                        Nothing ->
                            data.defaults.globalTransformOrder
                }
            )
            data.animation.animGroups
    }


processProperties : DefaultsConfig -> List PropertyConfig -> List ProcessedPropertyConfig
processProperties defaults =
    List.filterMap (processProperty defaults)


processProperty : DefaultsConfig -> PropertyConfig -> Maybe ProcessedPropertyConfig
processProperty globalData property =
    case property of
        CustomPropertyConfig cssName unit config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = 0
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = \a b -> abs (b - a)
                    , durationFn = TimeSpec.duration
                    , speedFn = TimeSpec.speed
                    , wrapper = ProcessedCustomPropertyConfig cssName unit
                    }

        CustomColorPropertyConfig cssName config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = Color.transparent
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Color.distance
                    , durationFn = Color.duration
                    , speedFn = Color.speed
                    , wrapper = ProcessedCustomColorPropertyConfig cssName
                    }

        OpacityConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = Opacity.fromFloat 1.0
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Opacity.distance
                    , durationFn = Opacity.duration
                    , speedFn = Opacity.speed
                    , wrapper = ProcessedOpacityConfig
                    }

        PerspectiveOriginConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = PerspectiveOrigin.default
                    , defaultCssUnit = Percent
                    , distanceFn = PerspectiveOrigin.distance
                    , durationFn = PerspectiveOrigin.duration
                    , speedFn = PerspectiveOrigin.speed
                    , wrapper = ProcessedPerspectiveOriginConfig
                    }

        RotateConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = Rotate.default
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Rotate.distance
                    , durationFn = Rotate.duration
                    , speedFn = Rotate.speed
                    , wrapper = ProcessedRotateConfig
                    }

        ScaleConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = Scale.default
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Scale.distance
                    , durationFn = Scale.duration
                    , speedFn = Scale.speed
                    , wrapper = ProcessedScaleConfig
                    }

        SizeConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalSizeCssUnit
                    , defaultStart = Size.default
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Size.distance
                    , durationFn = Size.duration
                    , speedFn = Size.speed
                    , wrapper = ProcessedSizeConfig
                    }

        SkewConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = Skew.default
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Skew.distance
                    , durationFn = Skew.duration
                    , speedFn = Skew.speed
                    , wrapper = ProcessedSkewConfig
                    }

        TranslateConfig config ->
            Just <|
                processStandardAnimation
                    { config = config
                    , globalData = globalData
                    , globalCssUnit = globalData.globalCssUnit
                    , defaultStart = Translate.default
                    , defaultCssUnit = InternalUnit.default
                    , distanceFn = Translate.distance
                    , durationFn = Translate.duration
                    , speedFn = Translate.speed
                    , wrapper = ProcessedTranslateConfig
                    }


processStandardAnimation :
    { config : AnimationConfig a
    , globalData : DefaultsConfig
    , globalCssUnit : InternalUnit.CssUnitAxes
    , defaultStart : a
    , defaultCssUnit : Unit
    , distanceFn : a -> a -> Float
    , durationFn : Float -> TimeSpec -> Float
    , speedFn : Float -> Float -> TimeSpec -> Float
    , wrapper : ProcessedAnimationConfig a -> ProcessedPropertyConfig
    }
    -> ProcessedPropertyConfig
processStandardAnimation { config, globalData, globalCssUnit, defaultStart, defaultCssUnit, distanceFn, durationFn, speedFn, wrapper } =
    let
        start =
            Maybe.withDefault defaultStart config.start

        distance_ =
            distanceFn start config.end

        resolvedTiming =
            resolveTimingWithDefault config.timing globalData.globalTiming (Duration 0)

        rawDuration =
            durationFn distance_ resolvedTiming

        resolvedSpring =
            case config.spring of
                Just s ->
                    Just s

                Nothing ->
                    globalData.globalSpring

        duration_ =
            case resolvedSpring of
                Just s ->
                    SpringSolver.settleTimeMs
                        { spring = SpringInt.unwrap s
                        , from = 0
                        , to = 1
                        }

                Nothing ->
                    rawDuration

        speed_ =
            speedFn distance_ duration_ resolvedTiming
    in
    wrapper
        { start = config.start
        , end = config.end
        , duration = round duration_
        , speed = speed_
        , distance = distance_
        , timing = resolvedTiming
        , easing = resolveEasingWithDefault config.easing globalData.globalEasing EaseInOut
        , spring = resolvedSpring
        , cssUnit = InternalUnit.resolveCssUnitAxes config.cssUnit globalCssUnit defaultCssUnit
        , delay = resolveDelayWithDefault config.delay globalData.globalDelay 0
        , mode = config.mode
        }


{-| Generic resolver for optional values with local, global, and default fallback.
-}
resolveMaybeWithDefault : Maybe a -> Maybe a -> a -> a
resolveMaybeWithDefault local global default =
    case ( local, global ) of
        ( Just value, _ ) ->
            value

        ( Nothing, Just value ) ->
            value

        ( Nothing, Nothing ) ->
            default


resolveTimingWithDefault : Maybe TimeSpec -> Maybe TimeSpec -> TimeSpec -> TimeSpec
resolveTimingWithDefault =
    resolveMaybeWithDefault


resolveEasingWithDefault : Maybe Easing -> Maybe Easing -> Easing -> Easing
resolveEasingWithDefault =
    resolveMaybeWithDefault


resolveDelayWithDefault : Maybe Int -> Maybe Int -> Int -> Int
resolveDelayWithDefault =
    resolveMaybeWithDefault



-- ============================================================
-- TRANSFORM ORDERING
-- ============================================================


type alias TransformParts =
    { translate : String
    , rotate : String
    , skew : String
    , scale : String
    }


extractTransformsFromProcessed : List ProcessedPropertyConfig -> TransformParts
extractTransformsFromProcessed properties =
    List.foldl collectProcessedTransform emptyTransformParts properties


extractTransformsFromProperty : List PropertyConfig -> TransformParts
extractTransformsFromProperty properties =
    List.foldl collectPropertyTransform emptyTransformParts properties


emptyTransformParts : TransformParts
emptyTransformParts =
    { translate = ""
    , rotate = ""
    , skew = ""
    , scale = ""
    }


collectProcessedTransform : ProcessedPropertyConfig -> TransformParts -> TransformParts
collectProcessedTransform property acc =
    case property of
        ProcessedTranslateConfig config ->
            { acc | translate = Translate.toCssString config.cssUnit config.end }

        ProcessedRotateConfig config ->
            { acc | rotate = Rotate.toCssString config.end }

        ProcessedSkewConfig config ->
            { acc | skew = Skew.toCssString config.end }

        ProcessedScaleConfig config ->
            { acc | scale = Scale.toCssString config.end }

        _ ->
            acc


collectPropertyTransform : PropertyConfig -> TransformParts -> TransformParts
collectPropertyTransform property acc =
    case property of
        TranslateConfig config ->
            { acc | translate = Translate.toCssString (InternalUnit.resolveCssUnitAxes config.cssUnit InternalUnit.emptyCssUnitAxes InternalUnit.default) config.end }

        RotateConfig config ->
            { acc | rotate = Rotate.toCssString config.end }

        SkewConfig config ->
            { acc | skew = Skew.toCssString config.end }

        ScaleConfig config ->
            { acc | scale = Scale.toCssString config.end }

        _ ->
            acc



-- ============================================================
-- ANIMATION HISTORY
-- ============================================================


{-| Add a new animation to the element's history, tagged `AnimateKind`.
This is the normal `animate` path - the entry becomes the rest position
that subsequent `reset` calls return to.
-}
addAnimationToHistory : ProcessedAnimationData -> AnimBuilder eng -> AnimBuilder eng
addAnimationToHistory =
    addToHistoryWithKind AnimateKind


{-| Add a retarget entry to the element's history, tagged `RetargetKind`.
Subsequent `reset` calls walk past these entries to find the most recent
`AnimateKind` entry, so the box returns to the originally-animated rest
position rather than the synthesised mid-flight start.
-}
addRetargetToHistory : ProcessedAnimationData -> AnimBuilder eng -> AnimBuilder eng
addRetargetToHistory =
    addToHistoryWithKind RetargetKind


addToHistoryWithKind : HistoryKind -> ProcessedAnimationData -> AnimBuilder eng -> AnimBuilder eng
addToHistoryWithKind kind processedData (AnimBuilder data) =
    AnimGroups.foldl
        (\animGroupName groupConfig (AnimBuilder accData) ->
            let
                state =
                    accData.state

                newEntry =
                    { kind = kind, config = groupConfig }

                existingHistory =
                    AnimGroups.get animGroupName state.animationHistories

                updatedHistory =
                    case existingHistory of
                        Nothing ->
                            { current = newEntry
                            , history = []
                            }

                        Just existing ->
                            { current = newEntry
                            , history = existing.current :: existing.history
                            }
            in
            AnimBuilder
                { accData
                    | state =
                        { state
                            | animationHistories =
                                AnimGroups.insert
                                    animGroupName
                                    updatedHistory
                                    state.animationHistories
                        }
                }
        )
        (AnimBuilder data)
        processedData.groups



-- ============================================================
-- SCROLL-DRIVEN ANIMATION
-- ============================================================


{-| Set the scroll source element ID, transitioning the builder into scroll mode.
The `newMode` type parameter is left open so callers can specialise it to a phantom
mode record (e.g. `{ isScrollBased : () }`).
-}
setScrollSource : String -> AnimBuilder eng -> AnimBuilder newMode
setScrollSource source (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | source = Just source } }


{-| Set the scroll/view axis ("block" or "inline") without changing the phantom mode.
-}
setScrollAxis : String -> AnimBuilder eng -> AnimBuilder eng
setScrollAxis axisStr (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | axis = Just axisStr } }


{-| Set the target selector key for the current animation group.
For timeline engines this decouples animation group names from DOM lookup ids.
-}
setAnimTarget : String -> AnimBuilder eng -> AnimBuilder eng
setAnimTarget targetId (AnimBuilder data) =
    case data.animation.currentAnimGroup of
        Nothing ->
            AnimBuilder data

        Just animGroupName ->
            let
                sd =
                    data.scrollDriven
            in
            AnimBuilder
                { data
                    | scrollDriven =
                        { sd
                            | targets =
                                AnimGroups.insert animGroupName targetId sd.targets
                        }
                }


{-| Transition the builder into view mode without storing any data.
The `newMode` type parameter is left open so callers can specialise it to a phantom
mode record (e.g. `{ isViewBased : () }`).
-}
transitionMode : AnimBuilder eng -> AnimBuilder newMode
transitionMode (AnimBuilder data) =
    AnimBuilder data


{-| Set the ViewTimeline rangeStart value without changing the phantom mode.
-}
setViewRangeStart : String -> AnimBuilder eng -> AnimBuilder eng
setViewRangeStart range (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | viewRangeStart = Just range } }


{-| Set the ViewTimeline rangeEnd value without changing the phantom mode.
-}
setViewRangeEnd : String -> AnimBuilder eng -> AnimBuilder eng
setViewRangeEnd range (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | viewRangeEnd = Just range } }


{-| Get the scroll source element ID (for ScrollTimeline).
-}
getScrollSource : AnimBuilder eng -> Maybe String
getScrollSource (AnimBuilder data) =
    data.scrollDriven.source


{-| Get the timeline target id for an animation group, if explicitly set.
-}
getAnimTarget : AnimGroupName -> AnimBuilder eng -> Maybe String
getAnimTarget animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.scrollDriven.targets


{-| Get the scroll/view axis string ("block" or "inline").
-}
getScrollAxis : AnimBuilder eng -> Maybe String
getScrollAxis (AnimBuilder data) =
    data.scrollDriven.axis


{-| Get the ViewTimeline rangeStart value.
-}
getViewRangeStart : AnimBuilder eng -> Maybe String
getViewRangeStart (AnimBuilder data) =
    data.scrollDriven.viewRangeStart


{-| Get the ViewTimeline rangeEnd value.
-}
getViewRangeEnd : AnimBuilder eng -> Maybe String
getViewRangeEnd (AnimBuilder data) =
    data.scrollDriven.viewRangeEnd


{-| Get the per-frame progress-event opt-in flag for scroll/view timelines.
-}
getScrollEmitProgress : AnimBuilder eng -> Bool
getScrollEmitProgress (AnimBuilder data) =
    data.scrollDriven.emitProgress


{-| Enable or disable per-frame `Progress` events for scroll/view-driven
animations. Off by default so the port stays quiet unless callers actively
opt in.
-}
setScrollEmitProgress : Bool -> AnimBuilder { eng | withProgressEvents : () } -> AnimBuilder { eng | withProgressEvents : () }
setScrollEmitProgress enabled (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | emitProgress = enabled } }


{-| Get the per-frame `Progress` event opt-in flag.
-}
getEmitProgress : AnimBuilder eng -> Bool
getEmitProgress (AnimBuilder data) =
    data.emitProgress


{-| Enable or disable per-frame `Progress` events. Off by default — the JS
port still delivers `propertyUpdate` messages so engine state stays in sync,
but `update` returns `Nothing` instead of `Just (Progress ...)` when disabled.
-}
setEmitProgress : Bool -> AnimBuilder { eng | withProgressEvents : () } -> AnimBuilder { eng | withProgressEvents : () }
setEmitProgress enabled (AnimBuilder data) =
    AnimBuilder { data | emitProgress = enabled }
