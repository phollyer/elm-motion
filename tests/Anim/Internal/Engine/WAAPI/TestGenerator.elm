module Anim.Internal.Engine.WAAPI.TestGenerator exposing (suite)

import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
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


mkCfg : Maybe a -> a -> Builder.ProcessedAnimationConfig a
mkCfg start end =
    { start = start
    , end = end
    , duration = 1000
    , speed = 1
    , distance = 0
    , timing = Duration 1000
    , easing = Linear
    , spring = Nothing
    , cssUnit = unitAxes
    , delay = 0
    }


suite : Test
suite =
    describe "Anim.Internal.Engine.WAAPI.Generator.resolveStartFromSnapshot"
        [ describe "preserves an explicit start"
            [ test "translate" <|
                \_ ->
                    let
                        explicit =
                            Translate.fromRecord { x = 100, y = 0, z = 0 }

                        property =
                            Builder.ProcessedTranslateConfig (mkCfg (Just explicit) (Translate.fromRecord { x = 200, y = 0, z = 0 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setTranslate (Translate.fromRecord { x = 999, y = 0, z = 0 })
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedTranslateConfig cfg ->
                            Expect.equal cfg.start (Just explicit)

                        _ ->
                            Expect.fail "expected ProcessedTranslateConfig"
            , test "opacity" <|
                \_ ->
                    let
                        explicit =
                            Opacity.fromFloat 0.25

                        property =
                            Builder.ProcessedOpacityConfig (mkCfg (Just explicit) (Opacity.fromFloat 1))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setOpacity (Opacity.fromFloat 0.5)
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedOpacityConfig cfg ->
                            Expect.equal cfg.start (Just explicit)

                        _ ->
                            Expect.fail "expected ProcessedOpacityConfig"
            ]
        , describe "fills start from snapshot when Nothing"
            [ test "translate" <|
                \_ ->
                    let
                        snapshotValue =
                            Translate.fromRecord { x = 42, y = 7, z = 0 }

                        property =
                            Builder.ProcessedTranslateConfig (mkCfg Nothing (Translate.fromRecord { x = 200, y = 0, z = 0 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setTranslate snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedTranslateConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedTranslateConfig"
            , test "rotate" <|
                \_ ->
                    let
                        snapshotValue =
                            Rotate.fromRecord { x = 0, y = 45, z = 0 }

                        property =
                            Builder.ProcessedRotateConfig (mkCfg Nothing (Rotate.fromRecord { x = 0, y = 90, z = 0 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setRotate snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedRotateConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedRotateConfig"
            , test "scale" <|
                \_ ->
                    let
                        snapshotValue =
                            Scale.fromRecord { x = 1.5, y = 1.5, z = 1 }

                        property =
                            Builder.ProcessedScaleConfig (mkCfg Nothing (Scale.fromRecord { x = 2, y = 2, z = 1 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setScale snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedScaleConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedScaleConfig"
            , test "skew" <|
                \_ ->
                    let
                        snapshotValue =
                            Skew.fromRecord { x = 5, y = 0 }

                        property =
                            Builder.ProcessedSkewConfig (mkCfg Nothing (Skew.fromRecord { x = 10, y = 0 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setSkew snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedSkewConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedSkewConfig"
            , test "opacity" <|
                \_ ->
                    let
                        snapshotValue =
                            Opacity.fromFloat 0.3

                        property =
                            Builder.ProcessedOpacityConfig (mkCfg Nothing (Opacity.fromFloat 1))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setOpacity snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedOpacityConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedOpacityConfig"
            , test "size" <|
                \_ ->
                    let
                        snapshotValue =
                            Size.fromRecord { width = 100, height = 50 }

                        property =
                            Builder.ProcessedSizeConfig (mkCfg Nothing (Size.fromRecord { width = 200, height = 100 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setSize snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedSizeConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedSizeConfig"
            , test "perspectiveOrigin" <|
                \_ ->
                    let
                        snapshotValue =
                            PerspectiveOrigin.fromRecord { x = 25, y = 75 }

                        property =
                            Builder.ProcessedPerspectiveOriginConfig (mkCfg Nothing (PerspectiveOrigin.fromRecord { x = 50, y = 50 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setPerspectiveOrigin snapshotValue
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedPerspectiveOriginConfig cfg ->
                            Expect.equal cfg.start (Just snapshotValue)

                        _ ->
                            Expect.fail "expected ProcessedPerspectiveOriginConfig"
            , test "custom property" <|
                \_ ->
                    let
                        property =
                            Builder.ProcessedCustomPropertyConfig "border-width" "px" (mkCfg Nothing 10)

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setCustomProperty "border-width" 3 "px"
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedCustomPropertyConfig name unit cfg ->
                            Expect.all
                                [ \() -> Expect.equal name "border-width"
                                , \() -> Expect.equal unit "px"
                                , \() -> Expect.equal cfg.start (Just 3)
                                ]
                                ()

                        _ ->
                            Expect.fail "expected ProcessedCustomPropertyConfig"
            , test "custom color property" <|
                \_ ->
                    let
                        snapshotColor =
                            Color.fromRGBA { r = 255, g = 0, b = 0, a = 1 }

                        property =
                            Builder.ProcessedCustomColorPropertyConfig "background-color"
                                (mkCfg Nothing (Color.fromRGBA { r = 0, g = 0, b = 255, a = 1 }))

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setCustomColorProperty "background-color" snapshotColor
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedCustomColorPropertyConfig name cfg ->
                            Expect.all
                                [ \() -> Expect.equal name "background-color"
                                , \() -> Expect.equal cfg.start (Just snapshotColor)
                                ]
                                ()

                        _ ->
                            Expect.fail "expected ProcessedCustomColorPropertyConfig"
            ]
        , describe "leaves start as Nothing when snapshot has no value"
            [ test "translate with empty snapshot" <|
                \_ ->
                    let
                        property =
                            Builder.ProcessedTranslateConfig (mkCfg Nothing (Translate.fromRecord { x = 200, y = 0, z = 0 }))
                    in
                    case Generator.resolveStartFromSnapshot PropertyBaselines.empty property of
                        Builder.ProcessedTranslateConfig cfg ->
                            Expect.equal cfg.start Nothing

                        _ ->
                            Expect.fail "expected ProcessedTranslateConfig"
            , test "custom property absent from snapshot" <|
                \_ ->
                    let
                        property =
                            Builder.ProcessedCustomPropertyConfig "border-width" "px" (mkCfg Nothing 10)

                        snapshot =
                            PropertyBaselines.empty
                                |> PropertyBaselines.setCustomProperty "other-property" 1 "px"
                    in
                    case Generator.resolveStartFromSnapshot snapshot property of
                        Builder.ProcessedCustomPropertyConfig _ _ cfg ->
                            Expect.equal cfg.start Nothing

                        _ ->
                            Expect.fail "expected ProcessedCustomPropertyConfig"
            ]
        ]
