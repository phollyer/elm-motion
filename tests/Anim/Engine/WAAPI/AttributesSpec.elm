module Anim.Engine.WAAPI.AttributesSpec exposing (suite)

{-| Tests for `WAAPI.attributes` per-property style ownership.

`Generator.init` writes only to the per-group property snapshot, leaving
`propertyStates` empty for that property. `WAAPI.animate` _also_ writes
an entry into `propertyStates`, marking the property as JS-owned for
the lifetime of the group.

`WAAPI.attributes` consults `propertyStates` to decide which inline
styles to emit:

  - Independent slots (`opacity`, `perspective-origin`, `width`/`height`,
    custom, custom-color) are emitted only when the corresponding
    property has no entry in `propertyStates`.
      - The CSS `transform` slot is emitted only when all transform
        sub-properties are Elm-owned (no active JS ownership for
        `translate`/`rotate`/`skew`/`scale`). Once WAAPI has taken ownership
        of any transform sub-property, inline transform writes are deferred to
        the JS runtime so Elm does not overwrite committed WAAPI values with
        stale snapshot data after completion.
  - The `data-anim-target` attribute is always emitted.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Expect
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "WAAPI.attributes ownership"
        [ initOnlyTests
        , animatedTests
        , mixedKindTests
        , transformSlotTests
        , dataAttrTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


fakeCommandPort : Encode.Value -> Cmd msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> msg) -> Sub msg
fakeSubscriptionPort _ =
    Sub.none


initWith : List (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState msg
initWith =
    WAAPI.init fakeCommandPort fakeSubscriptionPort


animate : (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState msg -> WAAPI.AnimState msg
animate config state =
    WAAPI.animate state config |> Tuple.first


query : WAAPI.AnimState msg -> Query.Single msg
query state =
    Html.div (WAAPI.attributes "el" state) []
        |> Query.fromHtml



-- ============================================================
-- INIT-ONLY PROPERTIES (Elm-owned)
-- ============================================================


initOnlyTests : Test
initOnlyTests =
    describe "init-only properties are rendered as inline styles"
        [ test "Translate.initX emits transform: translate3d(...)" <|
            \_ ->
                initWith [ Translate.initX "el" 100 ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
        , test "Opacity.init emits opacity" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> query
                    |> Query.has [ Selector.style "opacity" "0.5" ]
        , test "Size.init emits width and height" <|
            \_ ->
                initWith [ Size.init "el" 120 ]
                    |> query
                    |> Expect.all
                        [ Query.has [ Selector.style "width" "120px" ]
                        , Query.has [ Selector.style "height" "120px" ]
                        ]
        , test "PerspectiveOrigin.initXY emits perspective-origin" <|
            \_ ->
                initWith [ PerspectiveOrigin.initXY "el" 50 75 ]
                    |> query
                    |> Query.has [ Selector.style "perspective-origin" "50% 75%" ]
        ]



-- ============================================================
-- ANIMATED PROPERTIES (JS-owned, Elm omits)
-- ============================================================


animatedTests : Test
animatedTests =
    describe "animated properties"
        [ test "animate Opacity → opacity inline suppressed" <|
            \_ ->
                initWith []
                    |> animate
                        (WAAPI.for "el"
                            >> Opacity.begin
                            >> Opacity.to 0.5
                            >> Opacity.end
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "opacity" "0.5" ]
        , test "animate Translate → transform inline rendered from snapshot start value" <|
            \_ ->
                initWith []
                    |> animate
                        (WAAPI.for "el"
                            >> Translate.begin
                            >> Translate.toX 100
                            >> Translate.end
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "transform" "translate3d(0px, 0px, 0px)" ]
        , test "animate Rotate → transform inline rendered from snapshot start value" <|
            \_ ->
                initWith []
                    |> animate
                        (WAAPI.for "el"
                            >> Rotate.begin
                            >> Rotate.toZ 360
                            >> Rotate.end
                        )
                    |> query
                    |> Query.hasNot [ Selector.style "transform" "rotateZ(0deg)" ]
        , test "data-anim-target is still emitted for animated groups" <|
            \_ ->
                initWith []
                    |> animate
                        (WAAPI.for "el"
                            >> Opacity.begin
                            >> Opacity.to 0.5
                            >> Opacity.end
                        )
                    |> query
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "data-anim-target" "el") ]
        ]



-- ============================================================
-- MIXED KINDS (one Elm-owned, one JS-owned)
-- ============================================================


mixedKindTests : Test
mixedKindTests =
    describe "mixed kinds: each property's ownership is independent"
        [ test "init-only Translate + animated Opacity → transform inline, no opacity inline" <|
            \_ ->
                initWith [ Translate.initX "el" 100 ]
                    |> animate
                        (WAAPI.for "el"
                            >> Opacity.begin
                            >> Opacity.to 0.5
                            >> Opacity.end
                        )
                    |> query
                    |> Expect.all
                        [ Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
                        , Query.hasNot [ Selector.style "opacity" "0.5" ]
                        ]
        , test "init-only Opacity + animated Translate → opacity inline, transform inline rendered from snapshot start value" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> animate
                        (WAAPI.for "el"
                            >> Translate.begin
                            >> Translate.toX 100
                            >> Translate.end
                        )
                    |> query
                    |> Expect.all
                        [ Query.has [ Selector.style "opacity" "0.5" ]
                        , Query.hasNot [ Selector.style "transform" "translate3d(0px, 0px, 0px)" ]
                        ]
        ]



-- ============================================================
-- TRANSFORM SLOT (monolithic)
-- ============================================================


transformSlotTests : Test
transformSlotTests =
    describe "transform slot is rendered only when fully Elm-owned"
        [ test "init-only Translate + animated Rotate → transform inline suppressed while JS owns a transform sub-property" <|
            \_ ->
                initWith [ Translate.initX "el" 100 ]
                    |> animate
                        (WAAPI.for "el"
                            >> Rotate.begin
                            >> Rotate.toZ 360
                            >> Rotate.end
                        )
                    |> query
                    |> Query.hasNot
                        [ Selector.style "transform"
                            "translate3d(100px, 0px, 0px) rotateZ(0deg)"
                        ]
        , test "init-only Opacity + init-only Translate (no transform animated) → transform inline" <|
            \_ ->
                initWith
                    [ Opacity.init "el" 0.5
                    , Translate.initX "el" 100
                    ]
                    |> query
                    |> Query.has [ Selector.style "transform" "translate3d(100px, 0px, 0px)" ]
        , test "no transform configured at all → no transform inline" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> query
                    |> Query.hasNot [ Selector.style "transform" "" ]
        , test "animating Rotate after Translate.initZ suppresses inline transform while JS owns transform" <|
            \_ ->
                initWith [ Translate.initZ "el" 200 ]
                    |> animate
                        (WAAPI.for "el"
                            >> Rotate.begin
                            >> Rotate.toX 360
                            >> Rotate.end
                        )
                    |> query
                    |> Query.hasNot
                        [ Selector.style "transform"
                            "translate3d(0px, 0px, 200px) rotateZ(0deg)"
                        ]
        ]



-- ============================================================
-- data-anim-target
-- ============================================================


dataAttrTests : Test
dataAttrTests =
    describe "data-anim-target"
        [ test "is emitted for unknown groups (no init, no animate)" <|
            \_ ->
                initWith []
                    |> query
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "data-anim-target" "el") ]
        , test "is emitted for init-only groups" <|
            \_ ->
                initWith [ Opacity.init "el" 0.5 ]
                    |> query
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "data-anim-target" "el") ]
        ]
