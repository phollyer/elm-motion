module Anim.Internal.Engine.WAAPI.TestProgressApply exposing (suite)

import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup exposing (AnimationStatus(..), PropertyState)
import Anim.Internal.Engine.WAAPI.ProgressApply as ProgressApply
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
import Expect
import Motion.Easing exposing (Easing(..))
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


unitAxes : InternalUnit.ResolvedCssUnitAxes
unitAxes =
    { x = InternalUnit.default
    , y = InternalUnit.default
    , z = InternalUnit.default
    }


{-| Helper to build a `ProcessedAnimationConfig` with sensible defaults
for a single property type.
-}
mkCfg : Maybe a -> a -> Easing -> Builder.ProcessedAnimationConfig a
mkCfg start end easing =
    { start = start
    , end = end
    , duration = 1000
    , speed = 1
    , distance = 0
    , timing = Duration 1000
    , easing = easing
    , spring = Nothing
    , cssUnit = unitAxes
    , delay = 0
    , mode = Builder.Animate
    }


mkState : Builder.ProcessedPropertyConfig -> PropertyState
mkState config =
    { version = 0, status = Running, config = config }


singleState : String -> Builder.ProcessedPropertyConfig -> AnimGroups.AnimGroups PropertyState
singleState propType config =
    AnimGroups.fromList [ ( propType, mkState config ) ]


suite : Test
suite =
    describe "Anim.Internal.Engine.WAAPI.ProgressApply"
        [ emptyProgressTests
        , unknownPropertyTests
        , opacityTests
        , translateTests
        , rotateTests
        , scaleTests
        , skewTests
        , sizeTests
        , perspectiveOriginTests
        , customPropertyTests
        , customColorPropertyTests
        , easingTests
        , startFallbackTests
        ]


emptyProgressTests : Test
emptyProgressTests =
    describe "empty propertyProgress dict"
        [ test "leaves baselines untouched" <|
            \_ ->
                let
                    states =
                        singleState "opacity" (Builder.ProcessedOpacityConfig (mkCfg (Just (Opacity.fromFloat 0)) (Opacity.fromFloat 1) Linear))

                    baseline =
                        PropertyBaselines.setOpacity (Opacity.fromFloat 0.25) PropertyBaselines.empty
                in
                ProgressApply.applyPropertyProgress Dict.empty states baseline
                    |> PropertyBaselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    |> Expect.equal (Just 0.25)
        ]


unknownPropertyTests : Test
unknownPropertyTests =
    describe "propType missing from propertyStates"
        [ test "is silently skipped" <|
            \_ ->
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "opacity", 0.5 ) ])
                    AnimGroups.init
                    PropertyBaselines.empty
                    |> PropertyBaselines.getOpacity
                    |> Expect.equal Nothing
        ]


opacityTests : Test
opacityTests =
    describe "opacity"
        [ test "interpolates 0->1 at progress 0.5 with linear easing" <|
            \_ ->
                let
                    states =
                        singleState "opacity"
                            (Builder.ProcessedOpacityConfig
                                (mkCfg (Just (Opacity.fromFloat 0)) (Opacity.fromFloat 1) Linear)
                            )
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "opacity", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    |> Expect.equal (Just 0.5)
        ]


translateTests : Test
translateTests =
    describe "translate"
        [ test "interpolates each axis with linear easing" <|
            \_ ->
                let
                    end =
                        Translate.fromRecord { x = 100, y = 200, z = 0 }

                    start =
                        Translate.fromRecord { x = 0, y = 0, z = 0 }

                    states =
                        singleState "translate"
                            (Builder.ProcessedTranslateConfig (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "translate", 0.25 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getTranslate
                    |> Maybe.map Translate.toRecord
                    |> Expect.equal (Just { x = 25, y = 50, z = 0 })
        ]


rotateTests : Test
rotateTests =
    describe "rotate"
        [ test "interpolates each axis with linear easing" <|
            \_ ->
                let
                    end =
                        Rotate.fromRecord { x = 0, y = 0, z = 180 }

                    start =
                        Rotate.fromRecord { x = 0, y = 0, z = 0 }

                    states =
                        singleState "rotate"
                            (Builder.ProcessedRotateConfig (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "rotate", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getRotate
                    |> Maybe.map Rotate.toRecord
                    |> Expect.equal (Just { x = 0, y = 0, z = 90 })
        ]


scaleTests : Test
scaleTests =
    describe "scale"
        [ test "interpolates each axis with linear easing" <|
            \_ ->
                let
                    end =
                        Scale.fromRecord { x = 2, y = 2, z = 1 }

                    start =
                        Scale.fromRecord { x = 1, y = 1, z = 1 }

                    states =
                        singleState "scale"
                            (Builder.ProcessedScaleConfig (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "scale", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getScale
                    |> Maybe.map Scale.toRecord
                    |> Expect.equal (Just { x = 1.5, y = 1.5, z = 1 })
        ]


skewTests : Test
skewTests =
    describe "skew"
        [ test "interpolates each axis with linear easing" <|
            \_ ->
                let
                    end =
                        Skew.fromRecord { x = 20, y = 40 }

                    start =
                        Skew.fromRecord { x = 0, y = 0 }

                    states =
                        singleState "skew"
                            (Builder.ProcessedSkewConfig (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "skew", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getSkew
                    |> Maybe.map Skew.toRecord
                    |> Expect.equal (Just { x = 10, y = 20 })
        ]


sizeTests : Test
sizeTests =
    describe "size"
        [ test "interpolates width/height with linear easing" <|
            \_ ->
                let
                    end =
                        Size.fromRecord { width = 200, height = 100 }

                    start =
                        Size.fromRecord { width = 0, height = 0 }

                    states =
                        singleState "size"
                            (Builder.ProcessedSizeConfig (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "size", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getSize
                    |> Maybe.map Size.toRecord
                    |> Expect.equal (Just { width = 100, height = 50 })
        ]


perspectiveOriginTests : Test
perspectiveOriginTests =
    describe "perspectiveOrigin"
        [ test "interpolates x/y with linear easing" <|
            \_ ->
                let
                    end =
                        PerspectiveOrigin.fromRecord { x = 100, y = 100 }

                    start =
                        PerspectiveOrigin.fromRecord { x = 0, y = 0 }

                    states =
                        singleState "perspectiveOrigin"
                            (Builder.ProcessedPerspectiveOriginConfig (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "perspectiveOrigin", 0.25 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getPerspectiveOrigin
                    |> Maybe.map PerspectiveOrigin.toRecord
                    |> Expect.equal (Just { x = 25, y = 25 })
        ]


customPropertyTests : Test
customPropertyTests =
    describe "custom property"
        [ test "interpolates the underlying float with linear easing" <|
            \_ ->
                let
                    states =
                        singleState "custom:--my-prop"
                            (Builder.ProcessedCustomPropertyConfig "--my-prop" "px" (mkCfg (Just 0) 100 Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "custom:--my-prop", 0.4 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getCustomProperty "--my-prop"
                    |> Expect.equal (Just 40)
        ]


customColorPropertyTests : Test
customColorPropertyTests =
    describe "custom color property"
        [ test "interpolates the color with linear easing at midpoint" <|
            \_ ->
                let
                    start =
                        Color.fromRGBA { r = 0, g = 0, b = 0, a = 1 }

                    end =
                        Color.fromRGBA { r = 255, g = 255, b = 255, a = 1 }

                    states =
                        singleState "customColor:--accent"
                            (Builder.ProcessedCustomColorPropertyConfig "--accent" (mkCfg (Just start) end Linear))
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "customColor:--accent", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getCustomColorProperty "--accent"
                    |> Maybe.map Color.toRgba
                    |> Maybe.map (\rgba -> ( rgba.r, rgba.g, rgba.b ))
                    |> Expect.equal (Just ( 128, 128, 128 ))
        ]


easingTests : Test
easingTests =
    describe "easing is applied to raw progress before interpolation"
        [ test "EaseInOut at raw 0.5 stays at 0.5 (symmetric)" <|
            \_ ->
                let
                    states =
                        singleState "opacity"
                            (Builder.ProcessedOpacityConfig
                                (mkCfg (Just (Opacity.fromFloat 0)) (Opacity.fromFloat 1) EaseInOut)
                            )
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "opacity", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    |> Expect.equal (Just 0.5)
        , test "EaseIn at raw 0.5 yields value < 0.5 (slow start)" <|
            \_ ->
                let
                    states =
                        singleState "opacity"
                            (Builder.ProcessedOpacityConfig
                                (mkCfg (Just (Opacity.fromFloat 0)) (Opacity.fromFloat 1) EaseIn)
                            )
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "opacity", 0.5 ) ])
                    states
                    PropertyBaselines.empty
                    |> PropertyBaselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    |> Maybe.map (\v -> v < 0.5)
                    |> Expect.equal (Just True)
        ]


startFallbackTests : Test
startFallbackTests =
    describe "start = Nothing falls back to current baseline"
        [ test "uses baseline value as start when config.start is Nothing" <|
            \_ ->
                let
                    states =
                        singleState "opacity"
                            (Builder.ProcessedOpacityConfig
                                (mkCfg Nothing (Opacity.fromFloat 1) Linear)
                            )

                    baseline =
                        PropertyBaselines.setOpacity (Opacity.fromFloat 0.2) PropertyBaselines.empty
                in
                ProgressApply.applyPropertyProgress
                    (Dict.fromList [ ( "opacity", 0.5 ) ])
                    states
                    baseline
                    |> PropertyBaselines.getOpacity
                    |> Maybe.map Opacity.toFloat
                    -- start=0.2 end=1 at t=0.5 → 0.6
                    |> Maybe.withDefault 0
                    |> Expect.within (Expect.Absolute 1.0e-6) 0.6
        ]
