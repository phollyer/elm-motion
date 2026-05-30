module Anim.Engine.WAAPI.TransformOrderSpec exposing (suite)

{-| Tests that `WAAPI.transformOrder` propagates from the public API
through to the internal `AnimBuilder` state, which is what the
WAAPI generator and encoder read when emitting the port payload
for the JS runtime.

The public `WAAPI.animate` call returns an opaque `Cmd msg`, so
direct payload inspection from the public surface isn't possible.
These tests therefore verify the contract at the boundary the public
API actually feeds into — the `AnimBuilder`'s normalized transform
order — using `Anim.Internal.Builder.getTransformOrder`.

Additional end-to-end JSON-payload coverage exists in
`tests/Anim/Internal/Engine/WAAPI/TestAnimGroup.elm` (per-element
order on the `AnimGroup`) and is exercised by the encoder via the
generator on every `WAAPI.animate` call.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Expect
import Test exposing (Test, describe, test)


{-| Apply a builder pipeline to a fresh WAAPI builder, mirroring what
`WAAPI.init` does internally when collecting `propertyInitializers`.
-}
applyBuilder : (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.EngineBuilder
applyBuilder pipeline =
    Builder.init []
        |> pipeline


basePipeline : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
basePipeline =
    Translate.for "el"
        >> Translate.toXY 100 50
        >> Translate.duration 500
        >> Translate.build
        >> Rotate.for "el"
        >> Rotate.toZ 90
        >> Rotate.duration 500
        >> Rotate.build
        >> Scale.for "el"
        >> Scale.toXY 2 2
        >> Scale.duration 500
        >> Scale.build


suite : Test
suite =
    describe "WAAPI.transformOrder (public API)"
        [ propagationTests
        , overrideTests
        ]



-- ============================================================
-- PROPAGATION
-- ============================================================


propagationTests : Test
propagationTests =
    describe "transformOrder propagates to the AnimBuilder"
        [ test "no transformOrder setter leaves order as Nothing (uses engine default)" <|
            \_ ->
                applyBuilder basePipeline
                    |> Builder.getTransformOrder "el"
                    |> Expect.equal Nothing
        , test "[Scale, Rotate, Translate, Skew] is recorded verbatim" <|
            \_ ->
                applyBuilder
                    (WAAPI.transformOrder [ Scale, Rotate, Translate, Skew ]
                        >> basePipeline
                    )
                    |> Builder.getTransformOrder "el"
                    |> Expect.equal (Just [ Scale, Rotate, Translate, Skew ])
        , test "[Rotate, Scale] is normalized to a full ordering" <|
            \_ ->
                -- normalizeTransformOrder appends any missing
                -- TransformProperty values so the runtime always has a
                -- complete order. The first elements of the result must
                -- match the user-supplied prefix.
                applyBuilder
                    (WAAPI.transformOrder [ Rotate, Scale ]
                        >> basePipeline
                    )
                    |> Builder.getTransformOrder "el"
                    |> Maybe.map (List.take 2)
                    |> Expect.equal (Just [ Rotate, Scale ])
        , test "empty list is normalized to the engine default order" <|
            \_ ->
                applyBuilder
                    (WAAPI.transformOrder []
                        >> basePipeline
                    )
                    |> Builder.getTransformOrder "el"
                    |> Maybe.map List.length
                    |> Expect.equal (Just 4)
        ]



-- ============================================================
-- OVERRIDES
-- ============================================================


overrideTests : Test
overrideTests =
    describe "later transformOrder setter overrides earlier ones"
        [ test "second setter wins" <|
            \_ ->
                applyBuilder
                    (WAAPI.transformOrder [ Translate, Rotate, Scale, Skew ]
                        >> WAAPI.transformOrder [ Scale, Skew, Rotate, Translate ]
                        >> basePipeline
                    )
                    |> Builder.getTransformOrder "el"
                    |> Expect.equal (Just [ Scale, Skew, Rotate, Translate ])
        , test "transformOrder is independent of property pipeline order" <|
            \_ ->
                let
                    orderBefore =
                        applyBuilder
                            (WAAPI.transformOrder [ Rotate, Translate, Scale, Skew ]
                                >> basePipeline
                            )
                            |> Builder.getTransformOrder "el"

                    orderAfter =
                        applyBuilder
                            (basePipeline
                                >> WAAPI.transformOrder [ Rotate, Translate, Scale, Skew ]
                            )
                            |> Builder.getTransformOrder "el"
                in
                orderBefore |> Expect.equal orderAfter
        , test "fireAndForget accepts a transformOrder-configured pipeline without crashing" <|
            \_ ->
                let
                    cmd : Cmd ()
                    cmd =
                        WAAPI.fireAndForget (\_ -> Cmd.none)
                            (WAAPI.transformOrder [ Scale, Translate, Rotate, Skew ]
                                >> basePipeline
                            )
                in
                cmd |> always Expect.pass
        ]
