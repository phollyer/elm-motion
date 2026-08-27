module Anim.Property.CssUnitSpec exposing (suite)

{-| Tests for `cssUnit*` API across Translate, Size, and PerspectiveOrigin.

Each property exposes:

    - `cssUnit` - set the unit for `init*` calls earlier in the pipeline

  - per-axis variants that override `cssUnit` on a specific axis

Order matters - `cssUnit*` only affects `init*` calls that appear before it in
the pipeline. The rendered CSS unit is verified by inspecting the inline
style output via the WAAPI engine's `attributes` function.

-}

import Anim.Engine.Transition as Transition
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


initWAAPIWith : List (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState msg
initWAAPIWith =
    WAAPI.init fakeCommandPort fakeSubscriptionPort


queryWAAPI : WAAPI.AnimState msg -> Query.Single msg
queryWAAPI state =
    Html.div (WAAPI.attributes "el" state) []
        |> Query.fromHtml


initTransitionWith : List (Transition.EngineBuilder -> Transition.EngineBuilder) -> Transition.AnimState
initTransitionWith =
    Transition.init


queryTransition : Transition.AnimState -> Query.Single msg
queryTransition state =
    Html.div (Transition.attributes "el" state) []
        |> Query.fromHtml


queryTransitionFor : String -> Transition.AnimState -> Query.Single msg
queryTransitionFor animGroup state =
    Html.div (Transition.attributes animGroup state) []
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
        [ describe "Transition Engine"
            [ test "default unit (Px) is used when cssUnit is not called" <|
                \_ ->
                    initTransitionWith [ Translate.initXY "el" 50 25 ]
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "50px 25px 0px" ]
            , test "cssUnit sets the unit for earlier initXY" <|
                \_ ->
                    initTransitionWith
                        [ Translate.initXY "el" 50 25
                            >> Translate.cssUnit Cqw
                        ]
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "50cqw 25cqw 0px" ]
            , test "cssUnitX overrides cssUnit on the X axis only" <|
                \_ ->
                    initTransitionWith
                        [ Translate.initXY "el" 50 25
                            >> Translate.cssUnit Cqw
                            >> Translate.cssUnitX Vw
                        ]
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "50vw 25cqw 0px" ]
            , test "cssUnitY overrides cssUnit on the Y axis only" <|
                \_ ->
                    initTransitionWith
                        [ Translate.initXY "el" 50 25
                            >> Translate.cssUnit Cqw
                            >> Translate.cssUnitY Vh
                        ]
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "50cqw 25vh 0px" ]
            , test "cssUnitZ sets the Z-axis unit" <|
                \_ ->
                    initTransitionWith
                        [ Translate.initXYZ "el" 0 0 10
                            >> Translate.cssUnitZ Vw
                        ]
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "0px 0px 10vw" ]
            , test "order matters - cssUnit before init has no effect" <|
                \_ ->
                    initTransitionWith
                        [ Translate.cssUnit Cqw
                            >> Translate.initXY "el" 50 25
                        ]
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "50px 25px 0px" ]
            , test "cssUnit is preserved during animation" <|
                \_ ->
                    let
                        state =
                            initTransitionWith
                                [ Translate.initXY "el" 50 25
                                    >> Translate.cssUnit Cqw
                                ]
                    in
                    (Transition.animate state <|
                        Transition.for "el"
                            >> Translate.begin
                            >> Translate.toXY 100 50
                            >> Translate.end
                    )
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "100cqw 50cqw 0px" ]
            , test "cssUnit is changed for an animation" <|
                \_ ->
                    let
                        state =
                            initTransitionWith
                                [ Translate.initXY "el" 50 25
                                    >> Translate.cssUnit Cqw
                                ]
                    in
                    (Transition.animate state <|
                        Transition.for "el"
                            >> Translate.cssUnit Cqh
                            >> Translate.begin
                            >> Translate.toXY 100 50
                            >> Translate.end
                    )
                        |> queryTransition
                        |> Query.has [ Selector.style "translate" "100cqh 50cqh 0px" ]
            ]
        , test "cssUnit is changed for only the targeted animation" <|
            \_ ->
                let
                    state =
                        initTransitionWith
                            [ Translate.initXY "el" 50 25
                                >> Translate.cssUnit Cqw
                            , Translate.initXY "el2" 50 25
                                >> Translate.cssUnit Cqw
                            ]

                    animState =
                        Transition.animate state <|
                            Translate.cssUnit Cqh
                                >> Transition.for "el"
                                -- testing that this CSS Unit change does not affect the other animation
                                -->> Translate.cssUnit Cqh
                                >> Translate.begin
                                >> Translate.toXY 100 50
                                >> Translate.end
                                >> Transition.for "el2"
                                >> Translate.begin
                                >> Translate.toXY 100 50
                                >> Translate.end
                in
                Expect.all
                    [ \_ ->
                        animState
                            |> queryTransitionFor "el"
                            |> Query.has [ Selector.style "translate" "100cqh 50cqh 0px" ]
                    , \_ ->
                        animState
                            |> queryTransitionFor "el2"
                            |> Query.has [ Selector.style "translate" "100cqw 50cqw 0px" ]
                    ]
                    ()
        , test "cssUnit is changed for all animations" <|
            \_ ->
                let
                    state =
                        initTransitionWith
                            [ Translate.initXY "el" 50 25
                                >> Translate.cssUnit Cqw
                            , Translate.initXY "el2" 50 25
                                >> Translate.cssUnit Cqw
                            ]

                    animState =
                        Transition.animate state <|
                            -- testing that this CSS Unit change does change for all animations
                            Transition.cssUnit Cqh
                                >> Transition.for "el"
                                >> Translate.begin
                                >> Translate.toXY 100 50
                                >> Translate.end
                                >> Transition.for "el2"
                                >> Translate.begin
                                >> Translate.toXY 100 50
                                >> Translate.end
                in
                Expect.all
                    [ \_ ->
                        animState
                            |> queryTransitionFor "el"
                            |> Query.has [ Selector.style "translate" "100cqh 50cqh 0cqh" ]
                    , \_ ->
                        animState
                            |> queryTransitionFor "el2"
                            |> Query.has [ Selector.style "translate" "100cqh 50cqh 0cqh" ]
                    ]
                    ()
        , describe "WAAPI Engine"
            [ test "default unit (Px) is used when cssUnit is not called" <|
                \_ ->
                    initWAAPIWith [ Translate.initXY "el" 50 25 ]
                        |> queryWAAPI
                        |> Query.has [ Selector.style "transform" "translate3d(50px, 25px, 0px)" ]
            , test "cssUnit sets the unit for earlier initXY" <|
                \_ ->
                    initWAAPIWith
                        [ Translate.initXY "el" 50 25
                            >> Translate.cssUnit Cqw
                        ]
                        |> queryWAAPI
                        |> Query.has [ Selector.style "transform" "translate3d(50cqw, 25cqw, 0px)" ]
            , test "cssUnitX overrides cssUnit on the X axis only" <|
                \_ ->
                    initWAAPIWith
                        [ Translate.initXY "el" 50 25
                            >> Translate.cssUnit Cqw
                            >> Translate.cssUnitX Vw
                        ]
                        |> queryWAAPI
                        |> Query.has [ Selector.style "transform" "translate3d(50vw, 25cqw, 0px)" ]
            , test "cssUnitY overrides cssUnit on the Y axis only" <|
                \_ ->
                    initWAAPIWith
                        [ Translate.initXY "el" 50 25
                            >> Translate.cssUnit Cqw
                            >> Translate.cssUnitY Vh
                        ]
                        |> queryWAAPI
                        |> Query.has [ Selector.style "transform" "translate3d(50cqw, 25vh, 0px)" ]
            , test "cssUnitZ sets the Z-axis unit" <|
                \_ ->
                    initWAAPIWith
                        [ Translate.initXYZ "el" 0 0 10
                            >> Translate.cssUnitZ Vw
                        ]
                        |> queryWAAPI
                        |> Query.has [ Selector.style "transform" "translate3d(0px, 0px, 10vw)" ]
            , test "order matters - cssUnit before init has no effect" <|
                \_ ->
                    initWAAPIWith
                        [ Translate.cssUnit Cqw
                            >> Translate.initXY "el" 50 25
                        ]
                        |> queryWAAPI
                        |> Query.has [ Selector.style "transform" "translate3d(50px, 25px, 0px)" ]
            ]
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
                        initWAAPIWith [ Size.initHW "el" 80 120 ] |> queryWAAPI
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
                        initWAAPIWith
                            [ Size.initHW "el" 80 120
                                >> Size.cssUnit Cqmin
                            ]
                            |> queryWAAPI
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
                        initWAAPIWith
                            [ Size.initHW "el" 80 120
                                >> Size.cssUnit Cqmin
                                >> Size.cssUnitW Vw
                            ]
                            |> queryWAAPI
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
                        initWAAPIWith
                            [ Size.initHW "el" 80 120
                                >> Size.cssUnit Cqmin
                                >> Size.cssUnitH Vh
                            ]
                            |> queryWAAPI
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
                initWAAPIWith [ PerspectiveOrigin.initXY "el" 50 75 ]
                    |> queryWAAPI
                    |> Query.has [ Selector.style "perspective-origin" "50% 75%" ]
        , test "cssUnit switches the unit for earlier initXY" <|
            \_ ->
                initWAAPIWith
                    [ PerspectiveOrigin.initXY "el" 200 150
                        >> PerspectiveOrigin.cssUnit Px
                    ]
                    |> queryWAAPI
                    |> Query.has [ Selector.style "perspective-origin" "200px 150px" ]
        , test "cssUnitX overrides cssUnit on the X axis only" <|
            \_ ->
                initWAAPIWith
                    [ PerspectiveOrigin.initXY "el" 50 150
                        >> PerspectiveOrigin.cssUnit Px
                        >> PerspectiveOrigin.cssUnitX Percent
                    ]
                    |> queryWAAPI
                    |> Query.has [ Selector.style "perspective-origin" "50% 150px" ]
        , test "cssUnitY overrides cssUnit on the Y axis only" <|
            \_ ->
                initWAAPIWith
                    [ PerspectiveOrigin.initXY "el" 200 50
                        >> PerspectiveOrigin.cssUnit Px
                        >> PerspectiveOrigin.cssUnitY Percent
                    ]
                    |> queryWAAPI
                    |> Query.has [ Selector.style "perspective-origin" "200px 50%" ]
        , test "initX uses the unit selected by cssUnitX" <|
            \_ ->
                initWAAPIWith
                    [ PerspectiveOrigin.initX "el" 200
                        >> PerspectiveOrigin.cssUnitX Px
                    ]
                    |> queryWAAPI
                    |> Query.has [ Selector.style "perspective-origin" "200px 50%" ]
        , test "initY uses the unit selected by cssUnitY" <|
            \_ ->
                initWAAPIWith
                    [ PerspectiveOrigin.initY "el" 150
                        >> PerspectiveOrigin.cssUnitY Px
                    ]
                    |> queryWAAPI
                    |> Query.has [ Selector.style "perspective-origin" "50% 150px" ]
        ]
