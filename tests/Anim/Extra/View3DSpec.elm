module Anim.Extra.View3DSpec exposing (suite)

{-| Tests for `Anim.Extra.View3D`.

The module is pure: each function returns an `Html.Attribute` produced
by `style`. We render each attribute on an empty div and assert the
resulting CSS via `Test.Html.Selector.style`.

Coverage:

  - `perspective` formats its `Float` as `Npx`.
  - `perspectiveOrigin` maps every `PerspectiveOrigin` constructor to
    the canonical two-word CSS string (or `n% n%` / `npx npx`).
  - `backfaceVisibility` and `transformStyle` map each variant to the
    correct keyword.
  - `opacityHack` emits the exact `0.99` value documented in the
    module — anything else breaks the GPU-compositor workaround.

-}

import Anim.Extra.View3D as View3D
    exposing
        ( BackfaceVisibility(..)
        , PerspectiveOrigin(..)
        , TransformStyle(..)
        )
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


rendered : Html.Attribute msg -> Query.Single msg
rendered attr =
    Html.div [ attr ] []
        |> Query.fromHtml


suite : Test
suite =
    describe "Anim.Extra.View3D"
        [ perspectiveTests
        , perspectiveOriginTests
        , backfaceVisibilityTests
        , transformStyleTests
        , opacityHackTests
        ]



-- ============================================================
-- perspective
-- ============================================================


perspectiveTests : Test
perspectiveTests =
    describe "perspective"
        [ test "renders integer-like value as Npx" <|
            \_ ->
                View3D.perspective 1000
                    |> rendered
                    |> Query.has [ Selector.style "perspective" "1000px" ]
        , test "renders fractional value with decimal point" <|
            \_ ->
                View3D.perspective 1234.5
                    |> rendered
                    |> Query.has [ Selector.style "perspective" "1234.5px" ]
        ]



-- ============================================================
-- perspectiveOrigin
-- ============================================================


perspectiveOriginTests : Test
perspectiveOriginTests =
    describe "perspectiveOrigin"
        (List.map originCase
            [ ( Center, "center center" )
            , ( TopLeft, "left top" )
            , ( TopCenter, "center top" )
            , ( TopRight, "right top" )
            , ( LeftMiddle, "left center" )
            , ( RightMiddle, "right center" )
            , ( BottomLeft, "left bottom" )
            , ( BottomCenter, "center bottom" )
            , ( BottomRight, "right bottom" )
            , ( Percent 25 75, "25% 75%" )
            , ( Px 100 200, "100px 200px" )
            ]
        )


originCase : ( PerspectiveOrigin, String ) -> Test
originCase ( origin, expected ) =
    test ("perspectiveOrigin " ++ expected) <|
        \_ ->
            View3D.perspectiveOrigin origin
                |> rendered
                |> Query.has [ Selector.style "perspective-origin" expected ]



-- ============================================================
-- backfaceVisibility
-- ============================================================


backfaceVisibilityTests : Test
backfaceVisibilityTests =
    describe "backfaceVisibility"
        [ test "Visible renders \"visible\"" <|
            \_ ->
                View3D.backfaceVisibility Visible
                    |> rendered
                    |> Query.has [ Selector.style "backface-visibility" "visible" ]
        , test "Hidden renders \"hidden\"" <|
            \_ ->
                View3D.backfaceVisibility Hidden
                    |> rendered
                    |> Query.has [ Selector.style "backface-visibility" "hidden" ]
        ]



-- ============================================================
-- transformStyle
-- ============================================================


transformStyleTests : Test
transformStyleTests =
    describe "transformStyle"
        [ test "Flat renders \"flat\"" <|
            \_ ->
                View3D.transformStyle Flat
                    |> rendered
                    |> Query.has [ Selector.style "transform-style" "flat" ]
        , test "Preserve3D renders \"preserve-3d\"" <|
            \_ ->
                View3D.transformStyle Preserve3D
                    |> rendered
                    |> Query.has [ Selector.style "transform-style" "preserve-3d" ]
        ]



-- ============================================================
-- opacityHack
-- ============================================================
--
-- The exact value matters: 0.99 forces a new compositor layer without
-- visibly affecting opacity. 1.0 disables the workaround; any value
-- below 0.99 introduces visible transparency.


opacityHackTests : Test
opacityHackTests =
    describe "opacityHack"
        [ test "renders opacity: 0.99 exactly" <|
            \_ ->
                View3D.opacityHack
                    |> rendered
                    |> Query.has [ Selector.style "opacity" "0.99" ]
        ]
