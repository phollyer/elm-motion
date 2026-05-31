module Anim.Property.SetSpec exposing (suite)

import Anim.Extra.Color as Color
import Anim.Internal.Builder as Builder
import Anim.Property.Custom as Custom
import Anim.Property.CustomColor as CustomColor
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit as Unit
import Expect
import Test exposing (..)


type alias TestMode =
    { withTiming : ()
    , withSpring : ()
    , withLoopForever : ()
    , withIterations : ()
    , withAlternate : ()
    , withTransformOrder : ()
    , withProgressEvents : ()
    }


animBuilder : Builder.AnimBuilder TestMode
animBuilder =
    Builder.init []


prepared : Builder.AnimBuilder TestMode
prepared =
    animBuilder |> Builder.for "el"


modeFor : (Builder.PropertyConfig -> Maybe Builder.AnimationMode) -> Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
modeFor extract builder =
    (Builder.getCurrentAnimGroupConfig builder).properties
        |> List.filterMap extract
        |> List.head


opacityMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
opacityMode =
    modeFor
        (\p ->
            case p of
                Builder.OpacityConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


translateMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
translateMode =
    modeFor
        (\p ->
            case p of
                Builder.TranslateConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


rotateMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
rotateMode =
    modeFor
        (\p ->
            case p of
                Builder.RotateConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


scaleMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
scaleMode =
    modeFor
        (\p ->
            case p of
                Builder.ScaleConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


skewMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
skewMode =
    modeFor
        (\p ->
            case p of
                Builder.SkewConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


sizeMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
sizeMode =
    modeFor
        (\p ->
            case p of
                Builder.SizeConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


perspectiveOriginMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
perspectiveOriginMode =
    modeFor
        (\p ->
            case p of
                Builder.PerspectiveOriginConfig cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


customMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
customMode =
    modeFor
        (\p ->
            case p of
                Builder.CustomPropertyConfig _ _ cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


customColorMode : Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode
customColorMode =
    modeFor
        (\p ->
            case p of
                Builder.CustomColorPropertyConfig _ cfg ->
                    Just cfg.mode

                _ ->
                    Nothing
        )


snapAndAnimate : String -> (Builder.AnimBuilder TestMode -> Maybe Builder.AnimationMode) -> (Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode) -> (Builder.AnimBuilder TestMode -> Builder.AnimBuilder TestMode) -> Test
snapAndAnimate label extract snapPipe toPipe =
    describe label
        [ test "set records mode = Snap" <|
            \_ ->
                prepared
                    |> snapPipe
                    |> extract
                    |> Expect.equal (Just Builder.Snap)
        , test "to records mode = Animate" <|
            \_ ->
                prepared
                    |> toPipe
                    |> extract
                    |> Expect.equal (Just Builder.Animate)
        ]


suite : Test
suite =
    describe "Anim.Property set"
        [ describe "Opacity"
            [ test "set records mode = Snap" <|
                \_ ->
                    prepared
                        |> (Opacity.for "el" >> Opacity.set 0 >> Opacity.build)
                        |> opacityMode
                        |> Expect.equal (Just Builder.Snap)
            , test "to records mode = Animate" <|
                \_ ->
                    prepared
                        |> (Opacity.for "el" >> Opacity.to 0 >> Opacity.build)
                        |> opacityMode
                        |> Expect.equal (Just Builder.Animate)
            , test "set after to upgrades mode to Snap" <|
                \_ ->
                    prepared
                        |> (Opacity.for "el"
                                >> Opacity.to 0.5
                                >> Opacity.set 0
                                >> Opacity.build
                           )
                        |> opacityMode
                        |> Expect.equal (Just Builder.Snap)
            , test "to after set preserves mode = Snap" <|
                \_ ->
                    prepared
                        |> (Opacity.for "el"
                                >> Opacity.set 0
                                >> Opacity.to 0.5
                                >> Opacity.build
                           )
                        |> opacityMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Translate"
            translateMode
            (Translate.for "el" >> Translate.setXYZ 1 2 3 >> Translate.build)
            (Translate.for "el" >> Translate.toXYZ 1 2 3 >> Translate.build)
        , describe "Translate axis variants"
            [ test "setX records Snap" <|
                \_ ->
                    prepared
                        |> (Translate.for "el" >> Translate.setX 10 >> Translate.build)
                        |> translateMode
                        |> Expect.equal (Just Builder.Snap)
            , test "setXY records Snap" <|
                \_ ->
                    prepared
                        |> (Translate.for "el" >> Translate.setXY 1 2 >> Translate.build)
                        |> translateMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Rotate"
            rotateMode
            (Rotate.for "el" >> Rotate.setXYZ 10 20 30 >> Rotate.build)
            (Rotate.for "el" >> Rotate.toXYZ 10 20 30 >> Rotate.build)
        , describe "Rotate axis variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Rotate.for "el" >> Rotate.set 45 >> Rotate.build)
                        |> rotateMode
                        |> Expect.equal (Just Builder.Snap)
            , test "setY records Snap" <|
                \_ ->
                    prepared
                        |> (Rotate.for "el" >> Rotate.setY 90 >> Rotate.build)
                        |> rotateMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Scale"
            scaleMode
            (Scale.for "el" >> Scale.setXYZ 1 2 3 >> Scale.build)
            (Scale.for "el" >> Scale.toXYZ 1 2 3 >> Scale.build)
        , describe "Scale variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Scale.for "el" >> Scale.set 2 >> Scale.build)
                        |> scaleMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Skew"
            skewMode
            (Skew.for "el" >> Skew.setXY 5 10 >> Skew.build)
            (Skew.for "el" >> Skew.toXY 5 10 >> Skew.build)
        , snapAndAnimate "Size"
            sizeMode
            (Size.for "el" >> Size.setHW 100 200 >> Size.build)
            (Size.for "el" >> Size.toHW 100 200 >> Size.build)
        , describe "Size variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Size.for "el" >> Size.set 100 >> Size.build)
                        |> sizeMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "PerspectiveOrigin"
            perspectiveOriginMode
            (PerspectiveOrigin.for "el" >> PerspectiveOrigin.setXY 10 20 >> PerspectiveOrigin.build)
            (PerspectiveOrigin.for "el" >> PerspectiveOrigin.toXY 10 20 >> PerspectiveOrigin.build)
        , describe "PerspectiveOrigin variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (PerspectiveOrigin.for "el" >> PerspectiveOrigin.set 50 >> PerspectiveOrigin.build)
                        |> perspectiveOriginMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Custom"
            customMode
            (Custom.for "el" (Custom.Margin Unit.Px) >> Custom.set 10 >> Custom.build)
            (Custom.for "el" (Custom.Margin Unit.Px) >> Custom.to 10 >> Custom.build)
        , snapAndAnimate "CustomColor"
            customColorMode
            (CustomColor.for "el" CustomColor.BackgroundColor >> CustomColor.set (Color.rgb 0 0 0) >> CustomColor.build)
            (CustomColor.for "el" CustomColor.BackgroundColor >> CustomColor.to (Color.rgb 0 0 0) >> CustomColor.build)
        ]
