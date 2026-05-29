module Anim.Engine.Sub.ProgressEventsTest exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Translate as Translate
import Expect
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


buildAnim : Sub.EngineBuilder -> Sub.EngineBuilder
buildAnim =
    Translate.for groupName
        >> Translate.toX 100
        >> Translate.duration 1000
        >> Translate.build


tick : Float -> Sub.AnimState -> ( Sub.AnimState, List Sub.AnimEvent )
tick deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state


isProgress : Sub.AnimEvent -> Bool
isProgress event =
    case event of
        Sub.Progress _ _ ->
            True

        _ ->
            False


suite : Test
suite =
    describe "Anim.Engine.Sub withProgressEvents"
        [ test "update omits Progress events by default" <|
            \_ ->
                let
                    state =
                        Sub.init [ Translate.initXY groupName 0 0 ]
                            |> (\s -> Sub.animate s buildAnim)

                    ( _, events ) =
                        tick 16 state
                in
                events
                    |> List.filter isProgress
                    |> Expect.equalLists []
        , test "update emits Progress events when withProgressEvents True" <|
            \_ ->
                let
                    state =
                        Sub.init
                            [ Sub.withProgressEvents True
                            , Translate.initXY groupName 0 0
                            ]
                            |> (\s -> Sub.animate s buildAnim)

                    ( _, events ) =
                        tick 16 state
                in
                events
                    |> List.filter isProgress
                    |> List.length
                    |> Expect.greaterThan 0
        , test "withProgressEvents False keeps Progress events suppressed" <|
            \_ ->
                let
                    state =
                        Sub.init
                            [ Sub.withProgressEvents False
                            , Translate.initXY groupName 0 0
                            ]
                            |> (\s -> Sub.animate s buildAnim)

                    ( _, events ) =
                        tick 16 state
                in
                events
                    |> List.filter isProgress
                    |> Expect.equalLists []
        ]
