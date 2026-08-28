module Anim.Internal.Builder.TestProperty exposing (suite)

import Anim.Extra.Color as Color
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Property.Opacity as InternalOpacity
import Anim.Internal.Property.PerspectiveOrigin as InternalPerspectiveOrigin
import Anim.Internal.Property.Rotate as InternalRotate
import Anim.Internal.Property.Scale as InternalScale
import Anim.Internal.Property.Size as InternalSize
import Anim.Internal.Property.Skew as InternalSkew
import Anim.Internal.Property.Translate as InternalTranslate
import Anim.Internal.Unit as InternalUnit
import Anim.Property.Custom as Custom
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Expect
import Motion.Easing exposing (Easing(..))
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


animBuilder : Builder.AnimBuilder TestMode
animBuilder =
    Builder.init []


type alias TestMode =
    { withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    , withLiveDelta : ()
    }


processAndStore : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
processAndStore builder =
    Builder.addAnimationToHistory (Builder.process builder) builder


suite : Test
suite =
    describe "Internal.Builder.Property"
        [ defaultConfigTests
        , withTests
        , upsertTests
        , propertyGetters
        , translateClampTests
        , rotateClampTests
        , scaleClampTests
        , skewClampTests
        , sizeClampTests
        , perspectiveOriginClampTests
        , opacityClampTests
        , customClampTests
        , animationHistoryLookupTests
        , globalDelayCarryoverTests
        ]



-- ============================================================
-- defaultConfig
-- ============================================================


defaultConfigTests : Test
defaultConfigTests =
    describe "defaultConfig"
        [ test "creates a config with the given end value and Nothing for everything else" <|
            \_ ->
                let
                    config =
                        Property.defaultConfig 42
                in
                Expect.all
                    [ \c -> Expect.equal Nothing c.start
                    , \c -> Expect.equal 42 c.end
                    , \c -> Expect.equal 0 c.distance
                    , \c -> Expect.equal Nothing c.timing
                    , \c -> Expect.equal Nothing c.delay
                    , \c -> Expect.equal Nothing c.easing
                    ]
                    config
        ]



-- ============================================================
-- with* functions
-- ============================================================


withTests : Test
withTests =
    describe "with* config modifiers"
        [ test "withSpeed sets timing to Speed" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.speed 150
                    |> .timing
                    |> Expect.equal (Just (Speed 150))
        , test "withDuration sets timing to Duration" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.duration 500
                    |> .timing
                    |> Expect.equal (Just (Duration 500))
        , test "withEasing sets easing" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.easing CubicInOut
                    |> .easing
                    |> Expect.equal (Just CubicInOut)
        , test "withDelay sets delay" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.delay 200
                    |> .delay
                    |> Expect.equal (Just 200)
        , test "withSpeed overwrites previous timing" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.duration 500
                    |> Property.speed 100
                    |> .timing
                    |> Expect.equal (Just (Speed 100))
        , test "duration overwrites previous timing" <|
            \_ ->
                Property.defaultConfig 0
                    |> Property.speed 100
                    |> Property.duration 300
                    |> .timing
                    |> Expect.equal (Just (Duration 300))
        ]



-- ============================================================
-- global delay carryover
-- ============================================================


globalDelayCarryoverTests : Test
globalDelayCarryoverTests =
    let
        fadeIn =
            Opacity.begin
                >> Opacity.to 1
                >> Opacity.duration 500
                >> Opacity.end

        sequencedBuilder =
            animBuilder
                |> Builder.for "textLineOne"
                |> fadeIn
                |> Builder.for "dotOne"
                |> Builder.delay 500
                |> fadeIn
                |> Builder.for "dotTwo"
                |> Builder.delay 1000
                |> fadeIn
                |> Builder.for "dotThree"
                |> Builder.delay 1500
                |> fadeIn
                |> Builder.for "textLineTwo"
                |> Builder.delay 2000
                |> fadeIn

        processed =
            Builder.process sequencedBuilder

        opacityDelayFor groupName =
            processed.groups
                |> AnimGroups.get groupName
                |> Maybe.andThen
                    (\group ->
                        group.properties
                            |> List.filter (\prop -> Builder.processedPropertyType prop == "opacity")
                            |> List.head
                            |> Maybe.map (Builder.processedTimings >> .delay)
                    )

        fallbackBuilder =
            animBuilder
                |> Builder.delay 1000
                |> Builder.for "textLineOne"
                |> fadeIn
                |> Builder.for "dotOne"
                |> Builder.delay 500
                |> fadeIn
                |> Builder.for "dotTwo"
                |> Builder.delay 1000
                |> fadeIn
                |> Builder.for "dotThree"
                |> Builder.delay 1500
                |> fadeIn
                |> Builder.for "textLineTwo"
                |> fadeIn

        fallbackProcessed =
            Builder.process fallbackBuilder

        fallbackDelayFor groupName =
            fallbackProcessed.groups
                |> AnimGroups.get groupName
                |> Maybe.andThen
                    (\group ->
                        group.properties
                            |> List.filter (\prop -> Builder.processedPropertyType prop == "opacity")
                            |> List.head
                            |> Maybe.map (Builder.processedTimings >> .delay)
                    )
    in
    describe "delay snapshotting in single pipeline"
        [ test "early groups keep their own delay instead of inheriting the final global delay" <|
            \_ ->
                Expect.all
                    [ \_ -> opacityDelayFor "textLineOne" |> Expect.equal (Just 0)
                    , \_ -> opacityDelayFor "dotOne" |> Expect.equal (Just 500)
                    , \_ -> opacityDelayFor "dotTwo" |> Expect.equal (Just 1000)
                    , \_ -> opacityDelayFor "dotThree" |> Expect.equal (Just 1500)
                    , \_ -> opacityDelayFor "textLineTwo" |> Expect.equal (Just 2000)
                    ]
                    ()
        , test "later groups inherit the global delay when they do not override it" <|
            \_ ->
                Expect.all
                    [ \_ -> fallbackDelayFor "textLineOne" |> Expect.equal (Just 1000)
                    , \_ -> fallbackDelayFor "dotOne" |> Expect.equal (Just 500)
                    , \_ -> fallbackDelayFor "dotTwo" |> Expect.equal (Just 1000)
                    , \_ -> fallbackDelayFor "dotThree" |> Expect.equal (Just 1500)
                    , \_ -> fallbackDelayFor "textLineTwo" |> Expect.equal (Just 1000)
                    ]
                    ()
        ]



-- ============================================================
-- upsert
-- ============================================================


upsertTests : Test
upsertTests =
    let
        translateConfig =
            Builder.TranslateConfig
                { start = Nothing
                , end = InternalTranslate.fromTriple ( 10, 20, 0 )
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , spring = Nothing
                , delay = Nothing
                , cssUnit = InternalUnit.emptyCssUnitAxes
                , mode = Builder.Animate
                }

        opacityConfig =
            Builder.OpacityConfig
                { start = Nothing
                , end = InternalOpacity.fromFloat 0.5
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , spring = Nothing
                , delay = Nothing
                , cssUnit = InternalUnit.emptyCssUnitAxes
                , mode = Builder.Animate
                }

        replacementTranslateConfig =
            Builder.TranslateConfig
                { start = Nothing
                , end = InternalTranslate.fromTriple ( 100, 200, 300 )
                , distance = 0
                , timing = Nothing
                , easing = Nothing
                , spring = Nothing
                , delay = Nothing
                , cssUnit = InternalUnit.emptyCssUnitAxes
                , mode = Builder.Animate
                }

        getProperties builder =
            (Builder.getCurrentAnimGroupConfig builder).properties
    in
    describe "upsert"
        [ test "adds a property when none of that type exists" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 1
        , test "adds different property types" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert opacityConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 2
        , test "replaces an existing property of the same type" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert replacementTranslateConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 1
        , test "replacement uses the new config values" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert replacementTranslateConfig
                    |> getProperties
                    |> List.head
                    |> Expect.equal (Just replacementTranslateConfig)
        , test "does not affect other property types when replacing" <|
            \_ ->
                animBuilder
                    |> Builder.for "test"
                    |> Property.upsert translateConfig
                    |> Property.upsert opacityConfig
                    |> Property.upsert replacementTranslateConfig
                    |> getProperties
                    |> List.length
                    |> Expect.equal 2
        ]



-- ============================================================
-- property getters
-- ============================================================


propertyGetters : Test
propertyGetters =
    describe "Property getters"
        [ getStartValue
        , getEndValue
        , getRangeValue
        ]


type alias GetStartTestConfig a =
    { label : String
    , getter : String -> Builder.AnimBuilder TestMode -> Maybe a
    , buildWithFrom : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
    , expectedFrom : a
    , buildWithoutFrom : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
    , expectedDefault : a
    }


getStartTests : GetStartTestConfig a -> Test
getStartTests config =
    describe config.label
        [ test "returns the start value when explicitly set" <|
            \_ ->
                animBuilder
                    |> config.buildWithFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal (Just config.expectedFrom)
        , test "returns the default if there is no explicit start value" <|
            \_ ->
                animBuilder
                    |> config.buildWithoutFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal (Just config.expectedDefault)
        , test "returns Nothing if there is no animation" <|
            \_ ->
                animBuilder
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal Nothing
        ]


getStartValue : Test
getStartValue =
    describe "Get the start value of a property"
        [ getStartTests
            { label = "getBackgroundColorStart"
            , buildWithFrom =
                Builder.for "test"
                    >> CustomColor.begin BackgroundColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> CustomColor.begin BackgroundColor
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , getter = \animGroup builder -> Property.getCustomColorPropertyStart animGroup "background-color" builder
            , expectedFrom = Color.rgba 100 200 50 1
            , expectedDefault = Color.rgba 255 255 255 0
            }
        , getStartTests
            { label = "getFontColorStart"
            , getter = \animGroup builder -> Property.getCustomColorPropertyStart animGroup "color" builder
            , buildWithFrom =
                Builder.for "test"
                    >> CustomColor.begin TextColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , expectedFrom = Color.rgba 100 200 50 1
            , buildWithoutFrom =
                Builder.for "test"
                    >> CustomColor.begin TextColor
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , expectedDefault = Color.rgba 255 255 255 0
            }
        , getStartTests
            { label = "getOpacityStart"
            , buildWithFrom =
                Builder.for "test"
                    >> Opacity.begin
                    >> Opacity.from 0.5
                    >> Opacity.to 0
                    >> Opacity.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Opacity.begin
                    >> Opacity.to 0
                    >> Opacity.end
            , getter = Property.getOpacityStart
            , expectedFrom = 0.5
            , expectedDefault = 1.0
            }
        , getStartTests
            { label = "getRotateStart"
            , buildWithFrom =
                Builder.for "test"
                    >> Rotate.begin
                    >> Rotate.fromXYZ 10 20 30
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Rotate.begin
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.end
            , getter = Property.getRotateStart
            , expectedFrom = { x = 10, y = 20, z = 30 }
            , expectedDefault = { x = 0, y = 0, z = 0 }
            }
        , getStartTests
            { label = "getScaleStart"
            , buildWithFrom =
                Builder.for "test"
                    >> Scale.begin
                    >> Scale.fromXYZ 2 3 4
                    >> Scale.toXYZ 5 6 7
                    >> Scale.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Scale.begin
                    >> Scale.toXYZ 5 6 7
                    >> Scale.end
            , getter = Property.getScaleStart
            , expectedFrom = { x = 2, y = 3, z = 4 }
            , expectedDefault = { x = 1, y = 1, z = 1 }
            }
        , getStartTests
            { label = "getSizeStart"
            , buildWithFrom =
                Builder.for "test"
                    >> Size.begin
                    >> Size.fromHW 50 100
                    >> Size.toHW 200 300
                    >> Size.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Size.begin
                    >> Size.toHW 200 300
                    >> Size.end
            , getter = Property.getSizeStart
            , expectedFrom = { width = 100, height = 50 }
            , expectedDefault = { width = 0, height = 0 }
            }
        , getStartTests
            { label = "getTranslateStart"
            , buildWithFrom =
                Builder.for "test"
                    >> Translate.begin
                    >> Translate.fromXYZ 10 20 30
                    >> Translate.toXYZ 100 200 300
                    >> Translate.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Translate.begin
                    >> Translate.toXYZ 100 200 300
                    >> Translate.end
            , getter = Property.getTranslateStart
            , expectedFrom = { x = 10, y = 20, z = 30 }
            , expectedDefault = { x = 0, y = 0, z = 0 }
            }
        ]


type alias GetEndTestConfig a =
    { label : String
    , getter : String -> Builder.AnimBuilder TestMode -> Maybe a
    , build : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
    , expectedEnd : a
    }


getEndTests : GetEndTestConfig a -> Test
getEndTests config =
    describe config.label
        [ test "returns the end value" <|
            \_ ->
                animBuilder
                    |> config.build
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal (Just config.expectedEnd)
        , test "returns Nothing if there is no animation" <|
            \_ ->
                animBuilder
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal Nothing
        ]


getEndValue : Test
getEndValue =
    describe "Get the end value of a property"
        [ getEndTests
            { label = "getBackgroundColorEnd"
            , build =
                Builder.for "test"
                    >> CustomColor.begin BackgroundColor
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , getter = \animGroup builder -> Property.getCustomColorPropertyEnd animGroup "background-color" builder
            , expectedEnd = Color.red
            }
        , getEndTests
            { label = "getFontColorEnd"
            , build =
                Builder.for "test"
                    >> CustomColor.begin TextColor
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , getter = \animGroup builder -> Property.getCustomColorPropertyEnd animGroup "color" builder
            , expectedEnd = Color.red
            }
        , getEndTests
            { label = "getOpacityEnd"
            , build =
                Builder.for "test"
                    >> Opacity.begin
                    >> Opacity.to 0.5
                    >> Opacity.end
            , getter = Property.getOpacityEnd
            , expectedEnd = 0.5
            }
        , getEndTests
            { label = "getRotateEnd"
            , build =
                Builder.for "test"
                    >> Rotate.begin
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.end
            , getter = Property.getRotateEnd
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        , getEndTests
            { label = "getScaleEnd"
            , build =
                Builder.for "test"
                    >> Scale.begin
                    >> Scale.toXYZ 5 6 7
                    >> Scale.end
            , getter = Property.getScaleEnd
            , expectedEnd = { x = 5, y = 6, z = 7 }
            }
        , getEndTests
            { label = "getSizeEnd"
            , build =
                Builder.for "test"
                    >> Size.begin
                    >> Size.toHW 200 300
                    >> Size.end
            , getter = Property.getSizeEnd
            , expectedEnd = { width = 300, height = 200 }
            }
        , getEndTests
            { label = "getTranslateEnd"
            , build =
                Builder.for "test"
                    >> Translate.begin
                    >> Translate.toXYZ 100 200 300
                    >> Translate.end
            , getter = Property.getTranslateEnd
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        ]


type alias GetRangeTestConfig a =
    { label : String
    , getter : String -> Builder.AnimBuilder TestMode -> Maybe { start : Maybe a, end : a }
    , buildWithFrom : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
    , expectedStart : a
    , expectedEndWithFrom : a
    , buildWithoutFrom : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
    , expectedDefaultStart : Maybe a
    , expectedEnd : a
    }


getRangeTests : GetRangeTestConfig a -> Test
getRangeTests config =
    describe config.label
        [ test "returns range with explicit start" <|
            \_ ->
                animBuilder
                    |> config.buildWithFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal
                        (Just
                            { start = Just config.expectedStart
                            , end = config.expectedEndWithFrom
                            }
                        )
        , test "returns range with default start when no explicit start" <|
            \_ ->
                animBuilder
                    |> config.buildWithoutFrom
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal
                        (Just
                            { start = config.expectedDefaultStart
                            , end = config.expectedEnd
                            }
                        )
        , test "returns Nothing if there is no animation" <|
            \_ ->
                animBuilder
                    |> processAndStore
                    |> config.getter "test"
                    |> Expect.equal Nothing
        ]


getRangeValue : Test
getRangeValue =
    describe "Get the range of a property"
        [ getRangeTests
            { label = "getBackgroundColorRange"
            , buildWithFrom =
                Builder.for "test"
                    >> CustomColor.begin BackgroundColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to (Color.rgba 255 0 0 1)
                    >> CustomColor.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> CustomColor.begin BackgroundColor
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , getter = \animGroup builder -> Property.getCustomColorPropertyRange animGroup "background-color" builder
            , expectedStart = Color.rgba 100 200 50 1
            , expectedEndWithFrom = Color.rgba 255 0 0 1
            , expectedDefaultStart = Just (Color.rgba 255 255 255 0)
            , expectedEnd = Color.red
            }
        , getRangeTests
            { label = "getFontColorRange"
            , buildWithFrom =
                Builder.for "test"
                    >> CustomColor.begin TextColor
                    >> CustomColor.from (Color.rgba 100 200 50 1)
                    >> CustomColor.to (Color.rgba 255 0 0 1)
                    >> CustomColor.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> CustomColor.begin TextColor
                    >> CustomColor.to Color.red
                    >> CustomColor.end
            , getter = \animGroup builder -> Property.getCustomColorPropertyRange animGroup "color" builder
            , expectedStart = Color.rgba 100 200 50 1
            , expectedEndWithFrom = Color.rgba 255 0 0 1
            , expectedDefaultStart = Just (Color.rgba 255 255 255 0)
            , expectedEnd = Color.red
            }
        , getRangeTests
            { label = "getOpacityRange"
            , buildWithFrom =
                Builder.for "test"
                    >> Opacity.begin
                    >> Opacity.from 0.5
                    >> Opacity.to 0
                    >> Opacity.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Opacity.begin
                    >> Opacity.to 0
                    >> Opacity.end
            , getter = Property.getOpacityRange
            , expectedStart = 0.5
            , expectedEndWithFrom = 0
            , expectedDefaultStart = Just 1.0
            , expectedEnd = 0
            }
        , getRangeTests
            { label = "getRotateRange"
            , buildWithFrom =
                Builder.for "test"
                    >> Rotate.begin
                    >> Rotate.fromXYZ 10 20 30
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Rotate.begin
                    >> Rotate.toXYZ 100 200 300
                    >> Rotate.end
            , getter = Property.getRotateRange
            , expectedStart = { x = 10, y = 20, z = 30 }
            , expectedEndWithFrom = { x = 100, y = 200, z = 300 }
            , expectedDefaultStart = Just { x = 0, y = 0, z = 0 }
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        , getRangeTests
            { label = "getScaleRange"
            , buildWithFrom =
                Builder.for "test"
                    >> Scale.begin
                    >> Scale.fromXYZ 2 3 4
                    >> Scale.toXYZ 5 6 7
                    >> Scale.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Scale.begin
                    >> Scale.toXYZ 5 6 7
                    >> Scale.end
            , getter = Property.getScaleRange
            , expectedStart = { x = 2, y = 3, z = 4 }
            , expectedEndWithFrom = { x = 5, y = 6, z = 7 }
            , expectedDefaultStart = Just { x = 1, y = 1, z = 1 }
            , expectedEnd = { x = 5, y = 6, z = 7 }
            }
        , getRangeTests
            { label = "getSizeRange"
            , buildWithFrom =
                Builder.for "test"
                    >> Size.begin
                    >> Size.fromHW 50 100
                    >> Size.toHW 200 300
                    >> Size.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Size.begin
                    >> Size.toHW 200 300
                    >> Size.end
            , getter = Property.getSizeRange
            , expectedStart = { width = 100, height = 50 }
            , expectedEndWithFrom = { width = 300, height = 200 }
            , expectedDefaultStart = Just { width = 0, height = 0 }
            , expectedEnd = { width = 300, height = 200 }
            }
        , getRangeTests
            { label = "getTranslateRange"
            , buildWithFrom =
                Builder.for "test"
                    >> Translate.begin
                    >> Translate.fromXYZ 10 20 30
                    >> Translate.toXYZ 100 200 300
                    >> Translate.end
            , buildWithoutFrom =
                Builder.for "test"
                    >> Translate.begin
                    >> Translate.toXYZ 100 200 300
                    >> Translate.end
            , getter = Property.getTranslateRange
            , expectedStart = { x = 10, y = 20, z = 30 }
            , expectedEndWithFrom = { x = 100, y = 200, z = 300 }
            , expectedDefaultStart = Just { x = 0, y = 0, z = 0 }
            , expectedEnd = { x = 100, y = 200, z = 300 }
            }
        ]



-- ============================================================
-- BATCH HELPERS
-- ============================================================


{-| Mimic what an Engine's `animate` does after processing an animation:
push it to history, merge baselines, and clear in-progress data.
-}
finishAnimateBatch : Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode
finishAnimateBatch builder =
    builder
        |> processAndStore
        |> Builder.mergeBaselines
        |> Builder.clearAnimData


{-| Pull the first TranslateConfig out of the in-progress builder.
-}
firstTranslateConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalTranslate.Translate)
firstTranslateConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.TranslateConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head



-- ============================================================
-- TRANSLATE CLAMPS
-- ============================================================


translateClampTests : Test
translateClampTests =
    let
        endRecord builder =
            firstTranslateConfig builder
                |> Maybe.map (.end >> InternalTranslate.toRecord)

        startRecord builder =
            firstTranslateConfig builder
                |> Maybe.andThen .start
                |> Maybe.map InternalTranslate.toRecord
    in
    describe "Translate clamps"
        [ test "clampX clamps explicit toX above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.toX 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "clampX still clamps when declared after toX" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.toX 500
                            >> Translate.clampX 0 200
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "clampX clamps explicit fromX below min" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.fromX -100
                            >> Translate.toX 50
                            >> Translate.end
                       )
                    |> startRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 0 })
        , test "clampX clamps a byX overshoot to the max boundary" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.fromX 150
                            >> Translate.byX 100
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "clampY only clamps the Y axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampY 0 100
                            >> Translate.toXY 500 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 100, z = 0 })
        , test "clampZ clamps the Z axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampZ -10 10
                            >> Translate.toZ 1000
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 10 })
        , test "clampX with reversed args (max < min) is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 200 0
                            >> Translate.toX 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "unclampX removes only the X axis clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.clampY 0 100
                            >> Translate.unclampX
                            >> Translate.toXY 500 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 100, z = 0 })
        , test "clamps are scoped to the active animGroup" <|
            \_ ->
                animBuilder
                    |> (Builder.for "ship"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.toX 50
                            >> Translate.end
                       )
                    |> (Builder.for "other"
                            >> Translate.begin
                            >> Translate.toX 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 0, z = 0 })
        , test "no clamps means values pass through unchanged" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.toX 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 0, z = 0 })
        , test "clamps persist across an animate batch (not cleared by clearAnimData)" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.toX 100
                            >> Translate.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.toX 500
                            >> Translate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "out-of-range start snaps to boundary" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.fromX 500
                            >> Translate.toX 100
                            >> Translate.end
                       )
                    |> startRecord
                    |> Expect.equal (Just { x = 200, y = 0, z = 0 })
        , test "distance is recomputed from clamped values" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Translate.begin
                            >> Translate.clampX 0 200
                            >> Translate.fromX 0
                            >> Translate.toX 1000
                            >> Translate.end
                       )
                    |> firstTranslateConfig
                    |> Maybe.map (.distance >> round)
                    |> Expect.equal (Just 200)
        ]



-- ============================================================
-- ROTATE / SCALE / SKEW / SIZE / PERSPECTIVE-ORIGIN / OPACITY / CUSTOM CLAMPS
-- ============================================================


firstRotateConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalRotate.Rotate)
firstRotateConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.RotateConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


firstScaleConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalScale.Scale)
firstScaleConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.ScaleConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


firstSkewConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalSkew.Skew)
firstSkewConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.SkewConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


firstSizeConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalSize.Size)
firstSizeConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.SizeConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


firstPerspectiveOriginConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalPerspectiveOrigin.PerspectiveOrigin)
firstPerspectiveOriginConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.PerspectiveOriginConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


firstOpacityConfig : Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig InternalOpacity.Opacity)
firstOpacityConfig builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.OpacityConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


firstCustomConfig : String -> Builder.AnimBuilder TestMode -> Maybe (Builder.AnimationConfig Float)
firstCustomConfig cssName builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.CustomPropertyConfig name _ cfg ->
                        if name == cssName then
                            Just cfg

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head


rotateClampTests : Test
rotateClampTests =
    let
        endRecord builder =
            firstRotateConfig builder
                |> Maybe.map (.end >> InternalRotate.toRecord)

        startRecord builder =
            firstRotateConfig builder
                |> Maybe.andThen .start
                |> Maybe.map InternalRotate.toRecord
    in
    describe "Rotate clamps"
        [ test "clampX clamps explicit toX above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampX 0 90
                            >> Rotate.toX 360
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 90, y = 0, z = 0 })
        , test "clampX still clamps when declared after toX" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.toX 360
                            >> Rotate.clampX 0 90
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 90, y = 0, z = 0 })
        , test "clampY only clamps the Y axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampY 0 45
                            >> Rotate.toXY 360 360
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 360, y = 45, z = 0 })
        , test "clampZ clamps the Z axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampZ -10 10
                            >> Rotate.toZ 1000
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 10 })
        , test "clampX with reversed args (max < min) is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampX 90 0
                            >> Rotate.toX 360
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 90, y = 0, z = 0 })
        , test "unclampX removes only the X axis clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampX 0 90
                            >> Rotate.clampY 0 45
                            >> Rotate.unclampX
                            >> Rotate.toXY 360 360
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 360, y = 45, z = 0 })
        , test "clamps are scoped to the active animGroup" <|
            \_ ->
                animBuilder
                    |> (Builder.for "ship"
                            >> Rotate.begin
                            >> Rotate.clampX 0 90
                            >> Rotate.toX 50
                            >> Rotate.end
                       )
                    |> (Builder.for "other"
                            >> Rotate.begin
                            >> Rotate.toX 360
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 360, y = 0, z = 0 })
        , test "clamps persist across an animate batch" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampX 0 90
                            >> Rotate.toX 30
                            >> Rotate.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.toX 360
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 90, y = 0, z = 0 })
        , test "out-of-range start snaps to boundary" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.clampX 0 90
                            >> Rotate.fromX -50
                            >> Rotate.toX 30
                            >> Rotate.end
                       )
                    |> startRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 0 })
        , test "byXYZ adds the delta to the configured start rotation" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Rotate.begin
                            >> Rotate.fromXYZ 10 20 30
                            >> Rotate.byXYZ 5 -5 15
                            >> Rotate.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 15, y = 15, z = 45 })
        ]


scaleClampTests : Test
scaleClampTests =
    let
        endRecord builder =
            firstScaleConfig builder
                |> Maybe.map (.end >> InternalScale.toRecord)
    in
    describe "Scale clamps"
        [ test "clampX clamps explicit toX above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.clampX 0.5 2
                            >> Scale.toX 5
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 2, y = 1, z = 1 })
        , test "clampX still clamps when declared after toX" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.toX 5
                            >> Scale.clampX 0.5 2
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 2, y = 1, z = 1 })
        , test "clampY only clamps the Y axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.clampY 0.5 1.5
                            >> Scale.toXY 5 5
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 5, y = 1.5, z = 1 })
        , test "clampZ clamps the Z axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.clampZ 0.1 0.5
                            >> Scale.toZ 10
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 1, y = 1, z = 0.5 })
        , test "clampX with reversed args is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.clampX 2 0.5
                            >> Scale.toX 5
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 2, y = 1, z = 1 })
        , test "unclampX removes only the X axis clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.clampX 0.5 2
                            >> Scale.clampY 0.5 1.5
                            >> Scale.unclampX
                            >> Scale.toXY 5 5
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 5, y = 1.5, z = 1 })
        , test "clamps are scoped to the active animGroup" <|
            \_ ->
                animBuilder
                    |> (Builder.for "a"
                            >> Scale.begin
                            >> Scale.clampX 0.5 2
                            >> Scale.toX 1.5
                            >> Scale.end
                       )
                    |> (Builder.for "b"
                            >> Scale.begin
                            >> Scale.toX 5
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 5, y = 1, z = 1 })
        , test "clamps persist across animate batches" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.clampX 0.5 2
                            >> Scale.toX 1
                            >> Scale.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.toX 5
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 2, y = 1, z = 1 })
        , test "byXYZ adds the delta to the configured start scale" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Scale.begin
                            >> Scale.fromXYZ 1 2 3
                            >> Scale.byXYZ 0.25 -0.5 1
                            >> Scale.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 1.25, y = 1.5, z = 4 })
        ]


skewClampTests : Test
skewClampTests =
    let
        endTuple builder =
            firstSkewConfig builder
                |> Maybe.map (\c -> ( InternalSkew.getX c.end, InternalSkew.getY c.end ))
    in
    describe "Skew clamps"
        [ test "clampX clamps explicit toX above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.clampX 0 30
                            >> Skew.toX 90
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 30, 0 ))
        , test "clampX still clamps when declared after toX" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.toX 90
                            >> Skew.clampX 0 30
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 30, 0 ))
        , test "clampY only clamps the Y axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.clampY 0 15
                            >> Skew.toXY 90 90
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 90, 15 ))
        , test "unclampX removes only X axis clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.clampX 0 30
                            >> Skew.clampY 0 15
                            >> Skew.unclampX
                            >> Skew.toXY 90 90
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 90, 15 ))
        , test "clampX with reversed args is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.clampX 30 0
                            >> Skew.toX 90
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 30, 0 ))
        , test "clamps persist across animate batches" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.clampX 0 30
                            >> Skew.toX 10
                            >> Skew.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.toX 90
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 30, 0 ))
        , test "byXY adds the delta to the configured start skew" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Skew.begin
                            >> Skew.fromXY 10 20
                            >> Skew.byXY 5 -10
                            >> Skew.end
                       )
                    |> endTuple
                    |> Expect.equal (Just ( 15, 10 ))
        ]


sizeClampTests : Test
sizeClampTests =
    let
        endRecord builder =
            firstSizeConfig builder
                |> Maybe.map (.end >> InternalSize.toRecord)
    in
    describe "Size clamps"
        [ test "clampWidth clamps explicit toW above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.clampWidth 0 200
                            >> Size.toW 500
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 200, height = 0 })
        , test "clampWidth still clamps when declared after toW" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.toW 500
                            >> Size.clampWidth 0 200
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 200, height = 0 })
        , test "clampHeight only clamps the height" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.clampHeight 0 100
                            >> Size.toHW 500 500
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 500, height = 100 })
        , test "clampWidth with reversed args is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.clampWidth 200 0
                            >> Size.toW 500
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 200, height = 0 })
        , test "byHW adds the delta to the configured start size" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.fromHW 100 200
                            >> Size.byHW 10 20
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 220, height = 110 })
        , test "unclampWidth removes only width clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.clampWidth 0 200
                            >> Size.clampHeight 0 100
                            >> Size.unclampWidth
                            >> Size.toHW 500 500
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 500, height = 100 })
        , test "clamps persist across animate batches" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.clampWidth 0 200
                            >> Size.toW 100
                            >> Size.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Size.begin
                            >> Size.toW 500
                            >> Size.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { width = 200, height = 0 })
        ]


perspectiveOriginClampTests : Test
perspectiveOriginClampTests =
    let
        endRecord builder =
            firstPerspectiveOriginConfig builder
                |> Maybe.map (.end >> InternalPerspectiveOrigin.toRecord)

        endUnit builder =
            firstPerspectiveOriginConfig builder
                |> Maybe.andThen (.cssUnit >> .x)
    in
    describe "PerspectiveOrigin clamps"
        [ test "clampX clamps explicit toX above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.clampX 0 100
                            >> PerspectiveOrigin.toX 500
                            >> PerspectiveOrigin.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 100, y = 50 })
        , test "clampX still clamps when declared after toX" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.toX 500
                            >> PerspectiveOrigin.clampX 0 100
                            >> PerspectiveOrigin.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 100, y = 50 })
        , test "clampY only clamps Y axis" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.clampY 0 60
                            >> PerspectiveOrigin.toXY 500 500
                            >> PerspectiveOrigin.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 60 })
        , test "by adds the delta to the configured start perspective origin" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.fromXY 10 20
                            >> PerspectiveOrigin.by 5
                            >> PerspectiveOrigin.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 15, y = 25 })
        , test "px unit is preserved across clamping" <|
            \_ ->
                animBuilder
                    |> PerspectiveOrigin.initXY "test" 0 0
                    |> PerspectiveOrigin.initCssUnit Unit.Px
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.clampX 0 100
                            >> PerspectiveOrigin.toX 500
                            >> PerspectiveOrigin.end
                       )
                    |> endUnit
                    |> Expect.equal (Just Unit.Px)
        , test "unclampX removes only X axis clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.clampX 0 100
                            >> PerspectiveOrigin.clampY 0 60
                            >> PerspectiveOrigin.unclampX
                            >> PerspectiveOrigin.toXY 500 500
                            >> PerspectiveOrigin.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 500, y = 60 })
        , test "clampX with reversed args is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> PerspectiveOrigin.begin
                            >> PerspectiveOrigin.clampX 100 0
                            >> PerspectiveOrigin.toX 500
                            >> PerspectiveOrigin.end
                       )
                    |> endRecord
                    |> Expect.equal (Just { x = 100, y = 50 })
        ]


opacityClampTests : Test
opacityClampTests =
    let
        endValue builder =
            firstOpacityConfig builder
                |> Maybe.map (.end >> InternalOpacity.toFloat)
    in
    describe "Opacity clamps"
        [ test "clamp clamps explicit to above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.clamp 0 0.5
                            >> Opacity.to 1
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 0.5)
        , test "clamp still clamps when declared after to" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.to 1
                            >> Opacity.clamp 0 0.5
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 0.5)
        , test "clamp clamps below min" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.clamp 0.2 1
                            >> Opacity.to 0
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 0.2)
        , test "clamp with reversed args is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.clamp 0.5 0
                            >> Opacity.to 1
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 0.5)
        , test "by adds the delta to the configured start opacity" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.from 0.25
                            >> Opacity.by 0.5
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 0.75)
        , test "unclamp removes the clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.clamp 0 0.5
                            >> Opacity.unclamp
                            >> Opacity.to 1
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 1)
        , test "clamps are scoped to the active animGroup" <|
            \_ ->
                animBuilder
                    |> (Builder.for "a"
                            >> Opacity.begin
                            >> Opacity.clamp 0 0.5
                            >> Opacity.to 0.3
                            >> Opacity.end
                       )
                    |> (Builder.for "b"
                            >> Opacity.begin
                            >> Opacity.to 1
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 1)
        , test "clamps persist across animate batches" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.clamp 0 0.5
                            >> Opacity.to 0.3
                            >> Opacity.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Opacity.begin
                            >> Opacity.to 1
                            >> Opacity.end
                       )
                    |> endValue
                    |> Expect.equal (Just 0.5)
        ]


customClampTests : Test
customClampTests =
    let
        endValue cssName builder =
            firstCustomConfig cssName builder
                |> Maybe.map .end
    in
    describe "Custom clamps"
        [ test "clamp clamps explicit to above max" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.clamp 0 200
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 200)
        , test "clamp still clamps when declared after to" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.to 500
                            >> Custom.clamp 0 200
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 200)
        , test "clamp with reversed args is normalized" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.clamp 200 0
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 200)
        , test "unclamp removes the clamp" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.clamp 0 200
                            >> Custom.unclamp
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 500)
        , test "clamps are keyed by CSS property name" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.clamp 0 200
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Top Unit.Px)
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> endValue "top"
                    |> Expect.equal (Just 500)
        , test "clamps are scoped to the active animGroup" <|
            \_ ->
                animBuilder
                    |> (Builder.for "a"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.clamp 0 200
                            >> Custom.to 50
                            >> Custom.end
                       )
                    |> (Builder.for "b"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 500)
        , test "clamps persist across animate batches" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.clamp 0 200
                            >> Custom.to 50
                            >> Custom.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.to 500
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 200)
        , test "by adds the delta to the configured start value" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.from 100
                            >> Custom.by 25
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 125)
        , test "by defaults the start to 0 when none is configured" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.by 30
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 30)
        , test "by accumulates across animate batches via the carried start" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.from 0
                            >> Custom.by 10
                            >> Custom.end
                       )
                    |> finishAnimateBatch
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.by 10
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 20)
        , test "clamp pins a by overshoot to the max boundary" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.from 100
                            >> Custom.clamp 0 120
                            >> Custom.by 50
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 120)
        , test "clamp pins a negative by undershoot to the min boundary" <|
            \_ ->
                animBuilder
                    |> (Builder.for "test"
                            >> Custom.begin (Custom.Left Unit.Px)
                            >> Custom.from 10
                            >> Custom.clamp 0 100
                            >> Custom.by -50
                            >> Custom.end
                       )
                    |> endValue "left"
                    |> Expect.equal (Just 0)
        ]



-- ============================================================
-- animation history lookup
-- ============================================================


{-| Regression: a property animated in an earlier (non-current) history
entry must remain discoverable, so engines that resolve resize baselines
by scanning history can still find it after a later, property-less
animation runs on the same group.

Concretely: `Scale.init "cube" 1` registers a Scale config in the cube's
history. A subsequent `Rotate`-only animation on the same group makes that
Rotate the new `current`, pushing the Scale-bearing entry into `.history`.
`getAnimationConfigs` must return both, current first, so
`findCurrentScale` can fall back to history and `Scale.bounds` keeps
working.

-}
animationHistoryLookupTests : Test
animationHistoryLookupTests =
    describe "getAnimationConfigs"
        [ test "returns an empty list for an unknown group" <|
            \_ ->
                animBuilder
                    |> Builder.getAnimationConfigs "missing"
                    |> List.length
                    |> Expect.equal 0
        , test "returns a single entry after one animation" <|
            \_ ->
                animBuilder
                    |> (Builder.for "cube" >> Scale.begin >> Scale.to 1 >> Scale.end)
                    |> processAndStore
                    |> Builder.getAnimationConfigs "cube"
                    |> List.length
                    |> Expect.equal 1
        , test "returns current first then history (most recent first)" <|
            \_ ->
                let
                    propertyTags configs =
                        configs
                            |> List.map
                                (\group ->
                                    group.properties
                                        |> List.map
                                            (\p ->
                                                case p of
                                                    Builder.ProcessedScaleConfig _ ->
                                                        "scale"

                                                    Builder.ProcessedRotateConfig _ ->
                                                        "rotate"

                                                    _ ->
                                                        "other"
                                            )
                                )
                in
                animBuilder
                    |> (Builder.for "cube" >> Scale.begin >> Scale.to 1 >> Scale.end)
                    |> processAndStore
                    |> Builder.mergeBaselines
                    |> Builder.clearAnimData
                    |> (Builder.for "cube" >> Rotate.begin >> Rotate.toX 90 >> Rotate.end)
                    |> processAndStore
                    |> Builder.getAnimationConfigs "cube"
                    |> propertyTags
                    |> Expect.equal [ [ "rotate" ], [ "scale" ] ]
        , test "preserves a Scale config in history after a Rotate-only animation runs (regression for Scale.bounds after non-scale animate)" <|
            \_ ->
                animBuilder
                    |> (Builder.for "cube" >> Scale.begin >> Scale.to 1 >> Scale.end)
                    |> processAndStore
                    |> Builder.mergeBaselines
                    |> Builder.clearAnimData
                    |> (Builder.for "cube" >> Rotate.begin >> Rotate.toX 90 >> Rotate.end)
                    |> processAndStore
                    |> Builder.getAnimationConfigs "cube"
                    |> List.any
                        (\group ->
                            List.any
                                (\p ->
                                    case p of
                                        Builder.ProcessedScaleConfig _ ->
                                            True

                                        _ ->
                                            False
                                )
                                group.properties
                        )
                    |> Expect.equal True
        , test "preserves a Size config in history after a Rotate-only animation runs (regression for Size.bounds after non-size animate)" <|
            \_ ->
                animBuilder
                    |> Size.initHW "box" 100 200
                    |> processAndStore
                    |> Builder.mergeBaselines
                    |> Builder.clearAnimData
                    |> (Builder.for "box" >> Rotate.begin >> Rotate.toX 90 >> Rotate.end)
                    |> processAndStore
                    |> Builder.getAnimationConfigs "box"
                    |> List.any
                        (\group ->
                            List.any
                                (\p ->
                                    case p of
                                        Builder.ProcessedSizeConfig _ ->
                                            True

                                        _ ->
                                            False
                                )
                                group.properties
                        )
                    |> Expect.equal True
        ]
