module Anim.Engine.WAAPI.SetProgressThrottleSpec exposing (suite)

{-| Pins the wire format of the WAAPI `setUpdateThrottle` command.

The encoded payload is dispatched to the JS runtime, which routes it to
`setPropertyUpdateThrottle(intervalMs)` to cap the rate of `propertyUpdate`
events sent back to Elm. The shape MUST stay stable so the JS handler
keeps reading the right field.

-}

import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI setUpdateThrottle command wire format"
        [ test "encodes type as \"setUpdateThrottle\"" <|
            \_ ->
                Encoder.encodeSetProgressThrottle 16
                    |> decodeStringField "type"
                    |> Expect.equal (Just "setUpdateThrottle")
        , test "carries the interval in intervalMs" <|
            \_ ->
                Encoder.encodeSetProgressThrottle 16
                    |> decodeIntField "intervalMs"
                    |> Expect.equal (Just 16)
        , test "encodes 0 as a valid disable value" <|
            \_ ->
                Encoder.encodeSetProgressThrottle 0
                    |> decodeIntField "intervalMs"
                    |> Expect.equal (Just 0)
        , test "does not carry an elementId (command is global, not per animGroup)" <|
            \_ ->
                Encoder.encodeSetProgressThrottle 33
                    |> hasField "elementId"
                    |> Expect.equal False
        ]



-- HELPERS


toString : Encode.Value -> String
toString =
    Encode.encode 0


decodeStringField : String -> Encode.Value -> Maybe String
decodeStringField field json =
    json
        |> toString
        |> Decode.decodeString (Decode.field field Decode.string)
        |> Result.toMaybe


decodeIntField : String -> Encode.Value -> Maybe Int
decodeIntField field json =
    json
        |> toString
        |> Decode.decodeString (Decode.field field Decode.int)
        |> Result.toMaybe


hasField : String -> Encode.Value -> Bool
hasField field json =
    json
        |> toString
        |> Decode.decodeString (Decode.field field Decode.value)
        |> Result.toMaybe
        |> (/=) Nothing
