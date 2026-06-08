module Anim.Engine.WAAPI.SnapSpec exposing (suite)

{-| Tests for the `snap` port command in the WAAPI engine.

When a builder pipeline mixes `Animate`-mode and `Snap`-mode properties,
the WAAPI engine emits two port messages: the regular `animate` message
carrying only the Animate-mode properties, and a separate `snap` message
carrying only the Snap-mode properties. The `snap` payload uses the same
shape as `retarget`; the JS handler cancels in-flight animations on the
named properties and writes the end value as inline style.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI snap encoder"
        [ test "encodeSnap tags the payload with type=snap" <|
            \_ ->
                Builder.init
                    [ Builder.for "cube"
                        >> Translate.begin
                        >> Translate.setX 100
                        >> Translate.end
                    ]
                    |> Builder.process
                    |> Encoder.encodeSnap AnimGroups.init
                    |> decodeType
                    |> Expect.equal (Just "snap")
        , test "encodeSnap includes the snapped property's end value" <|
            \_ ->
                Builder.init
                    [ Builder.for "cube"
                        >> Translate.begin
                        >> Translate.setX 250
                        >> Translate.end
                    ]
                    |> Builder.process
                    |> Encoder.encodeSnap AnimGroups.init
                    |> Encode.encode 0
                    |> String.contains "250"
                    |> Expect.equal True
        , test "encode (animate command) excludes Snap-mode properties" <|
            \_ ->
                Builder.init
                    [ Builder.for "cube"
                        >> Translate.begin
                        >> Translate.setX 100
                        >> Translate.end
                    ]
                    |> Builder.process
                    |> Encoder.encode AnimGroups.init
                    |> decodeElementPropertyTypes "cube"
                    |> Expect.equal []
        , test "encode includes Animate-mode property when mixed with Snap" <|
            \_ ->
                Builder.init
                    [ Builder.for "cube"
                        >> Opacity.begin
                        >> Opacity.to 0.5
                        >> Opacity.duration 200
                        >> Opacity.end
                        >> Translate.begin
                        >> Translate.setX 100
                        >> Translate.end
                    ]
                    |> Builder.process
                    |> Encoder.encode AnimGroups.init
                    |> decodeElementPropertyTypes "cube"
                    |> Expect.equal [ "opacity" ]
        , test "encodeSnap includes only Snap-mode property when mixed with Animate" <|
            \_ ->
                Builder.init
                    [ Builder.for "cube"
                        >> Opacity.begin
                        >> Opacity.to 0.5
                        >> Opacity.duration 200
                        >> Opacity.end
                        >> Translate.begin
                        >> Translate.setX 100
                        >> Translate.end
                    ]
                    |> Builder.process
                    |> Encoder.encodeSnap AnimGroups.init
                    |> decodeElementPropertyTypes "cube"
                    |> Expect.equal [ "translate" ]
        ]



-- HELPERS


decodeType : Encode.Value -> Maybe String
decodeType value =
    value
        |> Encode.encode 0
        |> Decode.decodeString (Decode.field "type" Decode.string)
        |> Result.toMaybe


decodeElementPropertyTypes : String -> Encode.Value -> List String
decodeElementPropertyTypes elementId value =
    let
        decoder =
            Decode.field "elements"
                (Decode.field elementId
                    (Decode.field "properties"
                        (Decode.list (Decode.field "type" Decode.string))
                    )
                )
    in
    value
        |> Encode.encode 0
        |> Decode.decodeString decoder
        |> Result.withDefault []
