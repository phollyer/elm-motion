module Anim.Engine.WAAPI.TestProgressEvents exposing (suite)

import Anim.Engine.WAAPI as WAAPI
import Anim.Internal.Engine.WAAPI as WAAPIInternal
import Anim.Property.Opacity as Opacity
import Expect
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.WAAPI withProgressEvents"
        [ test "update returns Nothing for propertyUpdate by default" <|
            \_ ->
                let
                    animState =
                        WAAPI.init dummyCmd dummySub []

                    ( _, maybeEvent ) =
                        WAAPI.update (propertyUpdateMsg "box" 0.42) animState
                in
                Expect.equal Nothing maybeEvent
        , test "update returns Just Progress when withProgressEvents True" <|
            \_ ->
                let
                    animState =
                        WAAPI.init dummyCmd dummySub [ WAAPI.withProgressEvents True ]

                    ( _, maybeEvent ) =
                        WAAPI.update (propertyUpdateMsg "box" 0.42) animState
                in
                Expect.equal (Just (WAAPI.Progress "box" 0.42)) maybeEvent
        , test "withProgressEvents False keeps Progress events suppressed" <|
            \_ ->
                let
                    animState =
                        WAAPI.init dummyCmd dummySub [ WAAPI.withProgressEvents False ]

                    ( _, maybeEvent ) =
                        WAAPI.update (propertyUpdateMsg "box" 0.42) animState
                in
                Expect.equal Nothing maybeEvent
        , test "group override True emits Progress when global default is False" <|
            \_ ->
                let
                    initialState =
                        WAAPI.init dummyCmd dummySub [ WAAPI.withProgressEvents False ]

                    ( animState, _ ) =
                        WAAPI.animate initialState
                            (WAAPI.for "box"
                                >> WAAPI.withProgressEvents True
                            )

                    ( _, maybeEvent ) =
                        WAAPI.update (propertyUpdateMsg "box" 0.42) animState
                in
                Expect.equal (Just (WAAPI.Progress "box" 0.42)) maybeEvent
        , test "group override False suppresses Progress when global default is True" <|
            \_ ->
                let
                    initialState =
                        WAAPI.init dummyCmd dummySub [ WAAPI.withProgressEvents True ]

                    ( animState, _ ) =
                        WAAPI.animate initialState
                            (WAAPI.for "box"
                                >> WAAPI.withProgressEvents False
                            )

                    ( _, maybeEvent ) =
                        WAAPI.update (propertyUpdateMsg "box" 0.42) animState
                in
                Expect.equal Nothing maybeEvent
        , test "stale propertyUpdate version does not overwrite current opacity snapshot" <|
            \_ ->
                let
                    initialState =
                        WAAPI.init dummyCmd dummySub []

                    ( animStateAfterAnimate, _ ) =
                        WAAPI.animate initialState <|
                            WAAPI.for "box"
                                >> Opacity.begin
                                >> Opacity.to 1
                                >> Opacity.duration 1000
                                >> Opacity.end

                    ( animStateAfterCurrentUpdate, _ ) =
                        WAAPI.update (propertyUpdateMsgWithVersion "box" 0.2 1 0.2) animStateAfterAnimate

                    currentBeforeStale =
                        WAAPI.getOpacityCurrent "box" animStateAfterCurrentUpdate

                    ( animStateAfterStaleUpdate, _ ) =
                        WAAPI.update (propertyUpdateMsgWithVersion "box" 0.8 0 0.8) animStateAfterCurrentUpdate

                    currentAfterStale =
                        WAAPI.getOpacityCurrent "box" animStateAfterStaleUpdate
                in
                Expect.equal currentBeforeStale currentAfterStale
        ]


propertyUpdateMsg : String -> Float -> WAAPI.AnimMsg
propertyUpdateMsg animGroup progress =
    propertyUpdateMsgWithVersion animGroup progress 1 progress


propertyUpdateMsgWithVersion : String -> Float -> Int -> Float -> WAAPI.AnimMsg
propertyUpdateMsgWithVersion animGroup progress opacityVersion opacityProgress =
    WAAPIInternal.JavascriptUpdate
        (Encode.object
            [ ( "type", Encode.string "propertyUpdate" )
            , ( "animGroup", Encode.string animGroup )
            , ( "progress", Encode.float progress )
            , ( "isAnimating", Encode.bool True )
            , ( "propertyVersions"
              , Encode.object [ ( "opacity", Encode.int opacityVersion ) ]
              )
            , ( "propertyProgress"
              , Encode.object [ ( "opacity", Encode.float opacityProgress ) ]
              )
            ]
        )


dummyCmd : Encode.Value -> Cmd msg
dummyCmd _ =
    Cmd.none


dummySub : (a -> msg) -> Sub msg
dummySub _ =
    Sub.none
