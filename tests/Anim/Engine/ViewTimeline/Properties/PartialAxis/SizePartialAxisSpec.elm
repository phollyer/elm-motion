module Anim.Engine.ViewTimeline.Properties.PartialAxis.SizePartialAxisSpec exposing (suite)

{-| Payload-level assertions for partial-axis size animations in
`Anim.Engine.ViewTimeline`.

These tests lock axis ownership bookkeeping for first-use partial size
updates:

    - First-use `toH` should mark only `touchedHeight`.
    - First-use `toW` should mark only `touchedWidth`.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Size as Size
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.ViewTimeline size partial-axis payload"
        [ describe "marking touched axes"
            [ test "first-use Size.toHW marks touchedHeight and touchedWidth" <|
                \_ ->
                    encodeView
                        (Builder.for "card"
                            >> Size.begin
                            >> Size.toHW 120 200
                            >> Size.end
                        )
                        |> decodeSizeTouchedAxes "card"
                        |> Expect.equal (Just ( True, True ))
            , test "first-use Size.toH marks touchedHeight only" <|
                \_ ->
                    encodeView
                        (Builder.for "card"
                            >> Size.begin
                            >> Size.toH 120
                            >> Size.end
                        )
                        |> decodeSizeTouchedAxes "card"
                        |> Expect.equal (Just ( True, False ))
            , test "first-use Size.toW marks touchedWidth only" <|
                \_ ->
                    encodeView
                        (Builder.for "card"
                            >> Size.begin
                            >> Size.toW 200
                            >> Size.end
                        )
                        |> decodeSizeTouchedAxes "card"
                        |> Expect.equal (Just ( False, True ))
            , test "after Size.toH, Size.toW keeps previously-owned height in touched axes" <|
                \_ ->
                    encodeViewAfterSizeHistory
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toH 120
                            >> Size.end
                        )
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toW 200
                            >> Size.end
                        )
                        |> decodeSizeTouchedAxes "cube"
                        |> Expect.equal (Just ( True, True ))
            , test "after Size.toW, Size.toH keeps previously-owned width in touched axes" <|
                \_ ->
                    encodeViewAfterSizeHistory
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toW 120
                            >> Size.end
                        )
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toH 200
                            >> Size.end
                        )
                        |> decodeSizeTouchedAxes "cube"
                        |> Expect.equal (Just ( True, True ))
            ]
        , describe "payload contains the correct values"
            [ test "first-use Size.toHW sends both size end values to JS" <|
                \_ ->
                    encodeView
                        (Builder.for "card"
                            >> Size.begin
                            >> Size.toHW 120 150
                            >> Size.end
                        )
                        |> decodeSizePayload "card"
                        |> Expect.equal
                            (Just
                                { startWidth = Just 0
                                , startHeight = Just 0
                                , endWidth = Just 150
                                , endHeight = Just 120
                                }
                            )
            , test "first-use Size.toH omits width fields and sends height fields" <|
                \_ ->
                    encodeView
                        (Builder.for "card"
                            >> Size.begin
                            >> Size.toH 120
                            >> Size.end
                        )
                        |> decodeSizePayload "card"
                        |> Expect.equal
                            (Just
                                { startWidth = Nothing
                                , startHeight = Just 0
                                , endWidth = Nothing
                                , endHeight = Just 120
                                }
                            )
            , test "first-use Size.toW omits height fields and sends width fields" <|
                \_ ->
                    encodeView
                        (Builder.for "card"
                            >> Size.begin
                            >> Size.toW 120
                            >> Size.end
                        )
                        |> decodeSizePayload "card"
                        |> Expect.equal
                            (Just
                                { startWidth = Just 0
                                , startHeight = Nothing
                                , endWidth = Just 120
                                , endHeight = Nothing
                                }
                            )
            , test "after Size.toH, Size.toW keeps previous height value in encoded start/end" <|
                \_ ->
                    encodeViewAfterSizeHistory
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toH 120
                            >> Size.end
                        )
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toW 200
                            >> Size.end
                        )
                        |> decodeSizePayload "cube"
                        |> Expect.equal
                            (Just
                                { startWidth = Just 0
                                , startHeight = Just 120
                                , endWidth = Just 200
                                , endHeight = Just 120
                                }
                            )
            ]
        , describe "will-change behavior"
            [ test "first-use Size.toHW emits 'width, height' for will-change" <|
                \_ ->
                    encodeView
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toHW 200 150
                            >> Size.end
                        )
                        |> decodeWillChange "cube"
                        |> Expect.equal (Just "width, height")
            , test "first-use Size.toH emits only 'height' for will-change" <|
                \_ ->
                    encodeView
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toH 150
                            >> Size.end
                        )
                        |> decodeWillChange "cube"
                        |> Expect.equal (Just "height")
            , test "first-use Size.toW emits only 'width' for will-change" <|
                \_ ->
                    encodeView
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toW 200
                            >> Size.end
                        )
                        |> decodeWillChange "cube"
                        |> Expect.equal (Just "width")
            , test "after Size.toH, Size.toW keeps previously-owned height in will-change" <|
                \_ ->
                    encodeViewAfterSizeHistory
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toH 120
                            >> Size.end
                        )
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toW 200
                            >> Size.end
                        )
                        |> decodeWillChange "cube"
                        |> Expect.equal (Just "width, height")
            , test "after Size.toW, Size.toH keeps previously-owned width in will-change" <|
                \_ ->
                    encodeViewAfterSizeHistory
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toW 200
                            >> Size.end
                        )
                        (Builder.for "cube"
                            >> Size.begin
                            >> Size.toH 120
                            >> Size.end
                        )
                        |> decodeWillChange "cube"
                        |> Expect.equal (Just "width, height")
            ]
        ]


encodeView steps =
    Builder.init [ steps ]
        |> Encoder.encodeView
        |> Encode.encode 0


encodeViewAfterSizeHistory first second =
    let
        firstBuilder =
            Builder.init [ first ]

        firstProcessed =
            Builder.process firstBuilder

        afterFirst =
            firstBuilder
                |> Builder.addAnimationToHistory firstProcessed
                |> Builder.mergeBaselines
                |> Builder.clearAnimData

        secondBuilder =
            second afterFirst
    in
    Encoder.encodeView secondBuilder
        |> Encode.encode 0


decodeWillChange : String -> String -> Maybe String
decodeWillChange animGroupName json =
    Decode.decodeString
        (Decode.at [ "elements", animGroupName, "willChange" ] Decode.string)
        json
        |> Result.toMaybe


type alias DecodedSizePayload =
    { startWidth : Maybe Float
    , startHeight : Maybe Float
    , endWidth : Maybe Float
    , endHeight : Maybe Float
    }


decodeSizePayload : String -> String -> Maybe DecodedSizePayload
decodeSizePayload animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        if type_ == "size" then
                            Decode.map4
                                (\startWidth startHeight endWidth endHeight ->
                                    { startWidth = startWidth
                                    , startHeight = startHeight
                                    , endWidth = endWidth
                                    , endHeight = endHeight
                                    }
                                )
                                (Decode.maybe (Decode.field "startWidth" Decode.float))
                                (Decode.maybe (Decode.field "startHeight" Decode.float))
                                (Decode.maybe (Decode.field "endWidth" Decode.float))
                                (Decode.maybe (Decode.field "endHeight" Decode.float))

                        else
                            Decode.fail "not size"
                    )
    in
    Decode.decodeString
        (Decode.at [ "elements", animGroupName, "properties" ]
            (Decode.list (Decode.maybe propertyDecoder)
                |> Decode.map (List.filterMap identity >> List.head)
            )
        )
        json
        |> Result.toMaybe
        |> Maybe.andThen identity


decodeSizeTouchedAxes : String -> String -> Maybe ( Bool, Bool )
decodeSizeTouchedAxes animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\ty ->
                        if ty == "size" then
                            Decode.map2 Tuple.pair
                                (Decode.field "touchedHeight" Decode.bool)
                                (Decode.field "touchedWidth" Decode.bool)

                        else
                            Decode.fail "not size"
                    )
    in
    Decode.decodeString
        (Decode.at [ "elements", animGroupName, "properties" ]
            (Decode.list (Decode.maybe propertyDecoder)
                |> Decode.map (List.filterMap identity >> List.head)
            )
        )
        json
        |> Result.toMaybe
        |> Maybe.andThen identity
