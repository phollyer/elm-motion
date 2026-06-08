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
                        |> (Builder.for "el" >> Opacity.begin >> Opacity.set 0 >> Opacity.end)
                        |> opacityMode
                        |> Expect.equal (Just Builder.Snap)
            , test "to records mode = Animate" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Opacity.begin >> Opacity.to 0 >> Opacity.end)
                        |> opacityMode
                        |> Expect.equal (Just Builder.Animate)
            , test "set after to upgrades mode to Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Opacity.begin
                                >> Opacity.to 0.5
                                >> Opacity.set 0
                                >> Opacity.end
                           )
                        |> opacityMode
                        |> Expect.equal (Just Builder.Snap)
            , test "to after set preserves mode = Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Opacity.begin
                                >> Opacity.set 0
                                >> Opacity.to 0.5
                                >> Opacity.end
                           )
                        |> opacityMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Translate"
            translateMode
            (Builder.for "el" >> Translate.begin >> Translate.setXYZ 1 2 3 >> Translate.end)
            (Builder.for "el" >> Translate.begin >> Translate.toXYZ 1 2 3 >> Translate.end)
        , describe "Translate axis variants"
            [ test "setX records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Translate.begin >> Translate.setX 10 >> Translate.end)
                        |> translateMode
                        |> Expect.equal (Just Builder.Snap)
            , test "setXY records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Translate.begin >> Translate.setXY 1 2 >> Translate.end)
                        |> translateMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Rotate"
            rotateMode
            (Builder.for "el" >> Rotate.begin >> Rotate.setXYZ 10 20 30 >> Rotate.end)
            (Builder.for "el" >> Rotate.begin >> Rotate.toXYZ 10 20 30 >> Rotate.end)
        , describe "Rotate axis variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Rotate.begin >> Rotate.set 45 >> Rotate.end)
                        |> rotateMode
                        |> Expect.equal (Just Builder.Snap)
            , test "setY records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Rotate.begin >> Rotate.setY 90 >> Rotate.end)
                        |> rotateMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Scale"
            scaleMode
            (Builder.for "el" >> Scale.begin >> Scale.setXYZ 1 2 3 >> Scale.end)
            (Builder.for "el" >> Scale.begin >> Scale.toXYZ 1 2 3 >> Scale.end)
        , describe "Scale variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Scale.begin >> Scale.set 2 >> Scale.end)
                        |> scaleMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Skew"
            skewMode
            (Builder.for "el" >> Skew.begin >> Skew.setXY 5 10 >> Skew.end)
            (Builder.for "el" >> Skew.begin >> Skew.toXY 5 10 >> Skew.end)
        , snapAndAnimate "Size"
            sizeMode
            (Builder.for "el" >> Size.begin >> Size.setHW 100 200 >> Size.end)
            (Builder.for "el" >> Size.begin >> Size.toHW 100 200 >> Size.end)
        , describe "Size variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> Size.begin >> Size.set 100 >> Size.end)
                        |> sizeMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "PerspectiveOrigin"
            perspectiveOriginMode
            (Builder.for "el" >> PerspectiveOrigin.begin >> PerspectiveOrigin.setXY 10 20 >> PerspectiveOrigin.end)
            (Builder.for "el" >> PerspectiveOrigin.begin >> PerspectiveOrigin.toXY 10 20 >> PerspectiveOrigin.end)
        , describe "PerspectiveOrigin variants"
            [ test "set (uniform) records Snap" <|
                \_ ->
                    prepared
                        |> (Builder.for "el" >> PerspectiveOrigin.begin >> PerspectiveOrigin.set 50 >> PerspectiveOrigin.end)
                        |> perspectiveOriginMode
                        |> Expect.equal (Just Builder.Snap)
            ]
        , snapAndAnimate "Custom"
            customMode
            (Builder.for "el" >> Custom.begin (Custom.Margin Unit.Px) >> Custom.set 10 >> Custom.end)
            (Builder.for "el" >> Custom.begin (Custom.Margin Unit.Px) >> Custom.to 10 >> Custom.end)
        , snapAndAnimate "CustomColor"
            customColorMode
            (Builder.for "el" >> CustomColor.begin CustomColor.BackgroundColor >> CustomColor.set (Color.rgb 0 0 0) >> CustomColor.end)
            (Builder.for "el" >> CustomColor.begin CustomColor.BackgroundColor >> CustomColor.to (Color.rgb 0 0 0) >> CustomColor.end)
        ]
