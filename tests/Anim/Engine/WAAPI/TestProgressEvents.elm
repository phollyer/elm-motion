module Anim.Engine.WAAPI.TestProgressEvents exposing (suite)

import Anim.Engine.WAAPI as WAAPI
import Anim.Internal.Engine.WAAPI as WAAPIInternal
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
        ]


propertyUpdateMsg : String -> Float -> WAAPI.AnimMsg
propertyUpdateMsg animGroup progress =
    WAAPIInternal.JavascriptUpdate
        (Encode.object
            [ ( "type", Encode.string "propertyUpdate" )
            , ( "animGroup", Encode.string animGroup )
            , ( "progress", Encode.float progress )
            , ( "isAnimating", Encode.bool True )
            , ( "propertyVersions", Encode.object [] )
            ]
        )


dummyCmd : Encode.Value -> Cmd msg
dummyCmd _ =
    Cmd.none


dummySub : (a -> msg) -> Sub msg
dummySub _ =
    Sub.none
