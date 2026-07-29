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
    Sub.for groupName
        >> Translate.begin
        >> Translate.toX 100
        >> Translate.duration 1000
        >> Translate.end


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


progressEntry : Sub.AnimEvent -> Maybe ( String, Float )
progressEntry event =
    case event of
        Sub.Progress group value ->
            Just ( group, value )

        _ ->
            Nothing


expectProgressFor : String -> List Sub.AnimEvent -> Expect.Expectation
expectProgressFor group events =
    events
        |> List.filterMap progressEntry
        |> Expect.all
            [ \entries -> List.isEmpty entries |> Expect.equal False
            , \entries -> List.all (\( g, _ ) -> g == group) entries |> Expect.equal True
            , \entries -> List.all (\( _, p ) -> p > 0 && p <= 1) entries |> Expect.equal True
            ]


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
                    |> expectProgressFor groupName
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
        , test "group override True emits Progress when global default is False" <|
            \_ ->
                let
                    state =
                        Sub.init
                            [ Sub.withProgressEvents False
                            , Translate.initXY groupName 0 0
                            ]
                            |> (\s ->
                                    Sub.animate s
                                        (Sub.for groupName
                                            >> Sub.withProgressEvents True
                                            >> Translate.begin
                                            >> Translate.toX 100
                                            >> Translate.duration 1000
                                            >> Translate.end
                                        )
                               )

                    ( _, events ) =
                        tick 16 state
                in
                events
                    |> expectProgressFor groupName
        , test "group override False suppresses Progress when global default is True" <|
            \_ ->
                let
                    state =
                        Sub.init
                            [ Sub.withProgressEvents True
                            , Translate.initXY groupName 0 0
                            ]
                            |> (\s ->
                                    Sub.animate s
                                        (Sub.for groupName
                                            >> Sub.withProgressEvents False
                                            >> Translate.begin
                                            >> Translate.toX 100
                                            >> Translate.duration 1000
                                            >> Translate.end
                                        )
                               )

                    ( _, events ) =
                        tick 16 state
                in
                events
                    |> List.filter isProgress
                    |> Expect.equalLists []
        ]
