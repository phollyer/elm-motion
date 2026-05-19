module Anim.Engine.WAAPI.PerspectiveOriginPolicyAutoApplySpec exposing (suite)

{-| Tests that swapping the resize policy inside `WAAPI.animate` re-applies
the most recent cached perspective-origin bounds immediately, without
requiring another `onResize` event. Mirrors the translate suite in
`Anim.Engine.WAAPI.PolicyAutoApplySpec`.

Cmds emitted by the WAAPI engine are opaque, so these tests only verify
the observable runtime state via `WAAPI.getPerspectiveOriginEnd`.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Resize as Resize
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "card"


type Msg
    = NoOp


fakeCommandPort : Encode.Value -> Cmd Msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> Msg) -> Sub Msg
fakeSubscriptionPort _ =
    Sub.none


initialState : WAAPI.AnimState Msg
initialState =
    WAAPI.init fakeCommandPort
        fakeSubscriptionPort
        [ PerspectiveOrigin.initPercent groupName 0 0 ]


moveX : Float -> WAAPI.AnimBuilder mode -> WAAPI.AnimBuilder mode
moveX target =
    PerspectiveOrigin.for groupName
        >> PerspectiveOrigin.percent
        >> PerspectiveOrigin.toXY target 0
        >> PerspectiveOrigin.duration 1000
        >> PerspectiveOrigin.easing Linear
        >> PerspectiveOrigin.build


animate : (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState Msg -> WAAPI.AnimState Msg
animate config state =
    WAAPI.animate state config
        |> Tuple.first


onResize :
    WAAPI.AnimGroupName
    -> Resize.Policy
    -> { x : Maybe Resize.AxisBounds, y : Maybe Resize.AxisBounds }
    -> WAAPI.AnimState Msg
    -> WAAPI.AnimState Msg
onResize name policy bounds state =
    let
        withPolicy =
            animate (PerspectiveOrigin.resizePolicy name policy) state
    in
    WAAPI.onResize withPolicy
        (PerspectiveOrigin.bounds name
            { x = bounds.x, y = bounds.y, z = Nothing }
        )
        |> Tuple.first


endX : WAAPI.AnimState Msg -> Float
endX state =
    WAAPI.getPerspectiveOriginEnd groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


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


suite : Test
suite =
    describe "WAAPI perspective-origin policy swap mid-animation auto-applies cached bounds"
        [ test "swapping policy while starting a new animation re-applies the most recent bounds" <|
            \_ ->
                let
                    -- Start an animation, fire a resize that caches bounds 0..200,
                    -- then start a new animation to 1000 while swapping policy
                    -- to Clamp. The cached 0..200 bounds should be auto-applied
                    -- under the new policy, clamping endX to 200.
                    afterPolicySwap =
                        initialState
                            |> animate (moveX 500)
                            |> onResize groupName
                                Resize.proportional
                                { x = Just { min = 0, max = 200 }
                                , y = Nothing
                                }
                            |> animate
                                (PerspectiveOrigin.resizePolicy groupName Resize.clamp
                                    >> moveX 1000
                                )
                in
                endX afterPolicySwap
                    |> within 0.001 200
        , test "policy swap before any resize is a silent no-op" <|
            \_ ->
                let
                    -- No `onResize` has fired, so `lastResize` is empty.
                    -- A policy swap paired with a new animation should
                    -- leave the authored end untouched.
                    afterPolicySwap =
                        initialState
                            |> animate
                                (PerspectiveOrigin.resizePolicy groupName Resize.clamp
                                    >> moveX 500
                                )
                in
                endX afterPolicySwap
                    |> within 0.001 500
        , test "policy swap retargets to the most recent of several resize events" <|
            \_ ->
                let
                    afterPolicySwap =
                        initialState
                            |> animate (moveX 500)
                            |> onResize groupName
                                Resize.proportional
                                { x = Just { min = 0, max = 100 }
                                , y = Nothing
                                }
                            |> onResize groupName
                                Resize.proportional
                                { x = Just { min = 0, max = 300 }
                                , y = Nothing
                                }
                            |> animate
                                (PerspectiveOrigin.resizePolicy groupName Resize.clamp
                                    >> moveX 1000
                                )
                in
                endX afterPolicySwap
                    |> within 0.001 300
        ]
