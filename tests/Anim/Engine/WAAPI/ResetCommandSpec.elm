module Anim.Engine.WAAPI.ResetCommandSpec exposing (suite)

{-| Regression tests for the WAAPI `reset` command wire format.

The reset path used to encode itself as a duration-0 `animate` command
that replayed the original 0 -> end keyframes. The Web Animations API
finishes such an animation immediately and emits a `finish` event with
`propertyProgress: 1.0`. Elm then applied that progress against the
still-stored "go to end" config and overwrote the snapshot with the END
value - so pressing Reset visibly sent the element to the end position
instead of snapping it back to the start.

The fix replaces the duration-0 animate hack with a dedicated
`type: "reset"` command. These tests pin the wire format so the bug
cannot return silently.

-}

import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI reset command wire format"
        [ test "encodes type as \"reset\"" <|
            \_ ->
                Encoder.encodeCommandWithProperties "reset" "ball" Nothing
                    |> decodeStringField "type"
                    |> Expect.equal (Just "reset")
        , test "carries the animGroup name in elementId" <|
            \_ ->
                Encoder.encodeCommandWithProperties "reset" "ball" Nothing
                    |> decodeStringField "elementId"
                    |> Expect.equal (Just "ball")
        , test "omits properties when no filter is supplied (resets all)" <|
            \_ ->
                Encoder.encodeCommandWithProperties "reset" "ball" Nothing
                    |> hasField "properties"
                    |> Expect.equal False
        , test "carries the properties filter when supplied" <|
            \_ ->
                Encoder.encodeCommandWithProperties "reset" "ball" (Just [ "translate", "rotate" ])
                    |> decodeStringListField "properties"
                    |> Expect.equal (Just [ "translate", "rotate" ])
        , test "does not encode an animate-shaped payload (no duration, no keyframes)" <|
            \_ ->
                let
                    json =
                        Encoder.encodeCommandWithProperties "reset" "ball" Nothing
                in
                ( hasField "duration" json, hasField "keyframes" json )
                    |> Expect.equal ( False, False )
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


decodeStringListField : String -> Encode.Value -> Maybe (List String)
decodeStringListField field json =
    json
        |> toString
        |> Decode.decodeString (Decode.field field (Decode.list Decode.string))
        |> Result.toMaybe


hasField : String -> Encode.Value -> Bool
hasField field json =
    json
        |> toString
        |> Decode.decodeString (Decode.field field Decode.value)
        |> Result.toMaybe
        |> (/=) Nothing
