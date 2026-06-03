module Anim.Property.CssUnitSpec exposing (suite)

{-| Tests for `cssUnit*` API across Translate, Size, and PerspectiveOrigin.

Each property exposes:

    - `cssUnit` - set the unit for `init*` calls earlier in the pipeline

  - per-axis variants that override `cssUnit` on a specific axis

Order matters - `cssUnit*` only affects `init*` calls that appear before it in
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


fakeCommandPort : Encode.Value -> Cmd msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> msg) -> Sub msg
fakeSubscriptionPort _ =
    Sub.none


initWith : List (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState msg
initWith =
    WAAPI.init fakeCommandPort fakeSubscriptionPort


query : WAAPI.AnimState msg -> Query.Single msg
query state =
    Html.div (WAAPI.attributes "el" state) []
        |> Query.fromHtml


suite : Test
suite =
    describe "Property.cssUnit"
        [ translateTests
        , sizeTests
        , perspectiveOriginTests
        ]



-- ============================================================
-- TRANSLATE
-- ============================================================


translateTests : Test
translateTests =
    describe "Translate.cssUnit"
        [ test "default unit (Px) is used when cssUnit is not called" <|
            \_ ->
                initWith [ Translate.initXY "el" 50 25 ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50px, 25px, 0px)" ]
        , test "cssUnit sets the unit for earlier initXY" <|
            \_ ->
                initWith
                    [ Translate.initXY "el" 50 25
                        >> Translate.cssUnit Cqw
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50cqw, 25cqw, 0px)" ]
        , test "cssUnitX overrides cssUnit on the X axis only" <|
            \_ ->
                initWith
                    [ Translate.initXY "el" 50 25
                        >> Translate.cssUnit Cqw
                        >> Translate.cssUnitX Vw
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50vw, 25cqw, 0px)" ]
        , test "cssUnitY overrides cssUnit on the Y axis only" <|
            \_ ->
                initWith
                    [ Translate.initXY "el" 50 25
                        >> Translate.cssUnit Cqw
                        >> Translate.cssUnitY Vh
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50cqw, 25vh, 0px)" ]
        , test "cssUnitZ sets the Z-axis unit" <|
            \_ ->
                initWith
                    [ Translate.initXYZ "el" 0 0 10
                        >> Translate.cssUnitZ Vw
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(0px, 0px, 10vw)" ]
        , test "order matters - cssUnit before init has no effect" <|
            \_ ->
                initWith
                    [ Translate.cssUnit Cqw
                        >> Translate.initXY "el" 50 25
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(50px, 25px, 0px)" ]
        ]



-- ============================================================
-- SIZE
-- ============================================================


sizeTests : Test
sizeTests =
    describe "Size.cssUnit"
        [ test "default unit (Px) is used when cssUnit is not called" <|
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
        , test "cssUnit sets the unit for earlier initHW" <|
            \_ ->
                let
                    rendered =
                        initWith
                            [ Size.initHW "el" 80 120
                                >> Size.cssUnit Cqmin
                            ]
                            |> query
                in
                Expect.all
                    [ \_ -> rendered |> Query.has [ Selector.style "height" "80cqmin" ]
                    , \_ -> rendered |> Query.has [ Selector.style "width" "120cqmin" ]
                    ]
                    ()
        , test "cssUnitW overrides cssUnit on width only" <|
            \_ ->
                let
                    rendered =
                        initWith
                            [ Size.initHW "el" 80 120
                                >> Size.cssUnit Cqmin
                                >> Size.cssUnitW Vw
                            ]
                            |> query
                in
                Expect.all
                    [ \_ -> rendered |> Query.has [ Selector.style "height" "80cqmin" ]
                    , \_ -> rendered |> Query.has [ Selector.style "width" "120vw" ]
                    ]
                    ()
        , test "cssUnitH overrides cssUnit on height only" <|
            \_ ->
                let
                    rendered =
                        initWith
                            [ Size.initHW "el" 80 120
                                >> Size.cssUnit Cqmin
                                >> Size.cssUnitH Vh
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
    describe "PerspectiveOrigin.cssUnit"
        [ test "default unit (Percent) is used when cssUnit is not called" <|
            \_ ->
                initWith [ PerspectiveOrigin.initXY "el" 50 75 ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 75%" ]
        , test "cssUnit switches the unit for earlier initXY" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initXY "el" 200 150
                        >> PerspectiveOrigin.cssUnit Px
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "200px 150px" ]
        , test "cssUnitX overrides cssUnit on the X axis only" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initXY "el" 50 150
                        >> PerspectiveOrigin.cssUnit Px
                        >> PerspectiveOrigin.cssUnitX Percent
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 150px" ]
        , test "cssUnitY overrides cssUnit on the Y axis only" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initXY "el" 200 50
                        >> PerspectiveOrigin.cssUnit Px
                        >> PerspectiveOrigin.cssUnitY Percent
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "200px 50%" ]
        , test "initX uses the unit selected by cssUnitX" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initX "el" 200
                        >> PerspectiveOrigin.cssUnitX Px
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "200px 50%" ]
        , test "initY uses the unit selected by cssUnitY" <|
            \_ ->
                initWith
                    [ PerspectiveOrigin.initY "el" 150
                        >> PerspectiveOrigin.cssUnitY Px
                    ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 150px" ]
        ]
