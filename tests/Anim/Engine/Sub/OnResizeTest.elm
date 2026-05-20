module Anim.Engine.Sub.OnResizeTest exposing (suite)

{-| Tests for `onResize`, which mutates an in-flight translate
animation to match a new bounding range. Resize is always proportional:
endpoints adopt the new bounds, the current value is proportionally
remapped, and the normalised timing cursor is preserved.

Animations are stepped via `Sub.update` with `Internal.AnimationFrame` and
queried via `Sub.getTranslateCurrent` / `getTranslateEnd`.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


initialState : Sub.AnimState
initialState =
    Sub.init [ Translate.initXY groupName 0 0 ]


moveX : Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
moveX target =
    Translate.for groupName
        >> Translate.toX target
        >> Translate.duration 1000
        >> Translate.easing Linear
        >> Translate.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


currentX : Sub.AnimState -> Float
currentX state =
    Sub.getTranslateCurrent groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


endX : Sub.AnimState -> Float
endX state =
    Sub.getTranslateEnd groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


{-| Step the animation `n` times by `deltaMs` and return the (min, max)
range of `currentX` values seen across all steps (inclusive of the start).
-}
trackExtrema : Int -> Float -> Sub.AnimState -> ( Float, Float )
trackExtrema n deltaMs initial =
    let
        x0 =
            currentX initial

        go i state acc =
            if i <= 0 then
                acc

            else
                let
                    next =
                        step deltaMs state

                    x =
                        currentX next

                    ( lo, hi ) =
                        acc
                in
                go (i - 1) next ( Basics.min lo x, Basics.max hi x )
    in
    go n initial ( x0, x0 )


within : Float -> Float -> Float -> Expect.Expectation
within tolerance expected actual =
    if abs (expected - actual) <= tolerance then
        Expect.pass

    else
        Expect.fail
            ("Expected "
                ++ String.fromFloat actual
                ++ " to be within "
                ++ String.fromFloat tolerance
                ++ " of "
                ++ String.fromFloat expected
            )


{-| Test-local shim that adapts a 2D-bounds resize call to the builder-based
`Sub.onResize` API. Keeps the rest of the suite readable.
-}
onResize :
    Sub.AnimGroupName
    -> { x : Maybe Resize.AxisBounds, y : Maybe Resize.AxisBounds }
    -> Sub.AnimState
    -> Sub.AnimState
onResize name bounds animState =
    Sub.onResize animState <|
        Translate.bounds name
            { x = bounds.x, y = bounds.y, z = Nothing }


suite : Test
suite =
    describe "Anim.Engine.onResize"
        [ describe "no-op cases"
            [ test "no axes specified leaves state untouched" <|
                \_ ->
                    let
                        before =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        after =
                            onResize groupName
                                { x = Nothing, y = Nothing }
                                before
                    in
                    currentX after
                        |> within 0.001 (currentX before)
            , test "unknown group is a no-op" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        after =
                            onResize "doesNotExist"
                                { x = Just { min = 0, max = 100 }
                                , y = Nothing
                                }
                                state
                    in
                    currentX after
                        |> within 0.001 (currentX state)
            ]
        , describe "Proportional remap"
            [ test "halfway through 0->500 becomes halfway through 0->300" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 500

                        resized =
                            onResize groupName
                                { x = Just { min = 0, max = 300 }
                                , y = Nothing
                                }
                                state
                    in
                    currentX resized
                        |> within 0.5 150
            , test "runtime target maps to new max when traveling forward" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250
                                |> onResize groupName
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }

                        finished =
                            List.foldl (\_ s -> step 50 s) state (List.range 1 200)
                    in
                    currentX finished
                        |> within 0.5 300
            , test "getTranslateEnd reflects the new max immediately" <|
                \_ ->
                    let
                        resized =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250
                                |> onResize groupName
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }
                    in
                    endX resized
                        |> within 0.001 300
            , test "rescaled animation continues to new target over time" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 500
                                |> onResize groupName
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }

                        finished =
                            List.foldl (\_ s -> step 50 s) state (List.range 1 200)
                    in
                    currentX finished
                        |> within 0.5 300
            , test "completed one-shot tracks the new endpoint across successive resizes (regression)" <|
                -- A completed one-shot is "settled at the endpoint" - the
                -- right semantic is to snap `current` to the new endpoint
                -- and preserve the full leg, not collapse `start` to
                -- `current` (which degenerates the Proportional formula on
                -- the next resize and teleports the box back to `b.min`).
                \_ ->
                    let
                        finished =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> (\s -> List.foldl (\_ acc -> step 50 acc) s (List.range 1 60))

                        afterResize1 =
                            onResize groupName
                                { x = Just { min = 0, max = 300 }
                                , y = Nothing
                                }
                                finished

                        afterResize2 =
                            onResize groupName
                                { x = Just { min = 0, max = 350 }
                                , y = Nothing
                                }
                                afterResize1
                    in
                    Expect.all
                        [ \_ -> currentX afterResize1 |> within 0.5 300
                        , \_ -> endX afterResize1 |> within 0.001 300
                        , \_ -> currentX afterResize2 |> within 0.5 350
                        , \_ -> endX afterResize2 |> within 0.001 350
                        ]
                        ()
            ]
        , describe "paused one-shot"
            [ test "preserves the visual position across a resize" <|
                \_ ->
                    let
                        paused =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName

                        before =
                            currentX paused

                        resized =
                            onResize groupName
                                { x = Just { min = 0, max = 500 }
                                , y = Nothing
                                }
                                paused
                    in
                    currentX resized
                        |> within 0.001 before
            , test "does not creep across many sub-pixel resizes (regression)" <|
                \_ ->
                    let
                        paused =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName

                        before =
                            currentX paused

                        resized =
                            List.foldl
                                (\_ s ->
                                    onResize groupName
                                        { x = Just { min = 0, max = 500 }
                                        , y = Nothing
                                        }
                                        s
                                )
                                paused
                                (List.range 1 20)
                    in
                    currentX resized
                        |> within 0.001 before
            , test "scales current proportionally when the leg grows" <|
                \_ ->
                    let
                        paused =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName

                        beforeRatio =
                            currentX paused / 500

                        resized =
                            onResize groupName
                                { x = Just { min = 0, max = 1000 }
                                , y = Nothing
                                }
                                paused
                    in
                    currentX resized
                        |> within 0.5 (beforeRatio * 1000)
            , test "resume after resize completes at the new endpoint" <|
                \_ ->
                    let
                        finished =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName
                                |> onResize groupName
                                    { x = Just { min = 0, max = 1000 }
                                    , y = Nothing
                                    }
                                |> Sub.resume groupName
                                |> (\s -> List.foldl (\_ acc -> step 50 acc) s (List.range 1 200))
                    in
                    Expect.all
                        [ \_ -> currentX finished |> within 0.5 1000
                        , \_ -> endX finished |> within 0.001 1000
                        ]
                        ()
            , test "preserves eased visual position with non-linear easing (regression)" <|
                \_ ->
                    let
                        easedMove : Sub.AnimBuilder mode -> Sub.AnimBuilder mode
                        easedMove =
                            Translate.for groupName
                                >> Translate.toX 500
                                >> Translate.duration 1000
                                >> Translate.easing CubicOut
                                >> Translate.build

                        paused =
                            initialState
                                |> (\s -> Sub.animate s easedMove)
                                |> step 300
                                |> Sub.pause groupName

                        before =
                            currentX paused

                        resized =
                            List.foldl
                                (\_ s ->
                                    onResize groupName
                                        { x = Just { min = 0, max = 500 }
                                        , y = Nothing
                                        }
                                        s
                                )
                                paused
                                (List.range 1 10)
                    in
                    currentX resized
                        |> within 0.001 before
            ]
        , describe "axis selectivity"
            [ test "Y bounds do not affect X" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        before =
                            currentX state

                        resized =
                            onResize groupName
                                { x = Nothing
                                , y = Just { min = 0, max = 50 }
                                }
                                state
                    in
                    currentX resized
                        |> within 0.001 before
            ]
        , describe "non-translate properties are untouched"
            [ test "opacity in the same group is left alone" <|
                \_ ->
                    let
                        state =
                            Sub.init [ Translate.initXY groupName 0 0 ]
                                |> (\s ->
                                        Sub.animate s
                                            (Translate.for groupName
                                                >> Translate.toX 500
                                                >> Translate.duration 1000
                                                >> Translate.build
                                                >> Opacity.for groupName
                                                >> Opacity.to 0.5
                                                >> Opacity.duration 1000
                                                >> Opacity.build
                                            )
                                   )
                                |> step 500

                        opacityBefore =
                            Sub.getOpacityCurrent groupName state

                        resized =
                            onResize groupName
                                { x = Just { min = 0, max = 100 }
                                , y = Nothing
                                }
                                state

                        opacityAfter =
                            Sub.getOpacityCurrent groupName resized
                    in
                    opacityAfter
                        |> Expect.equal opacityBefore
            ]
        , describe "ping-pong (loopForever + alternate)"
            [ let
                pingPong : Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
                pingPong target =
                    Sub.loopForever
                        >> Sub.alternate
                        >> Translate.for groupName
                        >> Translate.toX target
                        >> Translate.duration 1000
                        >> Translate.easing Linear
                        >> Translate.build
              in
              describe "Proportional preserves the full new range across leg boundaries"
                [ test "after resize, the box reaches both new extremes" <|
                    \_ ->
                        let
                            state =
                                initialState
                                    |> (\s -> Sub.animate s (pingPong 500))
                                    |> step 500

                            resized =
                                onResize groupName
                                    { x = Just { min = 0, max = 1000 }
                                    , y = Nothing
                                    }
                                    state

                            ( minSeen, maxSeen ) =
                                trackExtrema 200 20 resized
                        in
                        Expect.all
                            [ \_ -> maxSeen |> within 5 1000
                            , \_ -> minSeen |> within 5 0
                            ]
                            ()
                , test "after resize, leg endpoint scales with the new range" <|
                    \_ ->
                        let
                            state =
                                initialState
                                    |> (\s -> Sub.animate s (pingPong 500))
                                    |> step 500
                                    |> onResize groupName
                                        { x = Just { min = 0, max = 1000 }
                                        , y = Nothing
                                        }
                        in
                        Sub.getTranslateRange groupName state
                            |> Maybe.map .end
                            |> Maybe.map .x
                            |> Maybe.withDefault -1
                            |> within 0.001 1000
                , test "preserves eased visual position with non-linear easing (regression)" <|
                    \_ ->
                        let
                            easedPingPong : Sub.AnimBuilder mode -> Sub.AnimBuilder mode
                            easedPingPong =
                                Sub.loopForever
                                    >> Sub.alternate
                                    >> Translate.for groupName
                                    >> Translate.toX 500
                                    >> Translate.duration 1000
                                    >> Translate.easing CubicOut
                                    >> Translate.build

                            running =
                                initialState
                                    |> (\s -> Sub.animate s easedPingPong)
                                    |> step 300

                            before =
                                currentX running

                            resized =
                                List.foldl
                                    (\_ s ->
                                        onResize groupName
                                            { x = Just { min = 0, max = 500 }
                                            , y = Nothing
                                            }
                                            s
                                    )
                                    running
                                    (List.range 1 10)
                        in
                        currentX resized
                            |> within 0.001 before
                ]
            ]
        , describe "group-wide bounds via Translate.bounds"
            [ test "applies proportional remap when only the group default is set" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 500

                        bounds =
                            { x = Just { min = 0, max = 100 }
                            , y = Nothing
                            , z = Nothing
                            }

                        resized =
                            Sub.onResize state <|
                                Translate.bounds groupName bounds
                    in
                    currentX resized
                        |> within 0.001 50
            ]
        , describe "Translate.position - static-axis snap"
            [ test "snaps a static axis to the requested pixel value" <|
                \_ ->
                    -- The Y axis has never animated (init: (0,0)), so its
                    -- start == end == current == 0. `position` should
                    -- relocate all three to 250.
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        resized =
                            Sub.onResize state <|
                                Translate.position groupName
                                    { x = Nothing
                                    , y = Just 250
                                    , z = Nothing
                                    }

                        actualY =
                            Sub.getTranslateCurrent groupName resized
                                |> Maybe.map .y
                                |> Maybe.withDefault -1
                    in
                    actualY |> within 0.001 250
            , test "snap persists across subsequent interpolation frames" <|
                \_ ->
                    -- Sub recomputes current = interpolate(start, end, t)
                    -- on every frame. A snap that didn't also set start
                    -- and end would be clobbered on the next frame.
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        resized =
                            Sub.onResize state <|
                                Translate.position groupName
                                    { x = Nothing
                                    , y = Just 250
                                    , z = Nothing
                                    }

                        after =
                            resized
                                |> step 50
                                |> step 50
                                |> step 50

                        actualY =
                            Sub.getTranslateCurrent groupName after
                                |> Maybe.map .y
                                |> Maybe.withDefault -1
                    in
                    actualY |> within 0.001 250
            , test "leaves an animating axis untouched (silent no-op)" <|
                \_ ->
                    -- X is animating from 0 -> 500. `position` on X
                    -- must be a no-op; the next interpolation frame
                    -- would otherwise overwrite a current-only nudge.
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        before =
                            currentX state

                        resized =
                            Sub.onResize state <|
                                Translate.position groupName
                                    { x = Just 9999
                                    , y = Nothing
                                    , z = Nothing
                                    }
                    in
                    currentX resized |> within 0.001 before
            , test "Nothing axes are left alone" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        resized =
                            Sub.onResize state <|
                                Translate.position groupName
                                    { x = Nothing
                                    , y = Nothing
                                    , z = Nothing
                                    }
                    in
                    currentX resized |> within 0.001 (currentX state)
            , test "composes with Translate.bounds on the moving axis" <|
                \_ ->
                    -- Mirrors the Perspective3D example: X is animating
                    -- and gets `bounds`-remapped; Y is static at 0 and
                    -- gets snapped to the new edge by `position`.
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        resized =
                            Sub.onResize state <|
                                Translate.bounds groupName
                                    { x = Just { min = 0, max = 1000 }
                                    , y = Nothing
                                    , z = Nothing
                                    }
                                    >> Translate.position groupName
                                        { x = Nothing
                                        , y = Just 800
                                        , z = Nothing
                                        }

                        afterY =
                            Sub.getTranslateCurrent groupName resized
                                |> Maybe.map .y
                                |> Maybe.withDefault -1

                        afterEndX =
                            endX resized
                    in
                    Expect.all
                        [ \_ -> afterY |> within 0.001 800
                        , \_ -> afterEndX |> within 0.001 1000
                        ]
                        ()
            ]
        ]
