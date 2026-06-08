module Anim.Internal.Engine.WAAPI.Encoder exposing
    ( encode
    , encodeCommandWithProperties
    , encodeProcessedData
    , encodeResize
    , encodeRestart
    , encodeRetarget
    , encodeScroll
    , encodeSetProgressThrottle
    , encodeSnap
    , encodeView
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..), DiscreteExitProperty)
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, PropertyState)
import Anim.Internal.Engine.WAAPI.Generator as Generator
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.Unit as InternalUnit
import Dict
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))
import Motion.Internal.Spring as SpringInt
import Motion.Spring exposing (Spring)
import Set exposing (Set)
import Shared.Easing as Easing
import Shared.Easing.Keyframes as EasingKeyframes
import Shared.Spring as SpringSolver



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimGroupName =
    String



-- ============================================================
-- ENCODE
-- ============================================================


encode : AnimGroups AnimGroup -> Builder.ProcessedAnimationData -> Encode.Value
encode animGroups processed =
    encodeAnimateLike "animate" animGroups Dict.empty (filterGroupsByMode Builder.Animate processed)


{-| Encode a snap-to-target retarget command. The JSON payload is the
same shape as `encode` (keyframes, timing, frozen axes) so the JS
handler can reuse the keyframe machinery, but `type` is `"retarget"`.
The JS side cancels any in-flight WAAPI animation on the named
properties and writes the final keyframe's value as inline style; timing
fields are ignored by the JS handler.

The `touchedAxes` dict is keyed by `(animGroupName, propertyName)`
and contains the subset of axes the user explicitly retargeted via
the builder pipeline (e.g. `Translate.toY 0` records `{"y"}`). The
JS handler snaps touched axes to the new target and lets untouched
axes of bundled transform properties continue their in-flight
animation toward their existing end target. If no entry exists for
a property, JS treats every axis as touched (full snap, current
behaviour for callers that retarget every axis at once).

-}
encodeRetarget :
    AnimGroups AnimGroup
    -> Dict.Dict ( String, String ) (Set String)
    -> Builder.ProcessedAnimationData
    -> Encode.Value
encodeRetarget =
    encodeAnimateLike "retarget"


{-| Encode a snap-mode batch command. Same payload shape as `encode`
and `encodeRetarget`; the JS handler cancels any in-flight WAAPI
animation on each named property and writes the property's `endValue`
as inline style. Timing fields are present in the payload but ignored
by JS. Emitted in addition to (and separately from) the regular
`animate` command, with the per-element property list pre-filtered to
contain only `mode = Snap` properties.
-}
encodeSnap : AnimGroups AnimGroup -> Builder.ProcessedAnimationData -> Encode.Value
encodeSnap animGroups processed =
    encodeAnimateLike "snap" animGroups Dict.empty (filterGroupsByMode Builder.Snap processed)


{-| Keep only properties whose `mode` matches `targetMode`, and drop
groups left with no properties. Used to split an animate command into
the regular `animate` payload (Animate-mode) and the parallel `snap`
payload (Snap-mode).
-}
filterGroupsByMode : Builder.AnimationMode -> Builder.ProcessedAnimationData -> Builder.ProcessedAnimationData
filterGroupsByMode targetMode processed =
    let
        filteredGroups =
            processed.groups
                |> AnimGroups.toList
                |> List.filterMap
                    (\( name, config ) ->
                        let
                            kept =
                                List.filter
                                    (\p -> Builder.processedPropertyMode p == targetMode)
                                    config.properties
                        in
                        if List.isEmpty kept then
                            Nothing

                        else
                            Just ( name, { config | properties = kept } )
                    )
                |> AnimGroups.fromList
    in
    { processed | groups = filteredGroups }


encodeAnimateLike :
    String
    -> AnimGroups AnimGroup
    -> Dict.Dict ( String, String ) (Set String)
    -> Builder.ProcessedAnimationData
    -> Encode.Value
encodeAnimateLike typeTag animGroups touchedAxes processed =
    let
        elementsWithVersions =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            animGroup =
                                AnimGroups.get animGroupName animGroups

                            propertyStatesGroup =
                                animGroup
                                    |> Maybe.map AnimGroup.getPropertyStates
                                    |> Maybe.withDefault AnimGroups.init

                            animTransformOrder =
                                animGroup
                                    |> Maybe.map AnimGroup.getTransformOrder
                                    |> Maybe.withDefault TransformProperty.default

                            snapshot =
                                animGroup
                                    |> Maybe.map AnimGroup.getPropertySnapshot
                                    |> Maybe.withDefault PropertyBaselines.empty

                            playback =
                                Builder.resolvePlayback
                                    processed.iterations
                                    processed.animationDirection
                                    config.playback
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            animGroupName
                            (Just propertyStatesGroup)
                            (Just animTransformOrder)
                            (encodeTransformBaseline snapshot)
                            Nothing
                            Nothing
                            Nothing
                            config.frozenAxes
                            config.discreteEntryProperties
                            config.discreteExitProperties
                            (touchedAxesForGroup animGroupName touchedAxes)
                            playback.iterations
                            playback.animationDirection
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string typeTag )
        , ( "elements", Encode.object elementsWithVersions )
        , ( "iterations", encodeIterations processed.iterations )
        , ( "direction", encodeAnimationDirection processed.animationDirection )
        ]


{-| Extract per-property touched-axis sets for a single animGroup
from the global `(animGroupName, propertyName) -> Set axis` dict.
-}
touchedAxesForGroup : AnimGroupName -> Dict.Dict ( String, String ) (Set String) -> Dict.Dict String (Set String)
touchedAxesForGroup animGroupName touchedAxes =
    Dict.foldl
        (\( group, propName ) axisSet acc ->
            if group == animGroupName then
                Dict.insert propName axisSet acc

            else
                acc
        )
        Dict.empty
        touchedAxes


encodeRestart : Builder.Iterations -> Builder.AnimationDirection -> AnimGroups AnimGroup -> AnimGroups Builder.ProcessedAnimGroupConfig -> Encode.Value
encodeRestart iterationsConfig directionConfig animGroup configGroup =
    let
        elementsWithVersions =
            configGroup
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            elementAnim =
                                AnimGroups.get animGroupName animGroup

                            elementProps =
                                elementAnim
                                    |> Maybe.map AnimGroup.getPropertyStates
                                    |> Maybe.withDefault AnimGroups.init

                            elemTransformOrder =
                                elementAnim
                                    |> Maybe.map AnimGroup.getTransformOrder
                                    |> Maybe.withDefault TransformProperty.default

                            snapshot =
                                elementAnim
                                    |> Maybe.map AnimGroup.getPropertySnapshot
                                    |> Maybe.withDefault PropertyBaselines.empty

                            playback =
                                Builder.resolvePlayback
                                    iterationsConfig
                                    directionConfig
                                    config.playback
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            animGroupName
                            (Just elementProps)
                            (Just elemTransformOrder)
                            (encodeTransformBaseline snapshot)
                            Nothing
                            Nothing
                            Nothing
                            config.frozenAxes
                            config.discreteEntryProperties
                            config.discreteExitProperties
                            Dict.empty
                            playback.iterations
                            playback.animationDirection
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        , ( "iterations", encodeIterations iterationsConfig )
        , ( "direction", encodeAnimationDirection directionConfig )
        , ( "isRestart", Encode.bool True )
        ]


encodeProcessedData : Builder.ProcessedAnimationData -> Encode.Value
encodeProcessedData data =
    let
        processedProperties =
            data.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            playback =
                                Builder.resolvePlayback
                                    data.iterations
                                    data.animationDirection
                                    config.playback
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            animGroupName
                            Nothing
                            Nothing
                            Nothing
                            Nothing
                            Nothing
                            Nothing
                            config.frozenAxes
                            config.discreteEntryProperties
                            config.discreteExitProperties
                            Dict.empty
                            playback.iterations
                            playback.animationDirection
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object processedProperties )
        , ( "iterations", encodeIterations data.iterations )
        , ( "direction", encodeAnimationDirection data.animationDirection )
        ]


{-| Encode iterations config as a JSON object with `type` and `count` fields.
-}
encodeIterations : Builder.Iterations -> Encode.Value
encodeIterations iterations_ =
    case iterations_ of
        Builder.Once ->
            Encode.object
                [ ( "type", Encode.string "once" )
                , ( "count", Encode.int 1 )
                ]

        Builder.Times n ->
            Encode.object
                [ ( "type", Encode.string "times" )
                , ( "count", Encode.int n )
                ]

        Builder.Infinite ->
            Encode.object
                [ ( "type", Encode.string "infinite" )
                , ( "count", Encode.int -1 )
                ]


{-| Encode animation direction as a Web Animations API direction string.
-}
encodeAnimationDirection : AnimationDirection -> Encode.Value
encodeAnimationDirection direction =
    case direction of
        Normal ->
            Encode.string "normal"

        Alternate ->
            Encode.string "alternate"


{-| Encode a command with an optional property filter (`Nothing` = all properties).
-}
encodeCommandWithProperties : String -> String -> Maybe (List String) -> Encode.Value
encodeCommandWithProperties commandType animGroupName maybeProperties =
    let
        baseFields =
            [ ( "type", Encode.string commandType )
            , ( "elementId", Encode.string animGroupName )
            ]

        propertyField =
            case maybeProperties of
                Just props ->
                    [ ( "properties", Encode.list Encode.string props ) ]

                Nothing ->
                    []
    in
    Encode.object (baseFields ++ propertyField)


{-| Encode a `setUpdateThrottle` command. Global JS-side setting that caps
the rate of per-frame `propertyUpdate` events sent back to Elm. Not tied to
any animGroup. Pass 0 to disable throttling.
-}
encodeSetProgressThrottle : Int -> Encode.Value
encodeSetProgressThrottle intervalMs =
    Encode.object
        [ ( "type", Encode.string "setUpdateThrottle" )
        , ( "intervalMs", Encode.int intervalMs )
        ]



-- ============================================================
-- RESIZE
-- ============================================================


{-| Encode a `resize` command, including the seek position (`currentTimeMs`)
computed on the Elm side.
-}
encodeResize :
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
    -> Encode.Value
encodeResize r =
    let
        baseFields =
            [ ( "type", Encode.string "resize" )
            , ( "elementId", Encode.string r.animGroupName )
            , ( "animGroup", Encode.string r.animGroupName )
            , ( "property", Encode.string r.property )
            , ( "startX", Encode.float r.start.x )
            , ( "startY", Encode.float r.start.y )
            , ( "startZ", Encode.float r.start.z )
            , ( "endX", Encode.float r.end.x )
            , ( "endY", Encode.float r.end.y )
            , ( "endZ", Encode.float r.end.z )
            , ( "currentX", Encode.float r.current.x )
            , ( "currentY", Encode.float r.current.y )
            , ( "currentZ", Encode.float r.current.z )
            , ( "duration", Encode.float r.durationMs )
            , ( "hasAnimationBaseline", Encode.bool r.hasAnimationBaseline )
            , ( "currentTimeMs"
              , case r.currentTimeMs of
                    Just t ->
                        Encode.float t

                    Nothing ->
                        Encode.null
              )
            ]

        unitField =
            case r.unit of
                Just unit ->
                    [ ( "unit", Encode.string unit ) ]

                Nothing ->
                    []
    in
    Encode.object (baseFields ++ unitField)



-- ============================================================
-- HELPERS
-- ============================================================


encodeProcessedAnimGroupConfig :
    AnimGroupName
    -> String
    -> Maybe (AnimGroups PropertyState)
    -> Maybe (List TransformProperty)
    -> Maybe Encode.Value
    -> Maybe String
    -> Maybe String
    -> Maybe Bool
    -> Dict.Dict String (List String)
    -> Dict.Dict String String
    -> Dict.Dict String Builder.DiscreteExitProperty
    -> Dict.Dict String (Set String)
    -> Builder.Iterations
    -> Builder.AnimationDirection
    -> List Builder.ProcessedPropertyConfig
    -> Encode.Value
encodeProcessedAnimGroupConfig animGroupName targetId propertyState transformOrder_ transformBaseline viewRangeStart viewRangeEnd emitProgress_ frozenAxes discreteEntryProperties discreteExitProperties touchedAxes iterations_ direction_ propertyConfigs =
    let
        baseFields =
            [ ( "properties", Encode.list (encodeProcessedPropertyConfig propertyState frozenAxes touchedAxes) propertyConfigs )
            , ( "animGroup", Encode.string animGroupName )
            , ( "target", Encode.string targetId )
            , ( "iterations", encodeIterations iterations_ )
            , ( "direction", encodeAnimationDirection direction_ )
            ]

        orderField =
            transformOrder_
                |> Maybe.map (\order -> [ ( "transformOrder", encodeTransformOrder order ) ])
                |> Maybe.withDefault []

        baselineField =
            transformBaseline
                |> Maybe.map (\baseline -> [ ( "transformBaseline", baseline ) ])
                |> Maybe.withDefault []

        viewRangeFields =
            [ viewRangeStart |> Maybe.map (\range -> ( "rangeStart", Encode.string range ))
            , viewRangeEnd |> Maybe.map (\range -> ( "rangeEnd", Encode.string range ))
            ]
                |> List.filterMap identity

        emitProgressField =
            emitProgress_
                |> Maybe.map (\enabled -> [ ( "emitProgress", Encode.bool enabled ) ])
                |> Maybe.withDefault []

        discreteEntryField =
            encodeDiscreteEntryFields discreteEntryProperties

        discreteExitField =
            encodeDiscreteExitFields discreteExitProperties

        willChangeField =
            case Builder.willChangeComposite propertyConfigs of
                "" ->
                    []

                value ->
                    [ ( "willChange", Encode.string value ) ]
    in
    Encode.object (baseFields ++ orderField ++ baselineField ++ viewRangeFields ++ emitProgressField ++ discreteEntryField ++ discreteExitField ++ willChangeField)


{-| Encode the Elm-side transform snapshot baseline (init values plus any
latest committed runtime values) so JavaScript can seed its
`lastKnownTransforms` cache before computing keyframes for the first
animation that touches a transform sub-property on this animGroup.

Without this, when ownership of the inline `transform` style flips from
Elm to JS (because a transform sub-property begins animating), JS reads
an empty inline transform, defaults missing axes to identity, and silently
drops init-only values such as `Translate.initZ animGroup 200`.

Returns `Nothing` when the snapshot has none of translate / scale /
rotate / skew set, so the encoded payload stays compact
when the element only animates non-transform properties.

-}
encodeTransformBaseline : PropertyBaselines -> Maybe Encode.Value
encodeTransformBaseline snapshot =
    let
        translateField =
            PropertyBaselines.getTranslate snapshot
                |> Maybe.map
                    (\t ->
                        ( "translate"
                        , Encode.object
                            [ ( "x", Encode.float (Translate.getX t) )
                            , ( "y", Encode.float (Translate.getY t) )
                            , ( "z", Encode.float (Translate.getZ t) )
                            ]
                        )
                    )

        scaleField =
            PropertyBaselines.getScale snapshot
                |> Maybe.map
                    (\s ->
                        ( "scale"
                        , Encode.object
                            [ ( "x", Encode.float (Scale.getX s) )
                            , ( "y", Encode.float (Scale.getY s) )
                            , ( "z", Encode.float (Scale.getZ s) )
                            ]
                        )
                    )

        rotateField =
            PropertyBaselines.getRotate snapshot
                |> Maybe.map
                    (\r ->
                        ( "rotate"
                        , Encode.object
                            [ ( "x", Encode.float (Rotate.getX r) )
                            , ( "y", Encode.float (Rotate.getY r) )
                            , ( "z", Encode.float (Rotate.getZ r) )
                            ]
                        )
                    )

        skewField =
            PropertyBaselines.getSkew snapshot
                |> Maybe.map
                    (\sk ->
                        ( "skew"
                        , Encode.object
                            [ ( "x", Encode.float (Skew.getX sk) )
                            , ( "y", Encode.float (Skew.getY sk) )
                            ]
                        )
                    )

        fields =
            List.filterMap identity [ translateField, scaleField, rotateField, skewField ]
    in
    if List.isEmpty fields then
        Nothing

    else
        Just (Encode.object fields)


encodeDiscreteEntryFields : Dict.Dict String String -> List ( String, Encode.Value )
encodeDiscreteEntryFields dict =
    if Dict.isEmpty dict then
        []

    else
        [ ( "discreteEntry"
          , dict
                |> Dict.toList
                |> List.map (\( k, v ) -> ( k, Encode.string v ))
                |> Encode.object
          )
        ]


encodeDiscreteExitFields : Dict.Dict String DiscreteExitProperty -> List ( String, Encode.Value )
encodeDiscreteExitFields dict =
    if Dict.isEmpty dict then
        []

    else
        [ ( "discreteExit"
          , dict
                |> Dict.toList
                |> List.map
                    (\( k, { from, to } ) ->
                        ( k
                        , Encode.object
                            [ ( "from", Encode.string from )
                            , ( "to", Encode.string to )
                            ]
                        )
                    )
                |> Encode.object
          )
        ]


{-| Encode transform order as a JSON array of strings.
-}
encodeTransformOrder : List TransformProperty -> Encode.Value
encodeTransformOrder order =
    Encode.list
        (\t ->
            case t of
                TransformProperty.Translate ->
                    Encode.string "translate"

                TransformProperty.Rotate ->
                    Encode.string "rotate"

                TransformProperty.Skew ->
                    Encode.string "skew"

                TransformProperty.Scale ->
                    Encode.string "scale"
        )
        order


encodeProcessedPropertyConfig : Maybe (AnimGroups PropertyState) -> Dict.Dict String (List String) -> Dict.Dict String (Set String) -> Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig maybeVersions frozenAxes touchedAxes property =
    let
        frozenAxesField propName =
            case Dict.get propName frozenAxes |> Maybe.withDefault [] of
                [] ->
                    []

                axes ->
                    [ ( "frozenAxes", Encode.list Encode.string axes ) ]

        touchedAxesFields propName axisNames =
            case Dict.get propName touchedAxes of
                Nothing ->
                    []

                Just axisSet ->
                    List.map
                        (\( axis, field ) ->
                            ( field, Encode.bool (Set.member axis axisSet) )
                        )
                        axisNames

        versionFields =
            case maybeVersions of
                Just propertyVersions ->
                    let
                        propType =
                            Generator.propertyTypeString property

                        version =
                            AnimGroups.get propType propertyVersions
                                |> Maybe.map .version
                                |> Maybe.withDefault 1
                    in
                    [ ( "version", Encode.int version ) ]

                Nothing ->
                    []

        encodeTripleStart toTriple default maybeStart =
            case maybeVersions of
                Just _ ->
                    case maybeStart of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    toTriple start
                            in
                            [ ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            ]

                        Nothing ->
                            [ ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            ]

                Nothing ->
                    let
                        ( sx, sy, sz ) =
                            maybeStart
                                |> Maybe.map toTriple
                                |> Maybe.withDefault default
                    in
                    [ ( "startX", Encode.float sx )
                    , ( "startY", Encode.float sy )
                    , ( "startZ", Encode.float sz )
                    ]
    in
    case property of
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            let
                startValue =
                    config.start
                        |> Maybe.map (\s -> [ ( "startValue", Encode.float s ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                (( "type", Encode.string "customProperty" )
                    :: ( "cssProperty", Encode.string cssName )
                    :: ( "unit", Encode.string unit )
                    :: versionFields
                    ++ [ ( "endValue", Encode.float config.end )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ startValue
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                (( "type", Encode.string "customColorProperty" )
                    :: ( "cssProperty", Encode.string cssName )
                    :: versionFields
                    ++ [ ( "endColor", Encode.string (Color.toCssString config.end) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ startColorField
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedOpacityConfig config ->
            let
                startValue =
                    config.start
                        |> Maybe.map Opacity.toFloat
                        |> Maybe.withDefault 1.0
            in
            Encode.object
                (( "type", Encode.string "opacity" )
                    :: versionFields
                    ++ [ ( "startValue", Encode.float startValue )
                       , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedPerspectiveOriginConfig config ->
            let
                ( startX, startY ) =
                    config.start
                        |> Maybe.map PerspectiveOrigin.toTuple
                        |> Maybe.withDefault ( 50, 50 )

                ( endX, endY ) =
                    PerspectiveOrigin.toTuple config.end
            in
            Encode.object
                (( "type", Encode.string "perspectiveOrigin" )
                    :: versionFields
                    ++ [ ( "startX", Encode.float startX )
                       , ( "startY", Encode.float startY )
                       , ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "unitX", Encode.string (InternalUnit.toCssSuffix config.cssUnit.x) )
                       , ( "unitY", Encode.string (InternalUnit.toCssSuffix config.cssUnit.y) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ touchedAxesFields "perspectiveOrigin" [ ( "x", "touchedX" ), ( "y", "touchedY" ) ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.end
            in
            Encode.object
                (( "type", Encode.string "scale" )
                    :: versionFields
                    ++ encodeTripleStart Scale.toTriple ( 1, 1, 1 ) config.start
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "endZ", Encode.float endZ )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ frozenAxesField "scale"
                    ++ touchedAxesFields "scale" [ ( "x", "touchedX" ), ( "y", "touchedY" ), ( "z", "touchedZ" ) ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end
            in
            Encode.object
                (( "type", Encode.string "rotate" )
                    :: versionFields
                    ++ encodeTripleStart Rotate.toTriple ( 0, 0, 0 ) config.start
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "endZ", Encode.float endZ )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ frozenAxesField "rotate"
                    ++ touchedAxesFields "rotate" [ ( "x", "touchedX" ), ( "y", "touchedY" ), ( "z", "touchedZ" ) ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedSkewConfig config ->
            let
                ( endX, endY ) =
                    Skew.toTuple config.end

                startFields =
                    case maybeVersions of
                        Just _ ->
                            case config.start of
                                Just start ->
                                    let
                                        ( startX, startY ) =
                                            Skew.toTuple start
                                    in
                                    [ ( "startX", Encode.float startX )
                                    , ( "startY", Encode.float startY )
                                    ]

                                Nothing ->
                                    [ ( "startX", Encode.null )
                                    , ( "startY", Encode.null )
                                    ]

                        Nothing ->
                            let
                                ( startX, startY ) =
                                    config.start
                                        |> Maybe.map Skew.toTuple
                                        |> Maybe.withDefault ( 0, 0 )
                            in
                            [ ( "startX", Encode.float startX )
                            , ( "startY", Encode.float startY )
                            ]
            in
            Encode.object
                (( "type", Encode.string "skew" )
                    :: versionFields
                    ++ startFields
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ frozenAxesField "skew"
                    ++ touchedAxesFields "skew" [ ( "x", "touchedX" ), ( "y", "touchedY" ) ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedSizeConfig config ->
            let
                ( startWidth, startHeight ) =
                    config.start
                        |> Maybe.map Size.toTuple
                        |> Maybe.withDefault ( 0, 0 )

                ( endWidth, endHeight ) =
                    Size.toTuple config.end
            in
            Encode.object
                (( "type", Encode.string "size" )
                    :: versionFields
                    ++ [ ( "startWidth", Encode.float startWidth )
                       , ( "startHeight", Encode.float startHeight )
                       , ( "endWidth", Encode.float endWidth )
                       , ( "endHeight", Encode.float endHeight )
                       , ( "unitWidth", Encode.string (InternalUnit.toCssSuffix config.cssUnit.x) )
                       , ( "unitHeight", Encode.string (InternalUnit.toCssSuffix config.cssUnit.y) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ touchedAxesFields "size" [ ( "width", "touchedWidth" ), ( "height", "touchedHeight" ) ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )

        Builder.ProcessedTranslateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Translate.toTriple config.end
            in
            Encode.object
                (( "type", Encode.string "translate" )
                    :: versionFields
                    ++ encodeTripleStart Translate.toTriple ( 0, 0, 0 ) config.start
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "endZ", Encode.float endZ )
                       , ( "unitX", Encode.string (InternalUnit.toCssSuffix config.cssUnit.x) )
                       , ( "unitY", Encode.string (InternalUnit.toCssSuffix config.cssUnit.y) )
                       , ( "unitZ", Encode.string (InternalUnit.toCssSuffix config.cssUnit.z) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ frozenAxesField "translate"
                    ++ touchedAxesFields "translate" [ ( "x", "touchedX" ), ( "y", "touchedY" ), ( "z", "touchedZ" ) ]
                    ++ encodeEasingWithKeyframes config.duration config.easing config.spring
                )


{-| Encode easing with keyframes for complex easings (Bounce, Elastic).
For complex easings, returns list with easing="linear" and keyframes array.
For simple easings, returns list with just easing string.

If a `Spring` is set on the property, the spring takes precedence over the
easing: the spring is sampled at `defaultKeyframeCount` evenly-spaced points
across the duration (which is already the spring's settle time) and emitted
as a `linear`+`easingKeyframes` payload.

-}
encodeEasingWithKeyframes : Int -> Easing -> Maybe Spring -> List ( String, Encode.Value )
encodeEasingWithKeyframes durationMs easingValue maybeSpring =
    case maybeSpring of
        Just s ->
            [ ( "easing", Encode.string "linear" )
            , ( "easingKeyframes", encodeKeyframeSamples (springKeyframes s (toFloat durationMs)) )
            ]

        Nothing ->
            if isComplexEasing easingValue then
                [ ( "easing", Encode.string "linear" )
                , ( "easingKeyframes", encodeKeyframeSamples (EasingKeyframes.generateKeyframes easingValue (toFloat durationMs)) )
                ]

            else
                [ ( "easing", Encode.string (Easing.toWebAnimations easingValue) ) ]


{-| Encode a list of `KeyframeSample` records as a JSON array of
`{ offset, value }` objects.
-}
encodeKeyframeSamples : List EasingKeyframes.KeyframeSample -> Encode.Value
encodeKeyframeSamples samples =
    samples
        |> Encode.list
            (\sample ->
                Encode.object
                    [ ( "offset", Encode.float sample.offset )
                    , ( "value", Encode.float sample.value )
                    ]
            )


{-| Sample a spring across `[0, durationMs]` into a list of
`KeyframeSample` records (uniformly spaced offsets), suitable as
`easingKeyframes` for WAAPI playback.
-}
springKeyframes : Spring -> Float -> List EasingKeyframes.KeyframeSample
springKeyframes s durationMs =
    let
        motion =
            { spring = SpringInt.unwrap s
            , from = 0
            , to = 1
            }

        n =
            EasingKeyframes.sampleCountForDuration durationMs
    in
    List.range 0 (n - 1)
        |> List.map
            (\i ->
                let
                    offset =
                        toFloat i / toFloat (n - 1)
                in
                { offset = offset
                , value = SpringSolver.valueAt motion (offset * durationMs)
                }
            )


{-| Check if an easing type requires keyframe pre-computation for accuracy.
Bounce and Elastic easings cannot be represented accurately with a single cubic-bezier curve.
-}
isComplexEasing : Easing -> Bool
isComplexEasing easing_ =
    case easing_ of
        ElasticIn ->
            True

        ElasticOut ->
            True

        ElasticInOut ->
            True

        BounceIn ->
            True

        BounceOut ->
            True

        BounceInOut ->
            True

        BackInCustom _ ->
            True

        BackOutCustom _ ->
            True

        BackInOutCustom _ ->
            True

        _ ->
            False



-- ============================================================
-- SCROLL TIMELINE
-- ============================================================


{-| Encode a scroll-driven animation using a `ScrollTimeline`.
Duration and delay are omitted — the timeline drives progress.
Iterations, direction, and easing are supported.
-}
encodeScroll : Builder.AnimBuilder { isScrollBased : () } -> Encode.Value
encodeScroll builder =
    let
        processed =
            Builder.process builder

        source =
            Builder.getScrollSource builder
                |> Maybe.withDefault "document"

        axis_ =
            Builder.getScrollAxis builder
                |> Maybe.withDefault "block"

        elements =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            playback =
                                Builder.resolvePlayback
                                    processed.iterations
                                    processed.animationDirection
                                    config.playback

                            emitProgress =
                                Maybe.withDefault (Builder.getScrollEmitProgressFor animGroupName builder) config.emitProgress
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            (Builder.getAnimTarget animGroupName builder |> Maybe.withDefault animGroupName)
                            Nothing
                            config.transformOrder
                            Nothing
                            config.viewRangeStart
                            config.viewRangeEnd
                            (Just emitProgress)
                            config.frozenAxes
                            config.discreteEntryProperties
                            config.discreteExitProperties
                            Dict.empty
                            playback.iterations
                            playback.animationDirection
                            config.properties
                        )
                    )

        discreteEntryFields =
            encodeDiscreteEntryFields (Builder.getDiscreteEntryProperties builder)

        discreteExitFields =
            encodeDiscreteExitFields (Builder.getDiscreteExitProperties builder)
    in
    Encode.object
        ([ ( "type", Encode.string "scrollDriven" )
         , ( "timeline"
           , Encode.object
                [ ( "type", Encode.string "scroll" )
                , ( "source", Encode.string source )
                , ( "axis", Encode.string axis_ )
                ]
           )
         , ( "elements", Encode.object elements )
         , ( "iterations", encodeIterations processed.iterations )
         , ( "direction", encodeAnimationDirection processed.animationDirection )
         , ( "emitProgress", Encode.bool (Builder.getScrollEmitProgress builder) )
         ]
            ++ discreteEntryFields
            ++ discreteExitFields
        )


{-| Encode a view-driven animation using a `ViewTimeline`.
Duration and delay are omitted — the timeline drives progress.
Iterations, direction, and easing are supported.
-}
encodeView : Builder.AnimBuilder Builder.ForView -> Encode.Value
encodeView builder =
    let
        processed =
            Builder.process builder

        axis_ =
            Builder.getScrollAxis builder
                |> Maybe.withDefault "block"

        timelineBase =
            [ ( "type", Encode.string "view" )
            , ( "axis", Encode.string axis_ )
            ]

        rangeFields =
            [ Builder.getViewRangeStart builder
                |> Maybe.map (\r -> ( "rangeStart", Encode.string r ))
            , Builder.getViewRangeEnd builder
                |> Maybe.map (\r -> ( "rangeEnd", Encode.string r ))
            ]
                |> List.filterMap identity

        elements =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            playback =
                                Builder.resolvePlayback
                                    processed.iterations
                                    processed.animationDirection
                                    config.playback

                            emitProgress =
                                Maybe.withDefault (Builder.getScrollEmitProgressFor animGroupName builder) config.emitProgress
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            (Builder.getAnimTarget animGroupName builder |> Maybe.withDefault animGroupName)
                            Nothing
                            config.transformOrder
                            Nothing
                            (Builder.getViewRangeStartFor animGroupName builder)
                            (Builder.getViewRangeEndFor animGroupName builder)
                            (Just emitProgress)
                            config.frozenAxes
                            config.discreteEntryProperties
                            config.discreteExitProperties
                            Dict.empty
                            playback.iterations
                            playback.animationDirection
                            config.properties
                        )
                    )

        discreteEntryFields =
            encodeDiscreteEntryFields (Builder.getDiscreteEntryProperties builder)

        discreteExitFields =
            encodeDiscreteExitFields (Builder.getDiscreteExitProperties builder)
    in
    Encode.object
        ([ ( "type", Encode.string "viewDriven" )
         , ( "timeline", Encode.object (timelineBase ++ rangeFields) )
         , ( "elements", Encode.object elements )
         , ( "iterations", encodeIterations processed.iterations )
         , ( "direction", encodeAnimationDirection processed.animationDirection )
         , ( "emitProgress", Encode.bool (Builder.getScrollEmitProgress builder) )
         ]
            ++ discreteEntryFields
            ++ discreteExitFields
        )
