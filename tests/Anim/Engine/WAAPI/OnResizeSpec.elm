module Anim.Engine.WAAPI.OnResizeSpec exposing (suite)

{-| Tests for the WAAPI engine `onResize` plumbing.

Two layers are exercised here:

1.  `Anim.Internal.Resize.Builder.applyAxis` - the per-axis math
    that drives both the Sub and WAAPI engines (always proportional).
2.  `Anim.Internal.Engine.WAAPI.Encoder.encodeResize` - the JSON shape
    sent over the `motionCmd` port to the JS handler.

The full pipeline (state -> `WAAPI.onResize` -> `Cmd msg`) cannot be
inspected directly because Elm `Cmd`s are opaque; instead the JS handler
exercises the consumer side via the Vitest suite.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI as WAAPI
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Resize.Builder as ResizeBuilder
import Expect
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI onResize"
        [ resizeMathTests
        , proportionFromProgressTests
        , currentTimeForResizeTests
        , encoderTests
        , translatePositionEncoderTests
        ]



-- ============================================================
-- SHARED RESIZE MATH
-- ============================================================


resizeMathTests : Test
resizeMathTests =
    describe "Resize.applyAxis (proportional)"
        [ test "Nothing bounds leaves axis untouched" <|
            \_ ->
                ResizeBuilder.applyAxis True Nothing Nothing 0 200 100
                    |> Expect.equal { start = 0, end = 200, current = 100 }
        , test "Looping preserves normalized progress" <|
            \_ ->
                -- old leg [0, 200], current 100 -> halfway
                -- new leg [0, 400], halfway -> 200
                ResizeBuilder.applyAxis
                    True
                    Nothing
                    (Just { min = 0, max = 400 })
                    0
                    200
                    100
                    |> Expect.equal { start = 0, end = 400, current = 200 }
        , test "Reverse leg keeps direction" <|
            \_ ->
                -- old leg [200, 0] (reverse), current 50 -> 75% to end
                -- new leg [400, 0] reverse -> 75% -> 100
                ResizeBuilder.applyAxis
                    True
                    Nothing
                    (Just { min = 0, max = 400 })
                    200
                    0
                    50
                    |> Expect.equal { start = 400, end = 0, current = 100 }
        , test "One-shot collapses to remaining leg" <|
            \_ ->
                -- not looping -> start becomes current; end becomes new max
                ResizeBuilder.applyAxis
                    False
                    Nothing
                    (Just { min = 0, max = 400 })
                    0
                    200
                    100
                    |> Expect.equal { start = 200, end = 400, current = 200 }
        , test "Zero old range preserves current (clamped into new bounds)" <|
            -- When start == end the leg has collapsed (e.g. a previous resize
            -- on a finished one-shot animation, or an init-only property
            -- whose synthesized baseline has start == end == current).
            -- There is no proportional position left to preserve, so collapse
            -- the leg to `current` clamped into the new bounds.
            \_ ->
                ResizeBuilder.applyAxis
                    True
                    Nothing
                    (Just { min = 50, max = 250 })
                    100
                    100
                    100
                    |> Expect.equal { start = 100, end = 100, current = 100 }
        , test "Zero old range clamps an out-of-range current into new bounds" <|
            \_ ->
                ResizeBuilder.applyAxis
                    False
                    Nothing
                    (Just { min = 0, max = 100 })
                    300
                    300
                    300
                    |> Expect.equal { start = 100, end = 100, current = 100 }
        , test "Successive one-shot resizes remap current against previous bounds, not the chopped leg" <|
            -- Regression for the bounds-reference bug: after a one-shot resize
            -- chops the leg to (newCurrent, legEnd), the next resize must use
            -- the *previous viewport bounds* as the reference range, not the
            -- (now shrunken) leg endpoints. Without `previousBounds`, the
            -- second resize would interpret the small remaining leg as the
            -- full viewport range and snap the box near `b.min`.
            \_ ->
                let
                    -- First resize: viewport [0..290], box mid-leg at x=248
                    -- (about 85% across the viewport). Old leg endpoints
                    -- (247, 290) - already a chopped post-resize leg, NOT
                    -- spanning the full prior viewport.
                    --
                    -- Without prev bounds: oldRange = 290-247 = 43;
                    --   newCurrent = 0 + ((248-247)/43)*580 ~= 13 (BUG)
                    --
                    -- With prev bounds {0,290}: oldRange = 290;
                    --   newCurrent = 0 + (248/290)*580 ~= 496 (CORRECT)
                    result =
                        ResizeBuilder.applyAxis
                            False
                            (Just { min = 0, max = 290 })
                            (Just { min = 0, max = 580 })
                            247
                            290
                            248
                in
                Expect.all
                    [ \r -> r.current |> Expect.within (Expect.Absolute 1.0) 496
                    , \r -> r.end |> Expect.equal 580
                    ]
                    result
        ]



-- ============================================================
-- PROPORTION FROM PROGRESS
-- ============================================================


proportionFromProgressTests : Test
proportionFromProgressTests =
    describe "WAAPI.proportionFromProgress"
        [ test "forward-aligned axis on normal direction returns progress" <|
            \_ ->
                WAAPI.proportionFromProgress Builder.Normal 0 0.3 0 200
                    |> Expect.equal (Just 0.3)
        , test "forward-aligned axis on first alternate iter returns progress" <|
            \_ ->
                WAAPI.proportionFromProgress Builder.Alternate 0 0.25 0 200
                    |> Expect.equal (Just 0.25)
        , test "forward-aligned axis on second alternate iter (reverse leg) returns 1 - progress" <|
            \_ ->
                WAAPI.proportionFromProgress Builder.Alternate 1 0.25 0 200
                    |> Expect.equal (Just 0.75)
        , test "reverse-aligned axis on normal direction returns 1 - progress" <|
            \_ ->
                WAAPI.proportionFromProgress Builder.Normal 0 0.3 200 0
                    |> Expect.equal (Just 0.7)
        , test "reverse-aligned axis on second alternate iter returns progress" <|
            \_ ->
                WAAPI.proportionFromProgress Builder.Alternate 1 0.3 200 0
                    |> Expect.equal (Just 0.3)
        , test "degenerate leg (start == end) returns Nothing" <|
            \_ ->
                WAAPI.proportionFromProgress Builder.Normal 0 0.5 100 100
                    |> Expect.equal Nothing
        , test "round-trip from progress + new bounds is exact" <|
            -- Bug 4 regression: a paused mid-flight animation that is
            -- resized N times must land on the same absolute position the
            -- proportion predicts, with no compounding error.
            \_ ->
                let
                    progress =
                        0.5

                    p =
                        WAAPI.proportionFromProgress Builder.Alternate 0 progress 0 200

                    boundsCycle =
                        List.repeat 10 ( { min = 0, max = 400 }, { min = 0, max = 200 } )

                    expectedAtWide =
                        Just 200

                    expectedAtNarrow =
                        Just 100

                    positionAt bounds =
                        p |> Maybe.map (\pp -> bounds.min + pp * (bounds.max - bounds.min))
                in
                boundsCycle
                    |> List.concatMap (\( a, b ) -> [ positionAt a, positionAt b ])
                    |> Expect.equal
                        (List.concat
                            (List.repeat 10 [ expectedAtWide, expectedAtNarrow ])
                        )
        ]



-- ============================================================
-- RESIZE CURRENT-TIME
-- ============================================================


currentTimeForResizeTests : Test
currentTimeForResizeTests =
    describe "WAAPI.currentTimeForResize"
        [ test "collapsed one-shot restarts at leg start when still in-flight" <|
            \_ ->
                WAAPI.currentTimeForResize
                    { isLooping = False
                    , treatAsSettled = False
                    , isComplete = False
                    , durationMs = 640
                    , currentIteration = 0
                    , progress = 0.2
                    , isCollapsedOneShot = True
                    }
                    |> Expect.equal (Just 0)
        , test "collapsed settled one-shot seeks to duration" <|
            \_ ->
                WAAPI.currentTimeForResize
                    { isLooping = False
                    , treatAsSettled = True
                    , isComplete = False
                    , durationMs = 640
                    , currentIteration = 0
                    , progress = 0.2
                    , isCollapsedOneShot = True
                    }
                    |> Expect.equal (Just 640)
        , test "looping preserves iteration offset" <|
            \_ ->
                WAAPI.currentTimeForResize
                    { isLooping = True
                    , treatAsSettled = False
                    , isComplete = False
                    , durationMs = 1000
                    , currentIteration = 2
                    , progress = 0.25
                    , isCollapsedOneShot = False
                    }
                    |> Expect.equal (Just 2250)
        , test "paused settled one-shot uses in-leg progress" <|
            \_ ->
                WAAPI.currentTimeForResize
                    { isLooping = False
                    , treatAsSettled = True
                    , isComplete = False
                    , durationMs = 900
                    , currentIteration = 0
                    , progress = 0.5
                    , isCollapsedOneShot = False
                    }
                    |> Expect.equal (Just 450)
        ]



-- ============================================================
-- ENCODER
-- ============================================================


encoderTests : Test
encoderTests =
    describe "Encoder.encodeResize"
        [ test "emits the expected JSON shape with explicit currentTimeMs" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "box"
                    , property = "translate"
                    , start = { x = 0, y = 0, z = 0 }
                    , end = { x = 400, y = 0, z = 0 }
                    , current = { x = 100, y = 0, z = 0 }
                    , durationMs = 1000
                    , currentTimeMs = Just 250
                    , hasAnimationBaseline = True
                    , unit = Nothing
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"box\""
                            ++ ",\"animGroup\":\"box\""
                            ++ ",\"property\":\"translate\""
                            ++ ",\"startX\":0,\"startY\":0,\"startZ\":0"
                            ++ ",\"endX\":400,\"endY\":0,\"endZ\":0"
                            ++ ",\"currentX\":100,\"currentY\":0,\"currentZ\":0"
                            ++ ",\"duration\":1000"
                            ++ ",\"hasAnimationBaseline\":true"
                            ++ ",\"currentTimeMs\":250}"
                        )
        , test "encodes non-zero start/end on all three axes and null currentTimeMs" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "el"
                    , property = "translate"
                    , start = { x = 1, y = 2, z = 3 }
                    , end = { x = 4, y = 5, z = 6 }
                    , current = { x = 7, y = 8, z = 9 }
                    , durationMs = 250
                    , currentTimeMs = Nothing
                    , hasAnimationBaseline = True
                    , unit = Nothing
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"el\""
                            ++ ",\"animGroup\":\"el\""
                            ++ ",\"property\":\"translate\""
                            ++ ",\"startX\":1,\"startY\":2,\"startZ\":3"
                            ++ ",\"endX\":4,\"endY\":5,\"endZ\":6"
                            ++ ",\"currentX\":7,\"currentY\":8,\"currentZ\":9"
                            ++ ",\"duration\":250"
                            ++ ",\"hasAnimationBaseline\":true"
                            ++ ",\"currentTimeMs\":null}"
                        )
        , test "emits property=scale when targeting the scale slot" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "cube"
                    , property = "scale"
                    , start = { x = 1, y = 1, z = 1 }
                    , end = { x = 2, y = 1, z = 1 }
                    , current = { x = 1.25, y = 1, z = 1 }
                    , durationMs = 1000
                    , currentTimeMs = Just 250
                    , hasAnimationBaseline = False
                    , unit = Nothing
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"cube\""
                            ++ ",\"animGroup\":\"cube\""
                            ++ ",\"property\":\"scale\""
                            ++ ",\"startX\":1,\"startY\":1,\"startZ\":1"
                            ++ ",\"endX\":2,\"endY\":1,\"endZ\":1"
                            ++ ",\"currentX\":1.25,\"currentY\":1,\"currentZ\":1"
                            ++ ",\"duration\":1000"
                            ++ ",\"hasAnimationBaseline\":false"
                            ++ ",\"currentTimeMs\":250}"
                        )
        , test "includes unit when provided (perspective-origin resize)" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "cube"
                    , property = "perspectiveOrigin"
                    , start = { x = 0, y = 0, z = 0 }
                    , end = { x = 400, y = 300, z = 0 }
                    , current = { x = 100, y = 75, z = 0 }
                    , durationMs = 1000
                    , currentTimeMs = Just 250
                    , hasAnimationBaseline = True
                    , unit = Just "px"
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"cube\""
                            ++ ",\"animGroup\":\"cube\""
                            ++ ",\"property\":\"perspectiveOrigin\""
                            ++ ",\"startX\":0,\"startY\":0,\"startZ\":0"
                            ++ ",\"endX\":400,\"endY\":300,\"endZ\":0"
                            ++ ",\"currentX\":100,\"currentY\":75,\"currentZ\":0"
                            ++ ",\"duration\":1000"
                            ++ ",\"hasAnimationBaseline\":true"
                            ++ ",\"currentTimeMs\":250"
                            ++ ",\"unit\":\"px\"}"
                        )
        ]



-- ============================================================
-- TRANSLATE POSITION ENCODER
-- ============================================================


translatePositionEncoderTests : Test
translatePositionEncoderTests =
    describe "Encoder.encodeTranslatePosition"
        [ test "emits all axes when every axis has a value" <|
            \_ ->
                Encoder.encodeTranslatePosition
                    { animGroupName = "box"
                    , x = Just 100
                    , y = Just 200
                    , z = Just 0
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"translatePosition\""
                            ++ ",\"elementId\":\"box\""
                            ++ ",\"animGroup\":\"box\""
                            ++ ",\"x\":100,\"y\":200,\"z\":0}"
                        )
        , test "emits null for axes left untouched" <|
            \_ ->
                Encoder.encodeTranslatePosition
                    { animGroupName = "el"
                    , x = Nothing
                    , y = Just 250
                    , z = Nothing
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"translatePosition\""
                            ++ ",\"elementId\":\"el\""
                            ++ ",\"animGroup\":\"el\""
                            ++ ",\"x\":null,\"y\":250,\"z\":null}"
                        )
        , test "emits null for every axis when all are Nothing" <|
            \_ ->
                Encoder.encodeTranslatePosition
                    { animGroupName = "empty"
                    , x = Nothing
                    , y = Nothing
                    , z = Nothing
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"translatePosition\""
                            ++ ",\"elementId\":\"empty\""
                            ++ ",\"animGroup\":\"empty\""
                            ++ ",\"x\":null,\"y\":null,\"z\":null}"
                        )
        ]
