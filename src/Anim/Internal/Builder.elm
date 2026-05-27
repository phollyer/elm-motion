module Anim.Internal.Builder exposing
    ( AnimBuilder
    , AnimGroupConfig
    , AnimationConfig
    , AnimationDirection(..)
    , DefaultsConfig
    , DiscreteEntryProperty
    , DiscreteExitProperty
    , ForDocumentTimeline
    , ForKeyframeEngine
    , ForScrollTimeline
    , ForSubEngine
    , ForTransitionEngine
    , ForViewTimeline
    , ForWAAPIEngine
    , FreezeProperty(..)
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
    , getAllFrozenAxes
    , getEasing
    , getEasingWithDefault
    , getFrozenAxes
    , getIterations
    , getPerspectiveOriginInitCssUnit
    , getRuntimeBaseline
    , getScrollAxis
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
    , injectRunningProperties
    , isPropertyRunning
    , iterations
    , loopForever
    , mergeBaselines
    , normalizeTransformOrder
    , process
    , processProperties
    , processedPropertyType
    , processedTimings
    , setAnimTarget
    , setClamp
    , setPerspectiveOriginInitCssUnit
    , setPerspectiveOriginInitCssUnitX
    , setPerspectiveOriginInitCssUnitY
    , setScrollAxis
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


type AnimBuilder mode
    = AnimBuilder BuilderData



-- Available `mode`s


type alias ForScrollTimeline =
    { forScroll : () }


type alias ForViewTimeline =
    { forView : () }


type alias ForDocumentTimeline engine =
    { forDocument : ()
    , forEngine : engine
    }


type alias ForKeyframeEngine =
    { forKeyframe : () }


type alias ForSubEngine =
    { forSub : () }


type alias ForTransitionEngine =
    { forTransition : () }


type alias ForWAAPIEngine =
    { forWAAPI : () }



-- Configuration records


type alias BuilderData =
    { defaults : DefaultsConfig
    , animation : AnimGroupData
    , playback : PlaybackConfig
    , state : PersistentState
    , scrollDriven : ScrollDrivenConfig
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
    , runningProperties : Dict AnimGroupName (Set String)
    , propertyClamps : Dict ( AnimGroupName, String, String ) ( Float, Float )
    }


{-| Animation history for a single element.

  - current: The most recent animation (if any)
  - history: Previous animations (most recent first)

-}
type alias AnimationHistory =
    { current : ProcessedAnimGroupConfig
    , history : List ProcessedAnimGroupConfig -- Most recent first (head = previous)
    }



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
    , targets : AnimGroups String
    }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : List (AnimBuilder mode -> AnimBuilder mode) -> AnimBuilder mode
init =
    List.foldl (\f b -> f b) <|
        AnimBuilder
            { defaults = initDefaults
            , animation = initAnimation
            , playback = initPlayback
            , state = initState
            , scrollDriven = initScrollDrivenConfig
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
    , runningProperties = Dict.empty
    , propertyClamps = Dict.empty
    }


initScrollDrivenConfig : ScrollDrivenConfig
initScrollDrivenConfig =
    { source = Nothing
    , axis = Nothing
    , viewRangeStart = Nothing
    , viewRangeEnd = Nothing
    , targets = AnimGroups.init
    }



-- ============================================================
-- DEFAULTS
-- ============================================================


duration : Int -> AnimBuilder mode -> AnimBuilder mode
duration ms (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Duration ms) } }


speed : Float -> AnimBuilder mode -> AnimBuilder mode
speed value (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalTiming = Just (Speed value) } }


easing : Easing -> AnimBuilder mode -> AnimBuilder mode
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


spring : Spring -> AnimBuilder mode -> AnimBuilder mode
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


delay : Int -> AnimBuilder mode -> AnimBuilder mode
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


cssUnit : Unit -> AnimBuilder mode -> AnimBuilder mode
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


cssUnitX : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitX unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalCssUnit = InternalUnit.setCssUnitX unit defs.globalCssUnit } }


cssUnitY : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitY unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalCssUnit = InternalUnit.setCssUnitY unit defs.globalCssUnit } }


cssUnitZ : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitZ unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalCssUnit = InternalUnit.setCssUnitZ unit defs.globalCssUnit } }


cssUnitWidth : Unit -> AnimBuilder mode -> AnimBuilder mode
cssUnitWidth unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | globalSizeCssUnit = InternalUnit.setCssUnitX unit defs.globalSizeCssUnit } }


cssUnitHeight : Unit -> AnimBuilder mode -> AnimBuilder mode
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


setTranslateInitCssUnit : Unit -> AnimBuilder mode -> AnimBuilder mode
setTranslateInitCssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setAllCssUnitAxes unit defs.translateInitCssUnit } }


setTranslateInitCssUnitX : Unit -> AnimBuilder mode -> AnimBuilder mode
setTranslateInitCssUnitX unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setCssUnitX unit defs.translateInitCssUnit } }


setTranslateInitCssUnitY : Unit -> AnimBuilder mode -> AnimBuilder mode
setTranslateInitCssUnitY unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setCssUnitY unit defs.translateInitCssUnit } }


setTranslateInitCssUnitZ : Unit -> AnimBuilder mode -> AnimBuilder mode
setTranslateInitCssUnitZ unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | translateInitCssUnit = InternalUnit.setCssUnitZ unit defs.translateInitCssUnit } }


getTranslateInitCssUnit : AnimBuilder mode -> InternalUnit.CssUnitAxes
getTranslateInitCssUnit (AnimBuilder data) =
    data.defaults.translateInitCssUnit


setSizeInitCssUnit : Unit -> AnimBuilder mode -> AnimBuilder mode
setSizeInitCssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | sizeInitCssUnit = InternalUnit.setAllCssUnitAxes unit defs.sizeInitCssUnit } }


setSizeInitCssUnitWidth : Unit -> AnimBuilder mode -> AnimBuilder mode
setSizeInitCssUnitWidth unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | sizeInitCssUnit = InternalUnit.setCssUnitX unit defs.sizeInitCssUnit } }


setSizeInitCssUnitHeight : Unit -> AnimBuilder mode -> AnimBuilder mode
setSizeInitCssUnitHeight unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | sizeInitCssUnit = InternalUnit.setCssUnitY unit defs.sizeInitCssUnit } }


getSizeInitCssUnit : AnimBuilder mode -> InternalUnit.CssUnitAxes
getSizeInitCssUnit (AnimBuilder data) =
    data.defaults.sizeInitCssUnit


setPerspectiveOriginInitCssUnit : Unit -> AnimBuilder mode -> AnimBuilder mode
setPerspectiveOriginInitCssUnit unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | perspectiveOriginInitCssUnit = InternalUnit.setAllCssUnitAxes unit defs.perspectiveOriginInitCssUnit } }


setPerspectiveOriginInitCssUnitX : Unit -> AnimBuilder mode -> AnimBuilder mode
setPerspectiveOriginInitCssUnitX unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | perspectiveOriginInitCssUnit = InternalUnit.setCssUnitX unit defs.perspectiveOriginInitCssUnit } }


setPerspectiveOriginInitCssUnitY : Unit -> AnimBuilder mode -> AnimBuilder mode
setPerspectiveOriginInitCssUnitY unit (AnimBuilder data) =
    let
        defs =
            data.defaults
    in
    AnimBuilder
        { data | defaults = { defs | perspectiveOriginInitCssUnit = InternalUnit.setCssUnitY unit defs.perspectiveOriginInitCssUnit } }


getPerspectiveOriginInitCssUnit : AnimBuilder mode -> InternalUnit.CssUnitAxes
getPerspectiveOriginInitCssUnit (AnimBuilder data) =
    data.defaults.perspectiveOriginInitCssUnit


transformOrder : List TransformProperty -> AnimBuilder mode -> AnimBuilder mode
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


for : String -> AnimBuilder mode -> AnimBuilder mode
for elementId (AnimBuilder data) =
    let
        anim =
            data.animation
    in
    AnimBuilder
        { data | animation = { anim | currentAnimGroup = Just elementId } }


{-| Get the current (most recent) animation for a group.
-}
getCurrentAnimationConfig : AnimGroupName -> AnimBuilder mode -> Maybe ProcessedAnimGroupConfig
getCurrentAnimationConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.state.animationHistories
        |> Maybe.map .current


getAnimationConfigs : AnimGroupName -> AnimBuilder mode -> List ProcessedAnimGroupConfig
getAnimationConfigs animGroupName (AnimBuilder data) =
    case AnimGroups.get animGroupName data.state.animationHistories of
        Nothing ->
            []

        Just h ->
            h.current :: h.history



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> AnimBuilder mode -> AnimBuilder mode
iterations count (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | iterations = Times count } }


loopForever : AnimBuilder mode -> AnimBuilder mode
loopForever (AnimBuilder data) =
    let
        pb =
            data.playback
    in
    AnimBuilder { data | playback = { pb | iterations = Infinite } }


alternate : AnimBuilder mode -> AnimBuilder mode
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


discreteTransitionsEnabled : AnimBuilder mode -> Bool
discreteTransitionsEnabled (AnimBuilder data) =
    data.playback.discreteTransitions


{-| Add a discrete CSS property for entry animations.

The value is applied when the animation starts, ensuring the element is
immediately in the target state.

    discreteEntry "display" "block"

-}
discreteEntry : String -> String -> AnimBuilder mode -> AnimBuilder mode
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
discreteExit : String -> String -> String -> AnimBuilder mode -> AnimBuilder mode
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


getDiscreteEntryProperties : AnimBuilder mode -> Dict String String
getDiscreteEntryProperties (AnimBuilder data) =
    data.playback.discreteEntryProperties


getDiscreteExitProperties : AnimBuilder mode -> Dict String DiscreteExitProperty
getDiscreteExitProperties (AnimBuilder data) =
    data.playback.discreteExitProperties


getIterations : AnimBuilder mode -> Iterations
getIterations (AnimBuilder data) =
    data.playback.iterations


getAnimationDirection : AnimBuilder mode -> AnimationDirection
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


freezeAxes : List String -> List FreezeProperty -> AnimBuilder mode -> AnimBuilder mode
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


unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder mode -> AnimBuilder mode
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
getFrozenAxes : String -> AnimBuilder mode -> List String
getFrozenAxes propName (AnimBuilder data) =
    Dict.get propName data.animation.frozenAxes |> Maybe.withDefault []


{-| Get the full frozen-axes dictionary keyed by property name. Used by
engines that need to forward freeze information to a downstream consumer
(e.g. the WAAPI JS layer, which overrides frozen axes with live-rendered
values to avoid snap-back from stale Elm snapshots).
-}
getAllFrozenAxes : AnimBuilder mode -> Dict String (List String)
getAllFrozenAxes (AnimBuilder data) =
    data.animation.frozenAxes


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


getAnimGroups : AnimBuilder mode -> AnimGroups AnimGroupConfig
getAnimGroups (AnimBuilder data) =
    data.animation.animGroups


{-| Name of the animGroup the next pipeline step will configure, or `Nothing` if not set.
-}
getCurrentAnimGroupName : AnimBuilder mode -> Maybe AnimGroupName
getCurrentAnimGroupName (AnimBuilder data) =
    data.animation.currentAnimGroup


getCurrentAnimGroupConfig : AnimBuilder mode -> AnimGroupConfig
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


getAnimGroupConfig : AnimGroupName -> AnimBuilder mode -> Maybe AnimGroupConfig
getAnimGroupConfig animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.animation.animGroups


{-| Get baseline states for a group.
Baselines reflect the last known property values - either animation targets
or runtime snapshots from active animations.
-}
getBaseline : String -> AnimBuilder mode -> Maybe PropertyBaselines
getBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.baselines


getRuntimeBaseline : String -> AnimBuilder mode -> Maybe PropertyBaselines
getRuntimeBaseline key (AnimBuilder data) =
    AnimGroups.get key data.state.runtimeBaselines


getTransformOrder : AnimGroupName -> AnimBuilder mode -> Maybe (List TransformProperty)
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


getTimeSpec : AnimBuilder mode -> Maybe TimeSpec
getTimeSpec (AnimBuilder data) =
    data.defaults.globalTiming


getTimeSpecWithDefault : AnimBuilder mode -> TimeSpec
getTimeSpecWithDefault (AnimBuilder data) =
    data.defaults.globalTiming |> Maybe.withDefault (Duration 0)


getEasing : AnimBuilder mode -> Maybe Easing
getEasing (AnimBuilder data) =
    data.defaults.globalEasing


getSpring : AnimBuilder mode -> Maybe Spring
getSpring (AnimBuilder data) =
    data.defaults.globalSpring


getEasingWithDefault : AnimBuilder mode -> Easing
getEasingWithDefault (AnimBuilder data) =
    data.defaults.globalEasing |> Maybe.withDefault QuintOut


getDelay : AnimBuilder mode -> Maybe Int
getDelay (AnimBuilder data) =
    data.defaults.globalDelay


getDelayWithDefault : AnimBuilder mode -> Int
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
injectCurrentStates : AnimGroups { a | propertySnapshot : PropertyBaselines } -> AnimBuilder mode -> AnimBuilder mode
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


{-| Inject the set of currently-running property keys per animGroup.

Engines call this from their `retarget` function to tell per-property
`continueFor` resolvers which property animations are still in flight.
The set is cleared by `clearAnimData` after the pipeline runs, so it
lives only for the duration of one pipeline invocation.

-}
injectRunningProperties : Dict AnimGroupName (Set String) -> AnimBuilder mode -> AnimBuilder mode
injectRunningProperties running (AnimBuilder data) =
    let
        state =
            data.state
    in
    AnimBuilder
        { data
            | state = { state | runningProperties = running }
        }


{-| True when the named property type is currently running on the given
animGroup, as reported by the most recent `injectRunningProperties` call.
-}
isPropertyRunning : AnimGroupName -> String -> AnimBuilder mode -> Bool
isPropertyRunning animGroupName propertyKey (AnimBuilder data) =
    Dict.get animGroupName data.state.runningProperties
        |> Maybe.map (Set.member propertyKey)
        |> Maybe.withDefault False


{-| Get a clamp range for a (animGroup, propertyKey, axis) triple, if any.
-}
getClamp : AnimGroupName -> String -> String -> AnimBuilder mode -> Maybe ( Float, Float )
getClamp animGroupName propertyKey axis (AnimBuilder data) =
    Dict.get ( animGroupName, propertyKey, axis ) data.state.propertyClamps


{-| Set a clamp range. Bounds are normalised so the smaller value becomes
the lower bound regardless of argument order.
-}
setClamp : AnimGroupName -> String -> String -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
clearClamp : AnimGroupName -> String -> String -> AnimBuilder mode -> AnimBuilder mode
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


clearAnimData : AnimBuilder mode -> AnimBuilder mode
clearAnimData (AnimBuilder data) =
    let
        pb =
            data.playback

        st =
            data.state
    in
    AnimBuilder
        { data
            | animation = initAnimation
            , playback =
                { pb
                    | discreteEntryProperties = Dict.empty
                    , discreteExitProperties = Dict.empty
                }
            , state = { st | runningProperties = Dict.empty }
        }


mergeBaselines : AnimBuilder mode -> AnimBuilder mode
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


{-| Amend the stored baselines for a single animGroup using a transform
function.

Used by engines that need to update baselines outside the normal `animate`
pipeline — for example, after a resize that shifts the in-flight
animation's end target. Subsequent builders look up the new end via
`getBaseline` (so that `Translate.for >> Translate.toY` and friends inherit
the resized X/Z values), and that lookup must reflect the post-resize
target rather than the pre-resize one captured by the prior `animate`.

-}
updateBaselines : String -> (PropertyBaselines -> PropertyBaselines) -> AnimBuilder mode -> AnimBuilder mode
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

        SizeConfig cfg ->
            baselines
                |> PropertyBaselines.setSize cfg.end
                |> PropertyBaselines.setSizeUnits
                    (InternalUnit.resolveCssUnitAxes cfg.cssUnit defaults.globalSizeCssUnit InternalUnit.default)

        CustomPropertyConfig cssName unit cfg ->
            PropertyBaselines.setCustomProperty cssName cfg.end unit baselines

        CustomColorPropertyConfig cssName cfg ->
            PropertyBaselines.setCustomColorProperty cssName cfg.end baselines


updateCurrentConfig : AnimGroupConfig -> AnimBuilder mode -> AnimBuilder mode
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
but for the post-process variant. The returned string matches the keys
used by `injectRunningProperties` / `isPropertyRunning`.
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


process : AnimBuilder mode -> ProcessedAnimationData
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


{-| Add a new animation to the element's history.
This function creates a new history entry and updates the element's animation timeline.
The previous current animation (if any) is moved to the history list.
-}
addAnimationToHistory : ProcessedAnimationData -> AnimBuilder mode -> AnimBuilder mode
addAnimationToHistory processedData (AnimBuilder data) =
    AnimGroups.foldl
        (\animGroupName groupConfig (AnimBuilder accData) ->
            let
                state =
                    accData.state

                -- Get existing history for this element
                existingHistory =
                    AnimGroups.get animGroupName state.animationHistories

                -- Update history: move current to history list, set new as current
                updatedHistory =
                    case existingHistory of
                        Nothing ->
                            { current = groupConfig
                            , history = []
                            }

                        Just existing ->
                            { current = groupConfig
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
setScrollSource : String -> AnimBuilder mode -> AnimBuilder newMode
setScrollSource source (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | source = Just source } }


{-| Set the scroll/view axis ("block" or "inline") without changing the phantom mode.
-}
setScrollAxis : String -> AnimBuilder mode -> AnimBuilder mode
setScrollAxis axisStr (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | axis = Just axisStr } }


{-| Set the target selector key for the current animation group.
For timeline engines this decouples animation group names from DOM lookup ids.
-}
setAnimTarget : String -> AnimBuilder mode -> AnimBuilder mode
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
transitionMode : AnimBuilder mode -> AnimBuilder newMode
transitionMode (AnimBuilder data) =
    AnimBuilder data


{-| Set the ViewTimeline rangeStart value without changing the phantom mode.
-}
setViewRangeStart : String -> AnimBuilder mode -> AnimBuilder mode
setViewRangeStart range (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | viewRangeStart = Just range } }


{-| Set the ViewTimeline rangeEnd value without changing the phantom mode.
-}
setViewRangeEnd : String -> AnimBuilder mode -> AnimBuilder mode
setViewRangeEnd range (AnimBuilder data) =
    let
        sd =
            data.scrollDriven
    in
    AnimBuilder { data | scrollDriven = { sd | viewRangeEnd = Just range } }


{-| Get the scroll source element ID (for ScrollTimeline).
-}
getScrollSource : AnimBuilder mode -> Maybe String
getScrollSource (AnimBuilder data) =
    data.scrollDriven.source


{-| Get the timeline target id for an animation group, if explicitly set.
-}
getAnimTarget : AnimGroupName -> AnimBuilder mode -> Maybe String
getAnimTarget animGroupName (AnimBuilder data) =
    AnimGroups.get animGroupName data.scrollDriven.targets


{-| Get the scroll/view axis string ("block" or "inline").
-}
getScrollAxis : AnimBuilder mode -> Maybe String
getScrollAxis (AnimBuilder data) =
    data.scrollDriven.axis


{-| Get the ViewTimeline rangeStart value.
-}
getViewRangeStart : AnimBuilder mode -> Maybe String
getViewRangeStart (AnimBuilder data) =
    data.scrollDriven.viewRangeStart


{-| Get the ViewTimeline rangeEnd value.
-}
getViewRangeEnd : AnimBuilder mode -> Maybe String
getViewRangeEnd (AnimBuilder data) =
    data.scrollDriven.viewRangeEnd
