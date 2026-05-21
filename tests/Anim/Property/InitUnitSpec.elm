module Anim.Property.InitUnitSpec exposing (suite)

{-| Tests for `initUnit*` API across Translate, Size, and PerspectiveOrigin.

Each property exposes:

  - `initUnit` - set the unit for all subsequent `init*` calls
  - per-axis variants that override `initUnit` on a specific axis

Order matters - `initUnit*` only affects `init*` calls that follow it in
the pipeline. The rendered CSS unit is verified by inspecting the inline
style output via the WAAPI engine's `attributes` function.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Expect
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type Msg
    = NoOp


fakeCommandPort : Encode.Value -> Cmd Msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> Msg) -> Sub Msg
fakeSubscriptionPort _ =
    Sub.none


initWith : List (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState Msg
initWith =
    WAAPI.init fakeCommandPort fakeSubscriptionPort


query : WAAPI.AnimState Msg -> Query.Single Msg
query state =
    Html.div (WAAPI.attributes "el" state) []
        |> Query.fromHtml


suite : Test
suite =
    describe "Property.initUnit"
        [ translateTests
        , sizeTests
        , perspectiveOriginTests
        ]



-- ============================================================
-- TRANSLATE
-- ============================================================


translateTests : Test
translateTests =
    describe "Translate.initUnit"
        [ test "default unit (Px) is used when initUnit is not called" <|
            \_ ->
                initWith [ Translate.initXY "el" 50 25 ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50px, 25px, 0px)" ]
        , test "initUnit sets the unit for subsequent initXY" <|
            \_ ->
                initWith
                    [ Translate.initUnit Cqw
                        >> Translate.initXY "el" 50 25
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50cqw, 25cqw, 0px)" ]
        , test "initUnitX overrides initUnit on the X axis only" <|
            \_ ->
                initWith
                    [ Translate.initUnit Cqw
                        >> Translate.initUnitX Vw
                        >> Translate.initXY "el" 50 25
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50vw, 25cqw, 0px)" ]
        , test "initUnitY overrides initUnit on the Y axis only" <|
            \_ ->
                initWith
                    [ Translate.initUnit Cqw
                        >> Translate.initUnitY Vh
                        >> Translate.initXY "el" 50 25
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50cqw, 25vh, 0px)" ]
        , test "initUnitZ sets the Z-axis unit" <|
            \_ ->
                initWith
                    [ Translate.initUnitZ Vw
                        >> Translate.initXYZ "el" 0 0 10
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(0px, 0px, 10vw)" ]
        , test "order matters - initUnit after init has no effect on the prior init" <|
            \_ ->
                initWith
                    [ Translate.initXY "el" 50 25
                        >> Translate.initUnit Cqw
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50px, 25px, 0px)" ]
        ]



-- ============================================================
-- SIZE
-- ============================================================


sizeTests : Test
sizeTests =
    describe "Size.initUnit"
        [ test "default unit (Px) is used when initUnit is not called" <|
            \_ ->
                let
                    rendered =
                        initWith [ Size.initHW "el" 80 120 ] |> query
                in
                Expect.all
                    [ \_ -> rendered |> Query.has [ Selector.style "height" "80px" ]
                    , \_ -> rendered |> Query.has [ Selector.style "width" "120px" ]
                    ]
                    ()
        , test "initUnit sets the unit for subsequent initHW" <|
            \_ ->
                let
                    rendered =
                        initWith
                            [ Size.initUnit Cqmin
                                >> Size.initHW "el" 80 120
                            ]
                            |> query
                in
                Expect.all
                    [ \_ -> rendered |> Query.has [ Selector.style "height" "80cqmin" ]
                    , \_ -> rendered |> Query.has [ Selector.style "width" "120cqmin" ]
                    ]
                    ()
        , test "initUnitWidth overrides initUnit on width only" <|
            \_ ->
                let
                    rendered =
                        initWith
                            [ Size.initUnit Cqmin
                                >> Size.initUnitWidth Vw
                                >> Size.initHW "el" 80 120
                            ]
                            |> query
                in
                Expect.all
                    [ \_ -> rendered |> Query.has [ Selector.style "height" "80cqmin" ]
                    , \_ -> rendered |> Query.has [ Selector.style "width" "120vw" ]
                    ]
                    ()
        , test "initUnitHeight overrides initUnit on height only" <|
            \_ ->
                let
                    rendered =
                        initWith
                            [ Size.initUnit Cqmin
                                >> Size.initUnitHeight Vh
                                >> Size.initHW "el" 80 120
                            ]
                            |> query
                in
                Expect.all
                    [ \_ -> rendered |> Query.has [ Selector.style "height" "80vh" ]
                    , \_ -> rendered |> Query.has [ Selector.style "width" "120cqmin" ]
                    ]
                    ()
        ]



-- ============================================================
-- PERSPECTIVE ORIGIN
-- ============================================================


perspectiveOriginTests : Test
perspectiveOriginTests =
    describe "PerspectiveOrigin.initUnit"
        [ test "default unit (Percent) is used when initUnit is not called" <|
            \_ ->
                initWith [ PerspectiveOrigin.initXY "el" 50 75 ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 75%" ]
        , test "initUnit switches the unit for subsequent initXY" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initUnit Px
                        >> PerspectiveOrigin.initXY "el" 200 150
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "200px 150px" ]
        , test "initUnitX overrides initUnit on the X axis only" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initUnit Px
                        >> PerspectiveOrigin.initUnitX Percent
                        >> PerspectiveOrigin.initXY "el" 50 150
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 150px" ]
        , test "initUnitY overrides initUnit on the Y axis only" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initUnit Px
                        >> PerspectiveOrigin.initUnitY Percent
                        >> PerspectiveOrigin.initXY "el" 200 50
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "200px 50%" ]
        , test "initX uses the unit selected by initUnitX" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initUnitX Px
                        >> PerspectiveOrigin.initX "el" 200
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "200px 50%" ]
        , test "initY uses the unit selected by initUnitY" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initUnitY Px
                        >> PerspectiveOrigin.initY "el" 150
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 150px" ]
        ]
