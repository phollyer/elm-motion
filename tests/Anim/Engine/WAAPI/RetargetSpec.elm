module Anim.Engine.WAAPI.RetargetSpec exposing (suite)

{-| End-to-end tests for `WAAPI.retarget` Elm-side semantics.

`WAAPI.retarget` snaps the named anim groups to the targets in the build with
no animation. Builder timing fields (`duration`, `delay`, `easing`, `spring`)
are accepted but ignored.

JS-side behaviour (cancelling the in-flight WAAPI animation, writing the
inline style, and emitting the `cancelled` lifecycle event) is exercised in
the Vitest suite — these tests cover only the state mutation that happens
inside Elm.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Dict
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)



-- ============================================================
-- HELPERS
-- ============================================================


fakeCommandPort : Encode.Value -> Cmd msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> msg) -> Sub msg
fakeSubscriptionPort _ =
    Sub.none


initState : WAAPI.AnimState msg
initState =
    WAAPI.init fakeCommandPort
        fakeSubscriptionPort
        [ Translate.initXY "a" 0 0
        , Translate.initXY "b" 0 0
        , Opacity.init "a" 1
        ]


startTranslate : String -> Float -> WAAPI.AnimState msg -> WAAPI.AnimState msg
startTranslate groupName target state =
    WAAPI.animate state
        (Translate.for groupName
            >> Translate.toX target
            >> Translate.duration 1000
            >> Translate.easing EaseInOut
            >> Translate.build
        )
        |> Tuple.first


snapTranslate : String -> Float -> WAAPI.AnimState msg -> WAAPI.AnimState msg
snapTranslate groupName target state =
    WAAPI.retarget state
        (Translate.for groupName
            >> Translate.toX target
            >> Translate.build
        )
        |> Tuple.first



-- ============================================================
-- SUITE
-- ============================================================


suite : Test
suite =
    describe "Anim.Engine.WAAPI retarget"
        [ snapSemantics
        , scoping
        , timingIgnored
        , encoderPayload
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
                    |> WAAPI.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "end value equals the new target after retarget on a running group" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> WAAPI.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget leaves the group not-complete before snap" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> WAAPI.isComplete "a"
                    |> Expect.equal (Just False)
        , test "retarget marks the group complete" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> WAAPI.isComplete "a"
                    |> Expect.equal (Just True)
        , test "retarget on an idle group also snaps to the target" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> WAAPI.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget on an idle group leaves the group complete" <|
            \_ ->
                initState
                    |> snapTranslate "a" 250
                    |> WAAPI.isComplete "a"
                    |> Expect.equal (Just True)
        , test "a subsequent animate begins from the snapped target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "a" 250
                    |> startTranslate "a" 600
                    |> WAAPI.getTranslateStart "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        ]



-- ============================================================
-- SCOPING
-- ============================================================


scoping : Test
scoping =
    describe "retarget is scoped to the groups in the build"
        [ test "retarget on group b leaves group a's animation un-completed" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> WAAPI.isComplete "a"
                    |> Expect.equal (Just False)
        , test "retarget on group b leaves group a's end value at its animation target" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> WAAPI.getTranslateEnd "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 500)
        , test "retarget on group b snaps only group b" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> snapTranslate "b" 250
                    |> WAAPI.getTranslateCurrent "b"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "retarget on Y preserves the in-flight X end value in the snapshot" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> (\state ->
                            WAAPI.retarget state
                                (Translate.for "a"
                                    >> Translate.toY 250
                                    >> Translate.build
                                )
                                |> Tuple.first
                       )
                    |> WAAPI.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 500)
        , test "retarget on Y snaps Y to the new target in the snapshot" <|
            \_ ->
                initState
                    |> startTranslate "a" 500
                    |> (\state ->
                            WAAPI.retarget state
                                (Translate.for "a"
                                    >> Translate.toY 250
                                    >> Translate.build
                                )
                                |> Tuple.first
                       )
                    |> WAAPI.getTranslateCurrent "a"
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
                        WAAPI.retarget
                            (startTranslate "a" 500 initState)
                            (Translate.for "a"
                                >> Translate.toX 250
                                >> Translate.duration 10000
                                >> Translate.build
                            )
                            |> Tuple.first
                in
                snapWithLongDuration
                    |> WAAPI.getTranslateCurrent "a"
                    |> Maybe.map .x
                    |> Expect.equal (Just 250)
        , test "delay set in retarget builder does not defer the snap" <|
            \_ ->
                let
                    snapWithDelay =
                        WAAPI.retarget
                            (startTranslate "a" 500 initState)
                            (Translate.for "a"
                                >> Translate.toX 250
                                >> Translate.delay 5000
                                >> Translate.build
                            )
                            |> Tuple.first
                in
                snapWithDelay
                    |> WAAPI.isComplete "a"
                    |> Expect.equal (Just True)
        ]



-- ============================================================
-- ENCODER PAYLOAD
-- ============================================================


encoderPayload : Test
encoderPayload =
    describe "encodeRetarget emits a snap-flavoured payload"
        [ test "type field is \"retarget\"" <|
            \_ ->
                let
                    processed =
                        translateProcessed "a" 250

                    json =
                        Encoder.encodeRetarget
                            (animGroupsFor "a")
                            Dict.empty
                            Dict.empty
                            processed
                            |> Encode.encode 0
                in
                json
                    |> Decode.decodeString (Decode.field "type" Decode.string)
                    |> Expect.equal (Ok "retarget")
        , test "elements field carries the touched group" <|
            \_ ->
                let
                    processed =
                        translateProcessed "a" 250

                    json =
                        Encoder.encodeRetarget
                            (animGroupsFor "a")
                            Dict.empty
                            Dict.empty
                            processed
                            |> Encode.encode 0
                in
                json
                    |> Decode.decodeString (Decode.field "elements" (Decode.keyValuePairs Decode.value) |> Decode.map (List.map Tuple.first))
                    |> Expect.equal (Ok [ "a" ])
        ]


animGroupsFor : String -> AnimGroups.AnimGroups AnimGroup.AnimGroup
animGroupsFor name =
    AnimGroups.init
        |> AnimGroups.insert name AnimGroup.init


translateProcessed : String -> Float -> Builder.ProcessedAnimationData
translateProcessed groupName target =
    Builder.init
        [ Translate.for groupName
            >> Translate.toX target
            >> Translate.duration 500
            >> Translate.build
        ]
        |> Builder.process
