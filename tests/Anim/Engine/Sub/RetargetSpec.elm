module Anim.Engine.Sub.RetargetSpec exposing (suite)

{-| End-to-end tests for `Sub.retarget`.

`Sub.retarget` snaps the named anim groups to the targets in the build with
no animation. For each touched property the in-flight animation is stopped
and replaced with the snapped target; properties not mentioned in the build
keep running with their existing state. `Translate` retargets per-axis: only
the touched axes snap, untouched axes continue along the existing easing
curve toward their existing end value.

Builder timing fields (`duration`, `delay`, `easing`, `spring`) are accepted
but ignored.

A `Cancelled` event is emitted for every group that was `Running` and is
touched by the build. No `Started` event is emitted.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)



-- ============================================================
-- HELPERS
-- ============================================================


initState : Sub.AnimState
initState =
    Sub.init
        [ Translate.initXY "a" 0 0
        , Translate.initXY "b" 0 0
        , Opacity.init "a" 1
        ]


startTranslate : String -> Float -> Sub.AnimState -> Sub.AnimState
startTranslate groupName target state =
    Sub.animate state <|
        (Translate.for groupName
            >> Translate.toX target
            >> Translate.duration 1000
            >> Translate.easing EaseInOut
            >> Translate.build
        )


snapTranslate : String -> Float -> Sub.AnimState -> Sub.AnimState
snapTranslate groupName target state =
    Sub.retarget state <|
        (Translate.for groupName
            >> Translate.toX target
            >> Translate.build
        )


snapTranslateY : String -> Float -> Sub.AnimState -> Sub.AnimState
snapTranslateY groupName target state =
    Sub.retarget state <|
        (Translate.for groupName
            >> Translate.toY target
            >> Translate.build
        )


drainEvents : Sub.AnimState -> ( Sub.AnimState, List Sub.AnimEvent )
drainEvents state =
    Sub.update (Internal.AnimationFrame 0) state



-- ============================================================
-- SUITE
-- ============================================================


suite : Test
suite =
    describe "Anim.Engine.Sub retarget"
        [ snapSemantics
        , scoping
        , perAxisOtherProperties
        , timingIgnored
        , eventEmission
        ]



-- ============================================================
-- SNAP SEMANTICS
-- ============================================================


snapSemantics : Test
snapSemantics =
    describe "retarget snaps to the new target"
        [ test "current value equals the new target immediately after retarget on a running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "end value equals the new target after retarget on a running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget leaves the group not-running" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just False)
        , test "retarget marks the group complete" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> Sub.isComplete "a"
                    |> Expect.equal (Just True)
        , test "retarget on an idle group also snaps to the target" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget on an idle group leaves the group not-running" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just False)
        , test "a subsequent animate begins from the snapped target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> startTranslate "a" 600
                    |> Sub.getTranslateStart "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        ]



-- ============================================================
-- SCOPING
-- ============================================================


scoping : Test
scoping =
    describe "retarget is scoped to the groups in the build"
        [ test "retarget on group b leaves group a's running animation intact" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just True)
        , test "retarget on group b leaves group a's end value at its animation target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 500)
        , test "retarget on group b snaps only group b" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> Sub.getTranslateCurrent "b"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget leaves untouched properties on the same group still running" <|
            \_ ->
                let
                    startOpacity state =
                        Sub.animate state <|
                            (Opacity.for "a"
                                >> Opacity.to 0
                                >> Opacity.duration 1000
                                >> Opacity.build
                            )
                in
                initState
                    |> startTranslate "a" 500
                    |> startOpacity
                    |> snapTranslate "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just True)
        , test "retarget on Y leaves the in-flight X axis still animating" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.isRunning "a"
                    |> Expect.equal (Just True)
        , test "retarget on Y pins Y on the running translate animation to the new target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .y
                    |> Expect.equal (Just 250)
        , test "retarget on Y leaves the in-flight X end value untouched" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 500)
        , test "retarget on Y sets the translate end Y value to the new target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslateY "a" 250
                    |> Sub.getTranslateEnd "a"
                    |> Maybe.map .y
                    |> Expect.equal (Just 250)
        ]



-- ============================================================
-- TIMING IGNORED
-- ============================================================


timingIgnored : Test
timingIgnored =
    describe "builder timing fields are accepted but ignored"
        [ test "duration set in retarget builder does not delay the snap" <|
            \_ ->
                let
                    snapWithLongDuration =
                        Sub.retarget
                            (startTranslate "a" 500 initState)
                            (Translate.for "a"
                                >> Translate.toX 250
                                >> Translate.duration 10000
                                >> Translate.build
                            )
                in
                snapWithLongDuration
                    |> Sub.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "delay set in retarget builder does not defer the snap" <|
            \_ ->
                let
                    snapWithDelay =
                        Sub.retarget
                            (startTranslate "a" 500 initState)
                            (Translate.for "a"
                                >> Translate.toX 250
                                >> Translate.delay 5000
                                >> Translate.build
                            )
                in
                snapWithDelay
                    |> Sub.isComplete "a"
                    |> Expect.equal (Just True)
        ]



-- ============================================================
-- EVENT EMISSION
-- ============================================================


eventEmission : Test
eventEmission =
    describe "retarget event emission"
        [ test "emits Cancelled for a previously-Running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> drainEvents
                    |> Tuple.first
                    |> snapTranslate "a" 250
                    |> drainEvents
                    |> Tuple.second
                    |> List.filter
                        (\ev ->
                            case ev of
                                Sub.Cancelled name _ ->
                                    name == "a"

                                _ ->
                                    False
                        )
                    |> List.length
                    |> Expect.equal 1
        , test "does not emit Started for the retargeted group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> drainEvents
                    |> Tuple.first
                    |> snapTranslate "a" 250
                    |> drainEvents
                    |> Tuple.second
                    |> List.filter
                        (\ev ->
                            case ev of
                                Sub.Started _ ->
                                    True

                                _ ->
                                    False
                        )
                    |> Expect.equal []
        , test "does not emit Cancelled for an idle retargeted group" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> drainEvents
                    |> Tuple.second
                    |> List.filter
                        (\ev ->
                            case ev of
                                Sub.Cancelled _ _ ->
                                    True

                                _ ->
                                    False
                        )
                    |> Expect.equal []
        ]



-- ============================================================
-- PER-AXIS RETARGET ON OTHER MULTI-DIMENSIONAL PROPERTIES
-- ============================================================


{-| Per-axis retarget continuation must apply to every multi-dimensional
property, not just `Translate`. For each property, animating one axis and
then retargeting a different axis must:

1.  Leave the in-flight axis still animating.
2.  Pin the retargeted axis on the running animation to the new target.
3.  Leave the in-flight axis's end value untouched.
4.  Set the retargeted axis's end value to the new target.

-}
perAxisOtherProperties : Test
perAxisOtherProperties =
    let
        rotateInit =
            Sub.init [ Rotate.initXYZ "a" 0 0 0 ]

        scaleInit =
            Sub.init [ Scale.initXYZ "a" 1 1 1 ]

        skewInit =
            Sub.init [ Skew.initXY "a" 0 0 ]

        perspectiveOriginInit =
            Sub.init [ PerspectiveOrigin.initXY "a" 50 50 ]

        sizeInit =
            Sub.init [ Size.initHW "a" 100 100 ]

        startRotateX state target =
            Sub.animate state
                (Rotate.for "a"
                    >> Rotate.toX target
                    >> Rotate.duration 1000
                    >> Rotate.easing EaseInOut
                    >> Rotate.build
                )

        snapRotateY state target =
            Sub.retarget state
                (Rotate.for "a"
                    >> Rotate.toY target
                    >> Rotate.build
                )

        startScaleX state target =
            Sub.animate state
                (Scale.for "a"
                    >> Scale.toX target
                    >> Scale.duration 1000
                    >> Scale.easing EaseInOut
                    >> Scale.build
                )

        snapScaleY state target =
            Sub.retarget state
                (Scale.for "a"
                    >> Scale.toY target
                    >> Scale.build
                )

        startSkewX state target =
            Sub.animate state
                (Skew.for "a"
                    >> Skew.toX target
                    >> Skew.duration 1000
                    >> Skew.easing EaseInOut
                    >> Skew.build
                )

        snapSkewY state target =
            Sub.retarget state
                (Skew.for "a"
                    >> Skew.toY target
                    >> Skew.build
                )

        startPerspectiveOriginX state target =
            Sub.animate state
                (PerspectiveOrigin.for "a"
                    >> PerspectiveOrigin.toX target
                    >> PerspectiveOrigin.duration 1000
                    >> PerspectiveOrigin.easing EaseInOut
                    >> PerspectiveOrigin.build
                )

        snapPerspectiveOriginY state target =
            Sub.retarget state
                (PerspectiveOrigin.for "a"
                    >> PerspectiveOrigin.toY target
                    >> PerspectiveOrigin.build
                )

        startSizeW state target =
            Sub.animate state
                (Size.for "a"
                    >> Size.toW target
                    >> Size.duration 1000
                    >> Size.easing EaseInOut
                    >> Size.build
                )

        snapSizeH state target =
            Sub.retarget state
                (Size.for "a"
                    >> Size.toH target
                    >> Size.build
                )
    in
    describe "per-axis retarget continuation on other multi-dimensional properties"
        [ describe "Rotate"
            [ test "retarget on Y leaves the in-flight X axis still animating" <|
                \_ ->
                    rotateInit
                        |> (\s -> startRotateX s 360)
                        |> (\s -> snapRotateY s 90)
                        |> Sub.isRunning "a"
                        |> Expect.equal (Just True)
            , test "retarget on Y pins Y on the running rotate animation to the new target" <|
                \_ ->
                    rotateInit
                        |> (\s -> startRotateX s 360)
                        |> (\s -> snapRotateY s 90)
                        |> Sub.getRotateCurrent "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 90)
            , test "retarget on Y leaves the in-flight X end value untouched" <|
                \_ ->
                    rotateInit
                        |> (\s -> startRotateX s 360)
                        |> (\s -> snapRotateY s 90)
                        |> Sub.getRotateEnd "a"
                        |> Maybe.map .x
                        |> Expect.equal (Just 360)
            , test "retarget on Y sets the rotate end Y value to the new target" <|
                \_ ->
                    rotateInit
                        |> (\s -> startRotateX s 360)
                        |> (\s -> snapRotateY s 90)
                        |> Sub.getRotateEnd "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 90)
            ]
        , describe "Scale"
            [ test "retarget on Y leaves the in-flight X axis still animating" <|
                \_ ->
                    scaleInit
                        |> (\s -> startScaleX s 2)
                        |> (\s -> snapScaleY s 0.5)
                        |> Sub.isRunning "a"
                        |> Expect.equal (Just True)
            , test "retarget on Y pins Y on the running scale animation to the new target" <|
                \_ ->
                    scaleInit
                        |> (\s -> startScaleX s 2)
                        |> (\s -> snapScaleY s 0.5)
                        |> Sub.getScaleCurrent "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 0.5)
            , test "retarget on Y leaves the in-flight X end value untouched" <|
                \_ ->
                    scaleInit
                        |> (\s -> startScaleX s 2)
                        |> (\s -> snapScaleY s 0.5)
                        |> Sub.getScaleEnd "a"
                        |> Maybe.map .x
                        |> Expect.equal (Just 2)
            , test "retarget on Y sets the scale end Y value to the new target" <|
                \_ ->
                    scaleInit
                        |> (\s -> startScaleX s 2)
                        |> (\s -> snapScaleY s 0.5)
                        |> Sub.getScaleEnd "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 0.5)
            ]
        , describe "Skew"
            [ test "retarget on Y leaves the in-flight X axis still animating" <|
                \_ ->
                    skewInit
                        |> (\s -> startSkewX s 30)
                        |> (\s -> snapSkewY s 15)
                        |> Sub.isRunning "a"
                        |> Expect.equal (Just True)
            , test "retarget on Y pins Y on the running skew animation to the new target" <|
                \_ ->
                    skewInit
                        |> (\s -> startSkewX s 30)
                        |> (\s -> snapSkewY s 15)
                        |> Sub.getSkewCurrent "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 15)
            , test "retarget on Y leaves the in-flight X end value untouched" <|
                \_ ->
                    skewInit
                        |> (\s -> startSkewX s 30)
                        |> (\s -> snapSkewY s 15)
                        |> Sub.getSkewEnd "a"
                        |> Maybe.map .x
                        |> Expect.equal (Just 30)
            , test "retarget on Y sets the skew end Y value to the new target" <|
                \_ ->
                    skewInit
                        |> (\s -> startSkewX s 30)
                        |> (\s -> snapSkewY s 15)
                        |> Sub.getSkewEnd "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 15)
            ]
        , describe "PerspectiveOrigin"
            [ test "retarget on Y leaves the in-flight X axis still animating" <|
                \_ ->
                    perspectiveOriginInit
                        |> (\s -> startPerspectiveOriginX s 100)
                        |> (\s -> snapPerspectiveOriginY s 25)
                        |> Sub.isRunning "a"
                        |> Expect.equal (Just True)
            , test "retarget on Y pins Y on the running perspective-origin animation to the new target" <|
                \_ ->
                    perspectiveOriginInit
                        |> (\s -> startPerspectiveOriginX s 100)
                        |> (\s -> snapPerspectiveOriginY s 25)
                        |> Sub.getPerspectiveOriginCurrent "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 25)
            , test "retarget on Y leaves the in-flight X end value untouched" <|
                \_ ->
                    perspectiveOriginInit
                        |> (\s -> startPerspectiveOriginX s 100)
                        |> (\s -> snapPerspectiveOriginY s 25)
                        |> Sub.getPerspectiveOriginEnd "a"
                        |> Maybe.map .x
                        |> Expect.equal (Just 100)
            , test "retarget on Y sets the perspective-origin end Y value to the new target" <|
                \_ ->
                    perspectiveOriginInit
                        |> (\s -> startPerspectiveOriginX s 100)
                        |> (\s -> snapPerspectiveOriginY s 25)
                        |> Sub.getPerspectiveOriginEnd "a"
                        |> Maybe.map .y
                        |> Expect.equal (Just 25)
            ]
        , describe "Size"
            [ test "retarget on H leaves the in-flight W axis still animating" <|
                \_ ->
                    sizeInit
                        |> (\s -> startSizeW s 300)
                        |> (\s -> snapSizeH s 50)
                        |> Sub.isRunning "a"
                        |> Expect.equal (Just True)
            , test "retarget on H pins H on the running size animation to the new target" <|
                \_ ->
                    sizeInit
                        |> (\s -> startSizeW s 300)
                        |> (\s -> snapSizeH s 50)
                        |> Sub.getSizeCurrent "a"
                        |> Maybe.map .height
                        |> Expect.equal (Just 50)
            , test "retarget on H leaves the in-flight W end value untouched" <|
                \_ ->
                    sizeInit
                        |> (\s -> startSizeW s 300)
                        |> (\s -> snapSizeH s 50)
                        |> Sub.getSizeEnd "a"
                        |> Maybe.map .width
                        |> Expect.equal (Just 300)
            , test "retarget on H sets the size end H value to the new target" <|
                \_ ->
                    sizeInit
                        |> (\s -> startSizeW s 300)
                        |> (\s -> snapSizeH s 50)
                        |> Sub.getSizeEnd "a"
                        |> Maybe.map .height
                        |> Expect.equal (Just 50)
            ]
        ]
