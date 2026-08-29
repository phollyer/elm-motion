module Anim.Property.CssUnitSpec exposing (suite)

{-| Tests for `cssUnit*` API across Translate, Size, and PerspectiveOrigin.

Each property exposes:

    - `cssUnit` - set the unit for `init*` calls earlier in the pipeline

  - per-axis variants that override `cssUnit` on a specific axis

Order matters - `cssUnit*` only affects `init*` calls that appear before it in
the pipeline. The rendered CSS unit is verified by inspecting the inline
style output via the WAAPI engine's `attributes` function.

-}

import Anim.Builder exposing (AnimBuilder)
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
    -- TODO: Ensure this test suite contains all the correct tests for cssUnit* across Translate, Size, and PerspectiveOrigin. Some of these tests are currently in other files and should be moved here.
    describe "Property.cssUnit"
        [ translateInitCssUnitTests
        , sizeInitCssUnitTests
        , sizeSingleAnimationCssUnitTests
        , sizeMultipleAnimationCssUnitTests
        , perspectiveOriginInitCssUnitTests
        , perspectiveOriginSingleAnimationCssUnitTests
        , perspectiveOriginMultipleAnimationCssUnitTests
        ]



-- ============================================================
-- PERSPECTIVE ORIGIN
-- ============================================================


perspectiveOriginInitCssUnitConfigs : List ( String, AnimBuilder eng -> AnimBuilder eng, Selector.Selector )
perspectiveOriginInitCssUnitConfigs =
    [ ( "default unit (%) is used when initCssUnit is not called"
      , PerspectiveOrigin.initXY "el" 25 25
      , Selector.style "perspective-origin" "25% 25%"
      )
    , ( "order matters - initCssUnit before initXY has no effect"
      , PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initXY "el" 100 100
      , Selector.style "perspective-origin" "100% 100%"
      )
    , ( "order matters - initCssUnit before initX has no effect"
      , PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initX "el" 100
      , Selector.style "perspective-origin" "100% 50%"
      )
    , ( "order matters - initCssUnit before initY has no effect"
      , PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initY "el" 100
      , Selector.style "perspective-origin" "50% 100%"
      )
    , ( "initCssUnit sets the unit for both axes when both axes are initialised"
      , PerspectiveOrigin.initXY "el" 100 100
            >> PerspectiveOrigin.initCssUnit Cqw
      , Selector.style "perspective-origin" "100cqw 100cqw"
      )
    , ( "initCssUnit sets the unit for both axes when only the X axis is initialised"
      , PerspectiveOrigin.initX "el" 100
            >> PerspectiveOrigin.initCssUnit Cqw
      , Selector.style "perspective-origin" "100cqw 50cqw"
      )
    , ( "initCssUnit sets the unit for both axes when only the Y axis is initialised"
      , PerspectiveOrigin.initY "el" 100
            >> PerspectiveOrigin.initCssUnit Cqw
      , Selector.style "perspective-origin" "50cqw 100cqw"
      )
    , ( "initCssUnit* overrides initCssUnit on their respective axes only"
      , PerspectiveOrigin.initXY "el" 100 100
            >> PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initCssUnitX Vw
            >> PerspectiveOrigin.initCssUnitY Vh
      , Selector.style "perspective-origin" "100vw 100vh"
      )
    , ( "initCssUnitX overrides initCssUnit on the X axis only"
      , PerspectiveOrigin.initXY "el" 100 100
            >> PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initCssUnitX Vw
      , Selector.style "perspective-origin" "100vw 100cqw"
      )
    , ( "initCssUnitY overrides initCssUnit on the Y axis only"
      , PerspectiveOrigin.initXY "el" 100 100
            >> PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initCssUnitY Vh
      , Selector.style "perspective-origin" "100cqw 100vh"
      )
    , ( "initCssUnitX overrides initCssUnit when the X axis is not initialised"
      , PerspectiveOrigin.initY "el" 100
            >> PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initCssUnitX Vw
      , Selector.style "perspective-origin" "50vw 100cqw"
      )
    , ( "initCssUnitY overrides initCssUnit when the Y axis is not initialised"
      , PerspectiveOrigin.initX "el" 100
            >> PerspectiveOrigin.initCssUnit Cqw
            >> PerspectiveOrigin.initCssUnitY Vh
      , Selector.style "perspective-origin" "100cqw 50vh"
      )
    ]


perspectiveOriginInitCssUnitTests : Test
perspectiveOriginInitCssUnitTests =
    describe "PerspectiveOrigin.cssUnit configuration"
        [ describe "Transition Engine"
            (List.map
                (\( description, config, expectation ) ->
                    test description <|
                        \_ ->
                            initTransitionWith [ config ]
                                |> queryTransition
                                |> Query.has [ expectation ]
                )
                perspectiveOriginInitCssUnitConfigs
            )
        , describe "WAAPI Engine"
            (List.map
                (\( description, config, expectation ) ->
                    test description <|
                        \_ ->
                            initWAAPIWith [ config ]
                                |> queryWAAPI
                                |> Query.has [ expectation ]
                )
                perspectiveOriginInitCssUnitConfigs
            )
        ]


perspectiveOriginSingleAnimationCssUnitConfigs : List ( ( String, AnimBuilder eng -> AnimBuilder eng, AnimBuilder eng -> AnimBuilder eng ), Selector.Selector )
perspectiveOriginSingleAnimationCssUnitConfigs =
    [ ( ( "cssUnit is preserved during animation"
        , PerspectiveOrigin.initXY "el" 50 25
            >> PerspectiveOrigin.initCssUnit Cqw
        , PerspectiveOrigin.begin
            >> PerspectiveOrigin.toXY 100 50
            >> PerspectiveOrigin.end
        )
      , Selector.style "perspective-origin" "100cqw 50cqw"
      )
    , ( ( "cssUnit changes the unit for both axes for an animation"
        , PerspectiveOrigin.initXY "el" 50 25
            >> PerspectiveOrigin.initCssUnit Cqw
        , PerspectiveOrigin.begin
            >> PerspectiveOrigin.cssUnit Cqh
            >> PerspectiveOrigin.toXY 100 50
            >> PerspectiveOrigin.end
        )
      , Selector.style "perspective-origin" "100cqh 50cqh"
      )
    , ( ( "cssUnitX changes the unit for the X axis for an animation"
        , PerspectiveOrigin.initXY "el" 50 25
            >> PerspectiveOrigin.initCssUnit Cqw
        , PerspectiveOrigin.begin
            >> PerspectiveOrigin.cssUnitX Cqh
            >> PerspectiveOrigin.toXY 100 50
            >> PerspectiveOrigin.end
        )
      , Selector.style "perspective-origin" "100cqh 50cqw"
      )
    , ( ( "cssUnitY changes the unit for the Y axis for an animation"
        , PerspectiveOrigin.initXY "el" 50 25
            >> PerspectiveOrigin.initCssUnit Cqw
        , PerspectiveOrigin.begin
            >> PerspectiveOrigin.cssUnitY Cqh
            >> PerspectiveOrigin.toXY 100 50
            >> PerspectiveOrigin.end
        )
      , Selector.style "perspective-origin" "100cqw 50cqh"
      )
    ]


perspectiveOriginSingleAnimationCssUnitTests : Test
perspectiveOriginSingleAnimationCssUnitTests =
    describe "PerspectiveOrigin.cssUnit single animation"
        [ describe "Transition Engine"
            (List.map
                (\( ( description, config, animation ), expectation ) ->
                    test description <|
                        \_ ->
                            let
                                state =
                                    initTransitionWith [ config ]
                            in
                            (Transition.animate state <|
                                Transition.for "el"
                                    >> animation
                            )
                                |> queryTransition
                                |> Query.has [ expectation ]
                )
                perspectiveOriginSingleAnimationCssUnitConfigs
            )
        ]


perspectiveOriginMultipleAnimationsCssUnitConfigs : List ( ( String, List (AnimBuilder eng -> AnimBuilder eng), List ( String, AnimBuilder a -> AnimBuilder a ) ), List ( String, Selector.Selector ) )
perspectiveOriginMultipleAnimationsCssUnitConfigs =
    [ ( ( "cssUnit changes only the targeted animation"
        , [ PerspectiveOrigin.initXY "el" 50 25
                >> PerspectiveOrigin.initCssUnit Cqw
          , PerspectiveOrigin.initXY "el2" 50 25
                >> PerspectiveOrigin.initCssUnit Px
          ]
        , [ ( "el"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnit Cqh
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          , ( "el2"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          ]
        )
      , [ ( "el", Selector.style "perspective-origin" "100cqh 50cqh" )
        , ( "el2", Selector.style "perspective-origin" "100px 50px" )
        ]
      )
    , ( ( "cssUnit changes the unit for all targeted animations"
        , [ PerspectiveOrigin.initXY "el" 50 25
                >> PerspectiveOrigin.initCssUnit Cqw
          , PerspectiveOrigin.initXY "el2" 50 25
                >> PerspectiveOrigin.initCssUnit Px
          ]
        , [ ( "el"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnit Cqh
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          , ( "el2"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnit Percent
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          ]
        )
      , [ ( "el", Selector.style "perspective-origin" "100cqh 50cqh" )
        , ( "el2", Selector.style "perspective-origin" "100% 50%" )
        ]
      )
    , ( ( "cssUnitX changes the unit for all targeted animations"
        , [ PerspectiveOrigin.initXY "el" 50 25
                >> PerspectiveOrigin.initCssUnit Cqw
          , PerspectiveOrigin.initXY "el2" 50 25
                >> PerspectiveOrigin.initCssUnit Px
          ]
        , [ ( "el"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnitX Cqh
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          , ( "el2"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnitX Percent
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          ]
        )
      , [ ( "el", Selector.style "perspective-origin" "100cqh 50cqw" )
        , ( "el2", Selector.style "perspective-origin" "100% 50px" )
        ]
      )
    , ( ( "cssUnitY changes the unit for all targeted animations"
        , [ PerspectiveOrigin.initXY "el" 50 25
                >> PerspectiveOrigin.initCssUnit Cqw
          , PerspectiveOrigin.initXY "el2" 50 25
                >> PerspectiveOrigin.initCssUnit Px
          ]
        , [ ( "el"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnitY Cqh
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          , ( "el2"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnitY Percent
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          ]
        )
      , [ ( "el", Selector.style "perspective-origin" "100cqw 50cqh" )
        , ( "el2", Selector.style "perspective-origin" "100px 50%" )
        ]
      )
    , ( ( "cssUnitX and cssUnitY operate independently for all targeted animations"
        , [ PerspectiveOrigin.initXY "el" 50 25
                >> PerspectiveOrigin.initCssUnit Cqw
          , PerspectiveOrigin.initXY "el2" 50 25
                >> PerspectiveOrigin.initCssUnit Px
          ]
        , [ ( "el"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnitX Cqh
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          , ( "el2"
            , PerspectiveOrigin.begin
                >> PerspectiveOrigin.cssUnitY Percent
                >> PerspectiveOrigin.toXY 100 50
                >> PerspectiveOrigin.end
            )
          ]
        )
      , [ ( "el", Selector.style "perspective-origin" "100cqh 50cqw" )
        , ( "el2", Selector.style "perspective-origin" "100px 50%" )
        ]
      )
    ]


perspectiveOriginMultipleAnimationCssUnitTests : Test
perspectiveOriginMultipleAnimationCssUnitTests =
    describe "PerspectiveOrigin.cssUnit multiple animations"
        [ describe "Transition Engine"
            (List.map
                (\( ( description, config, animations ), expectations ) ->
                    test description <|
                        \_ ->
                            let
                                animState =
                                    initTransitionWith config

                                anims =
                                    List.foldl
                                        (\( animGroup, animation ) acc ->
                                            acc
                                                >> Transition.for animGroup
                                                >> animation
                                        )
                                        identity
                                        animations
                            in
                            Transition.animate animState anims
                                |> Expect.all
                                    (List.map
                                        (\( animGroup, expectation ) ->
                                            queryTransitionFor animGroup
                                                >> Query.has [ expectation ]
                                        )
                                        expectations
                                    )
                )
                perspectiveOriginMultipleAnimationsCssUnitConfigs
            )
        ]



-- ============================================================
-- SIZE
-- ============================================================


sizeInitCssUnitConfigs : List ( String, AnimBuilder eng -> AnimBuilder eng, List Selector.Selector )
sizeInitCssUnitConfigs =
    [ ( "default unit (px) is used when initCssUnit is not called"
      , Size.initHW "el" 25 25
      , [ Selector.style "height" "25px"
        , Selector.style "width" "25px"
        ]
      )
    , ( "order matters - initCssUnit before initHW has no effect"
      , Size.initCssUnit Cqw
            >> Size.initHW "el" 100 100
      , [ Selector.style "height" "100px"
        , Selector.style "width" "100px"
        ]
      )
    , ( "order matters - initCssUnit before initH has no effect"
      , Size.initCssUnit Cqw
            >> Size.initH "el" 100
      , [ Selector.style "height" "100px"
        , Selector.style "width" "0px"
        ]
      )
    , ( "order matters - initCssUnit before initW has no effect"
      , Size.initCssUnit Cqw
            >> Size.initW "el" 100
      , [ Selector.style "height" "0px"
        , Selector.style "width" "100px"
        ]
      )
    , ( "initCssUnit sets the unit for both sides when both sides are initialised"
      , Size.initHW "el" 100 100
            >> Size.initCssUnit Cqw
      , [ Selector.style "height" "100cqw"
        , Selector.style "width" "100cqw"
        ]
      )
    , ( "initCssUnit sets the unit for both sides when only the height is initialised"
      , Size.initH "el" 100
            >> Size.initCssUnit Cqw
      , [ Selector.style "height" "100cqw"
        , Selector.style "width" "0cqw"
        ]
      )
    , ( "initCssUnit sets the unit for both sides when only the width is initialised"
      , Size.initW "el" 100
            >> Size.initCssUnit Cqw
      , [ Selector.style "height" "0cqw"
        , Selector.style "width" "100cqw"
        ]
      )
    , ( "initCssUnitH overrides initCssUnit on the height only"
      , Size.initHW "el" 100 100
            >> Size.initCssUnit Cqw
            >> Size.initCssUnitH Vw
      , [ Selector.style "height" "100vw"
        , Selector.style "width" "100cqw"
        ]
      )
    , ( "initCssUnitW overrides initCssUnit on the width only"
      , Size.initHW "el" 100 100
            >> Size.initCssUnit Cqw
            >> Size.initCssUnitW Vh
      , [ Selector.style "height" "100cqw"
        , Selector.style "width" "100vh"
        ]
      )
    , ( "initCssUnitH overrides initCssUnit when the height is not initialized"
      , Size.initW "el" 100
            >> Size.initCssUnit Cqw
            >> Size.initCssUnitH Vw
      , [ Selector.style "height" "0vw"
        , Selector.style "width" "100cqw"
        ]
      )
    , ( "initCssUnitW overrides initCssUnit when the width is not initialized"
      , Size.initH "el" 100
            >> Size.initCssUnit Cqw
            >> Size.initCssUnitW Vh
      , [ Selector.style "height" "100cqw"
        , Selector.style "width" "0vh"
        ]
      )
    ]


sizeInitCssUnitTests : Test
sizeInitCssUnitTests =
    describe "Size.initCssUnit configurations"
        [ describe "Transition Engine"
            (List.map
                (\( description, config, expectations ) ->
                    test description <|
                        \_ ->
                            initTransitionWith [ config ]
                                |> queryTransition
                                |> Expect.all
                                    [ Query.has expectations ]
                )
                sizeInitCssUnitConfigs
            )
        , describe "WAAPI Engine"
            (List.map
                (\( description, config, expectations ) ->
                    test description <|
                        \_ ->
                            initWAAPIWith [ config ]
                                |> queryWAAPI
                                |> Expect.all
                                    [ Query.has expectations ]
                )
                sizeInitCssUnitConfigs
            )
        ]


sizeSingleAnimationCssUnitConfigs : List ( ( String, AnimBuilder eng -> AnimBuilder eng, AnimBuilder eng -> AnimBuilder eng ), List Selector.Selector )
sizeSingleAnimationCssUnitConfigs =
    [ ( ( "cssUnit is preserved during animation"
        , Size.initHW "el" 50 25
            >> Size.initCssUnit Cqw
        , Size.begin
            >> Size.toHW 100 50
            >> Size.end
        )
      , [ Selector.style "height" "100cqw"
        , Selector.style "width" "50cqw"
        ]
      )
    , ( ( "cssUnit changes the unit for both sides for an animation"
        , Size.initHW "el" 50 25
            >> Size.initCssUnit Cqw
        , Size.begin
            >> Size.cssUnit Cqh
            >> Size.toHW 100 50
            >> Size.end
        )
      , [ Selector.style "height" "100cqh"
        , Selector.style "width" "50cqh"
        ]
      )
    , ( ( "cssUnitX changes the unit for the X axis for an animation"
        , Size.initHW "el" 50 25
            >> Size.initCssUnit Cqw
        , Size.begin
            >> Size.cssUnitH Cqh
            >> Size.toHW 100 50
            >> Size.end
        )
      , [ Selector.style "height" "100cqh"
        , Selector.style "width" "50cqw"
        ]
      )
    , ( ( "cssUnitW changes the unit for the width for an animation"
        , Size.initHW "el" 50 25
            >> Size.initCssUnit Cqw
        , Size.begin
            >> Size.cssUnitW Cqh
            >> Size.toHW 100 50
            >> Size.end
        )
      , [ Selector.style "height" "100cqw"
        , Selector.style "width" "50cqh"
        ]
      )
    ]


sizeSingleAnimationCssUnitTests : Test
sizeSingleAnimationCssUnitTests =
    describe "Size.cssUnit single animation"
        [ describe "Transition Engine"
            (List.map
                (\( ( description, config, animation ), expectation ) ->
                    test description <|
                        \_ ->
                            let
                                state =
                                    initTransitionWith [ config ]
                            in
                            (Transition.animate state <|
                                Transition.for "el"
                                    >> animation
                            )
                                |> queryTransition
                                |> Expect.all [ Query.has expectation ]
                )
                sizeSingleAnimationCssUnitConfigs
            )
        ]


sizeMultipleAnimationsCssUnitConfigs : List ( ( String, List (AnimBuilder eng -> AnimBuilder eng), List ( String, AnimBuilder a -> AnimBuilder a ) ), List ( String, List Selector.Selector ) )
sizeMultipleAnimationsCssUnitConfigs =
    [ ( ( "cssUnit changes only the targeted animation"
        , [ Size.initHW "el" 50 25
                >> Size.initCssUnit Cqw
          , Size.initHW "el2" 50 25
                >> Size.initCssUnit Px
          ]
        , [ ( "el"
            , Size.begin
                >> Size.cssUnit Cqh
                >> Size.toHW 100 50
                >> Size.end
            )
          , ( "el2"
            , Size.begin
                >> Size.toHW 100 50
                >> Size.end
            )
          ]
        )
      , [ ( "el"
          , [ Selector.style "height" "100cqh"
            , Selector.style "width" "50cqh"
            ]
          )
        , ( "el2"
          , [ Selector.style "height" "100px"
            , Selector.style "width" "50px"
            ]
          )
        ]
      )
    , ( ( "cssUnit changes the unit for all targeted animations"
        , [ Size.initHW "el" 50 25
                >> Size.initCssUnit Cqw
          , Size.initHW "el2" 50 25
                >> Size.initCssUnit Px
          ]
        , [ ( "el"
            , Size.begin
                >> Size.cssUnit Cqh
                >> Size.toHW 100 50
                >> Size.end
            )
          , ( "el2"
            , Size.begin
                >> Size.cssUnit Percent
                >> Size.toHW 100 50
                >> Size.end
            )
          ]
        )
      , [ ( "el"
          , [ Selector.style "height" "100cqh"
            , Selector.style "width" "50cqh"
            ]
          )
        , ( "el2"
          , [ Selector.style "height" "100%"
            , Selector.style "width" "50%"
            ]
          )
        ]
      )
    , ( ( "cssUnitW changes the unit for all targeted animations"
        , [ Size.initHW "el" 50 25
                >> Size.initCssUnit Cqw
          , Size.initHW "el2" 50 25
                >> Size.initCssUnit Px
          ]
        , [ ( "el"
            , Size.begin
                >> Size.cssUnitW Cqh
                >> Size.toHW 100 50
                >> Size.end
            )
          , ( "el2"
            , Size.begin
                >> Size.cssUnitW Percent
                >> Size.toHW 100 50
                >> Size.end
            )
          ]
        )
      , [ ( "el"
          , [ Selector.style "height" "100cqw"
            , Selector.style "width" "50cqh"
            ]
          )
        , ( "el2"
          , [ Selector.style "height" "100px"
            , Selector.style "width" "50%"
            ]
          )
        ]
      )
    , ( ( "cssUnitH changes the unit for all targeted animations"
        , [ Size.initHW "el" 50 25
                >> Size.initCssUnit Cqw
          , Size.initHW "el2" 50 25
                >> Size.initCssUnit Px
          ]
        , [ ( "el"
            , Size.begin
                >> Size.cssUnitH Cqh
                >> Size.toHW 100 50
                >> Size.end
            )
          , ( "el2"
            , Size.begin
                >> Size.cssUnitH Percent
                >> Size.toHW 100 50
                >> Size.end
            )
          ]
        )
      , [ ( "el"
          , [ Selector.style "height" "100cqh"
            , Selector.style "width" "50cqw"
            ]
          )
        , ( "el2"
          , [ Selector.style "height" "100%"
            , Selector.style "width" "50px"
            ]
          )
        ]
      )
    , ( ( "cssUnitH and cssUnitW operate independently for all targeted animations"
        , [ Size.initHW "el" 50 25
                >> Size.initCssUnit Cqw
          , Size.initHW "el2" 50 25
                >> Size.initCssUnit Px
          ]
        , [ ( "el"
            , Size.begin
                >> Size.cssUnitW Cqh
                >> Size.toHW 100 50
                >> Size.end
            )
          , ( "el2"
            , Size.begin
                >> Size.cssUnitH Percent
                >> Size.toHW 100 50
                >> Size.end
            )
          ]
        )
      , [ ( "el"
          , [ Selector.style "height" "100cqw"
            , Selector.style "width" "50cqh"
            ]
          )
        , ( "el2"
          , [ Selector.style "height" "100%"
            , Selector.style "width" "50px"
            ]
          )
        ]
      )
    ]


sizeMultipleAnimationCssUnitTests : Test
sizeMultipleAnimationCssUnitTests =
    describe "Size.cssUnit multiple animations"
        [ describe "Transition Engine"
            (List.map
                (\( ( description, config, animations ), expectations ) ->
                    test description <|
                        \_ ->
                            let
                                animState =
                                    initTransitionWith config

                                anims =
                                    List.foldl
                                        (\( animGroup, animation ) acc ->
                                            acc
                                                >> Transition.for animGroup
                                                >> animation
                                        )
                                        identity
                                        animations
                            in
                            Transition.animate animState anims
                                |> Expect.all
                                    (List.map
                                        (\( animGroup, expectation ) ->
                                            queryTransitionFor animGroup
                                                >> Query.has expectation
                                        )
                                        expectations
                                    )
                )
                sizeMultipleAnimationsCssUnitConfigs
            )
        ]



-- ============================================================
-- TRANSLATE
-- ============================================================


translateInitCssUnitConfigs : List ( String, AnimBuilder eng -> AnimBuilder eng, Selector.Selector )
translateInitCssUnitConfigs =
    [ ( "default unit (px) is used when initCssUnit is not called"
      , Translate.initXY "el" 25 25
      , Selector.style "translate" "25px 25px 0px"
      )
    , ( "order matters - initCssUnit before initXYZ has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initXYZ "el" 100 100 100
      , Selector.style "translate" "100px 100px 100px"
      )
    , ( "order matters - initCssUnit before initXY has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initXY "el" 100 100
      , Selector.style "translate" "100px 100px 0px"
      )
    , ( "order matters - initCssUnit before initXZ has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initXZ "el" 100 100
      , Selector.style "translate" "100px 0px 100px"
      )
    , ( "order matters - initCssUnit before initYZ has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initYZ "el" 100 100
      , Selector.style "translate" "0px 100px 100px"
      )
    , ( "order matters - initCssUnit before initX has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initX "el" 100
      , Selector.style "translate" "100px 0px 0px"
      )
    , ( "order matters - initCssUnit before initY has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initY "el" 100
      , Selector.style "translate" "0px 100px 0px"
      )
    , ( "order matters - initCssUnit before initZ has no effect"
      , Translate.initCssUnit Cqw
            >> Translate.initZ "el" 100
      , Selector.style "translate" "0px 0px 100px"
      )
    , ( "initCssUnit sets the unit for all axes when all axes are initialised"
      , Translate.initXYZ "el" 100 100 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "100cqw 100cqw 100cqw"
      )
    , ( "initCssUnit sets the unit for all axes when both X and Y axes are initialised"
      , Translate.initXY "el" 100 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "100cqw 100cqw 0cqw"
      )
    , ( "initCssUnit sets the unit for all axes when both X and Z axes are initialised"
      , Translate.initXZ "el" 100 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "100cqw 0cqw 100cqw"
      )
    , ( "initCssUnit sets the unit for all axes when both Y and Z axes are initialised"
      , Translate.initYZ "el" 100 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "0cqw 100cqw 100cqw"
      )
    , ( "initCssUnit sets the unit for all axes when only the X axis is initialised"
      , Translate.initX "el" 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "100cqw 0cqw 0cqw"
      )
    , ( "initCssUnit sets the unit for all axes when only the Y axis is initialised"
      , Translate.initY "el" 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "0cqw 100cqw 0cqw"
      )
    , ( "initCssUnit sets the unit for all axes when only the Z axis is initialised"
      , Translate.initZ "el" 100
            >> Translate.initCssUnit Cqw
      , Selector.style "translate" "0cqw 0cqw 100cqw"
      )
    , ( "initCssUnitX overrides initCssUnit on the X axis only"
      , Translate.initX "el" 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitX Vw
      , Selector.style "translate" "100vw 0cqw 0cqw"
      )
    , ( "initCssUnitY overrides initCssUnit on the Y axis only"
      , Translate.initY "el" 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitY Vh
      , Selector.style "translate" "0cqw 100vh 0cqw"
      )
    , ( "initCssUnitZ overrides initCssUnit on the Z axis only"
      , Translate.initZ "el" 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitZ Vw
      , Selector.style "translate" "0cqw 0cqw 100vw"
      )
    , ( "initCssUnit* overrides initCssUnit on their respective axes"
      , Translate.initXYZ "el" 100 100 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitX Vw
            >> Translate.initCssUnitY Vh
            >> Translate.initCssUnitZ Percent
      , Selector.style "translate" "100vw 100vh 100%"
      )
    , ( "initCssUnitX overrides initCssUnit when only the X axis is not initialised"
      , Translate.initYZ "el" 100 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitX Vw
      , Selector.style "translate" "0vw 100cqw 100cqw"
      )
    , ( "initCssUnitY overrides initCssUnit when only the Y axis is not initialised"
      , Translate.initXZ "el" 100 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitY Vh
      , Selector.style "translate" "100cqw 0vh 100cqw"
      )
    , ( "initCssUnitZ overrides initCssUnit when only the Z axis is not initialised"
      , Translate.initXY "el" 100 100
            >> Translate.initCssUnit Cqw
            >> Translate.initCssUnitZ Vw
      , Selector.style "translate" "100cqw 100cqw 0vw"
      )
    ]


translateInitCssUnitTests : Test
translateInitCssUnitTests =
    describe "Translate.cssUnit configuration"
        [ describe "Transition Engine"
            (List.map
                (\( description, config, expectation ) ->
                    test description <|
                        \_ ->
                            initTransitionWith [ config ]
                                |> queryTransition
                                |> Query.has [ expectation ]
                )
                translateInitCssUnitConfigs
            )

        -- TODO: These need to be handled differently to the Transition Engine tests
        -- The WAAPI engine writes the translate values to the `transform` style property
        -- Other Engines probably do too.
        {-
           , describe "WAAPI Engine"
               (List.map
                   (\( description, config, expectation ) ->
                       test description <|
                           \_ ->
                               initWAAPIWith config
                                   |> queryWAAPI
                                   |> expectation
                   )
                   translateInitCssUnitConfigs
               )
        -}
        ]
