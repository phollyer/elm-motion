module Scroll.Engine.TaskSpec exposing (suite)

{-| Tests for the public `Scroll.Engine.Task` engine surface.

The engine returns an opaque `Task ScrollError (List ScrollOk)` value
that cannot be inspected in pure Elm. These tests therefore focus on:

  - The public setters (`delay`, `duration`, `speed`, `easing`) being
    correct aliases for the internal `Scroll.Internal.ScrollBuilder`
    setters.
  - The `ScrollError` opaque type exposing the documented fields
    (`container`, `targetElementId`, `domError`).
  - The `ScrollOk` record type carrying the documented fields.
  - The `Container` type having both `Document` and `Container String`
    constructors.
  - `Task.scroll` and `Task.scrollEach` having the documented
    signatures. Tests bind the result to a variable of the expected
    type — a regression that changed the signature would fail to
    compile.

-}

import Browser.Dom as Dom
import Expect
import Motion.Easing exposing (Easing(..))
import Scroll.Builder as Scroll
import Scroll.Engine.Task as Task
    exposing
        ( Container(..)
        , ScrollError(..)
        , ScrollOk
        )
import Scroll.Internal.ScrollBuilder as SB
import Shared.TimeSpec exposing (TimeSpec(..))
import Task as ElmTask
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Scroll.Engine.Task"
        [ setterAliasTests
        , typeTests
        , triggerTypeTests
        ]



-- ============================================================
-- SETTER ALIASES
-- ============================================================


setterAliasTests : Test
setterAliasTests =
    describe "public setters delegate to Scroll.Internal.ScrollBuilder"
        [ test "Task.delay sets the global delay" <|
            \_ ->
                SB.init
                    |> Task.delay 150
                    |> SB.getDelayWithDefault
                    |> Expect.equal 150
        , test "Task.duration sets the timing to Duration" <|
            \_ ->
                SB.init
                    |> Task.duration 600
                    |> SB.getTimeSpecWithDefault
                    |> Expect.equal (Duration 600)
        , test "Task.speed sets the timing to Speed" <|
            \_ ->
                SB.init
                    |> Task.speed 175
                    |> SB.getTimeSpecWithDefault
                    |> Expect.equal (Speed 175)
        , test "Task.easing sets the global easing" <|
            \_ ->
                SB.init
                    |> Task.easing EaseInOut
                    |> SB.getEasingWithDefault
                    |> Expect.equal EaseInOut
        ]



-- ============================================================
-- TYPES
-- ============================================================


typeTests : Test
typeTests =
    describe "public types are constructible and destructurable"
        [ test "Container.Document is constructible" <|
            \_ ->
                Document |> Expect.equal Document
        , test "Container.Container takes an id String" <|
            \_ ->
                Container "main"
                    |> (\c ->
                            case c of
                                Container id ->
                                    id

                                Document ->
                                    ""
                       )
                    |> Expect.equal "main"
        , test "ScrollError exposes the documented record fields" <|
            \_ ->
                let
                    err =
                        ScrollError
                            { container = Document
                            , targetElementId = Just "target"
                            , domError = Dom.NotFound "target"
                            }
                in
                case err of
                    ScrollError fields ->
                        Expect.all
                            [ \_ -> fields.container |> Expect.equal Document
                            , \_ -> fields.targetElementId |> Expect.equal (Just "target")
                            , \_ ->
                                case fields.domError of
                                    Dom.NotFound id ->
                                        id |> Expect.equal "target"
                            ]
                            ()
        , test "ScrollError without a target element id" <|
            \_ ->
                let
                    err =
                        ScrollError
                            { container = Container "scroll-area"
                            , targetElementId = Nothing
                            , domError = Dom.NotFound "scroll-area"
                            }
                in
                case err of
                    ScrollError fields ->
                        fields.targetElementId |> Expect.equal Nothing
        , test "ScrollOk is a record alias with container + targetElementId" <|
            \_ ->
                let
                    ok : ScrollOk
                    ok =
                        { container = Container "scroll-area"
                        , targetElementId = Just "row-5"
                        }
                in
                Expect.all
                    [ \_ -> ok.container |> Expect.equal (Container "scroll-area")
                    , \_ -> ok.targetElementId |> Expect.equal (Just "row-5")
                    ]
                    ()
        ]



-- ============================================================
-- TRIGGER TYPE
-- ============================================================


triggerTypeTests : Test
triggerTypeTests =
    describe "Task.scroll / Task.scrollEach signatures"
        [ test "Task.scroll typechecks as (ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)" <|
            \_ ->
                let
                    typed : (Scroll.ScrollBuilder -> Scroll.ScrollBuilder) -> ElmTask.Task ScrollError (List ScrollOk)
                    typed =
                        Task.scroll
                in
                typed |> always Expect.pass
        , test "Task.scrollEach typechecks as (ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))" <|
            \_ ->
                let
                    typed : (Scroll.ScrollBuilder -> Scroll.ScrollBuilder) -> ElmTask.Task Never (List (Result ScrollError ScrollOk))
                    typed =
                        Task.scrollEach
                in
                typed |> always Expect.pass
        , test "Task.scroll with a configured target does not crash" <|
            \_ ->
                let
                    t : ElmTask.Task ScrollError (List ScrollOk)
                    t =
                        Task.scroll
                            (Task.delay 50
                                >> Task.duration 400
                                >> Task.easing QuintOut
                                >> Scroll.forContainer "scroll-area"
                                >> Scroll.toBottom
                                >> Scroll.build
                            )
                in
                t |> always Expect.pass
        , test "Task.scrollEach with multiple targets does not crash" <|
            \_ ->
                let
                    t : ElmTask.Task Never (List (Result ScrollError ScrollOk))
                    t =
                        Task.scrollEach
                            (Task.duration 500
                                >> Scroll.forDocument
                                >> Scroll.toElement "first"
                                >> Scroll.build
                                >> Scroll.forDocument
                                >> Scroll.toElement "second"
                                >> Scroll.build
                            )
                in
                t |> always Expect.pass
        ]
