module Anim.Engine.UnitCascadeSpec exposing (suite)

{-| End-to-end tests for the `Anim.Unit` length cascade.

Verifies the resolution order documented in `Anim.Unit`:

1.  Engine-level (`WAAPI.cssUnit`, `Transition.cssUnit`, `Keyframe.cssUnit`,
    `ScrollTimeline.cssUnit`, `ViewTimeline.cssUnit`)
2.  `Px` (built-in default) — except for `PerspectiveOrigin` which keeps
    its historical `Percent` default.

-}

import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Transition as Transition
import Anim.Engine.WAAPI as WAAPI
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Property.PerspectiveOrigin as InternalPerspectiveOrigin
import Anim.Internal.Property.Size as InternalSize
import Anim.Internal.Property.Translate as InternalTranslate
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit as Unit exposing (Unit)
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Unit length cascade"
        [ translateCascade
        , sizeCascade
        , perspectiveOriginCascade
        , engineDefaults
        ]



-- ============================================================
-- HELPERS
-- ============================================================


initBuilder : Builder.AnimBuilder eng
initBuilder =
    Builder.init []


firstGroup :
    Builder.AnimBuilder eng
    -> Maybe Builder.ProcessedAnimGroupConfig
firstGroup builder =
    Builder.process builder
        |> .groups
        |> AnimGroups.toList
        |> List.head
        |> Maybe.map Tuple.second


firstTranslateLength : Builder.AnimBuilder eng -> Maybe Unit
firstTranslateLength builder =
    firstGroup builder
        |> Maybe.andThen
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    Just cfg.cssUnit.x

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


firstSizeLength : Builder.AnimBuilder eng -> Maybe Unit
firstSizeLength builder =
    firstGroup builder
        |> Maybe.andThen
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedSizeConfig cfg ->
                                    Just cfg.cssUnit.x

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


firstPerspectiveOriginLength : Builder.AnimBuilder eng -> Maybe Unit
firstPerspectiveOriginLength builder =
    firstGroup builder
        |> Maybe.andThen
            (\group ->
                group.properties
                    |> List.filterMap
                        (\p ->
                            case p of
                                Builder.ProcessedPerspectiveOriginConfig cfg ->
                                    Just cfg.cssUnit.x

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


animateTranslate : Builder.AnimBuilder { eng | withTiming : () } -> Builder.AnimBuilder { eng | withTiming : () }
animateTranslate =
    Builder.for "box"
        >> Translate.begin
        >> Translate.toX 100
        >> Translate.end


animateSize : Builder.AnimBuilder { eng | withTiming : () } -> Builder.AnimBuilder { eng | withTiming : () }
animateSize =
    Builder.for "box"
        >> Size.begin
        >> Size.toW 200
        >> Size.end


animatePerspectiveOrigin : Builder.AnimBuilder { eng | withTiming : () } -> Builder.AnimBuilder { eng | withTiming : () }
animatePerspectiveOrigin =
    Builder.for "scene"
        >> PerspectiveOrigin.begin
        >> PerspectiveOrigin.toX 25
        >> PerspectiveOrigin.end



-- ============================================================
-- TRANSLATE CASCADE
-- ============================================================


translateCascade : Test
translateCascade =
    describe "Translate.cssUnit cascade"
        [ test "defaults to Px when nothing is set" <|
            \_ ->
                initBuilder
                    |> animateTranslate
                    |> firstTranslateLength
                    |> Expect.equal (Just Unit.Px)
        , test "engine-level WAAPI.cssUnit flows through to processed config" <|
            \_ ->
                initBuilder
                    |> WAAPI.cssUnit Unit.Vw
                    |> animateTranslate
                    |> firstTranslateLength
                    |> Expect.equal (Just Unit.Vw)
        , test "engine-level Transition.cssUnit flows through" <|
            \_ ->
                initBuilder
                    |> Transition.cssUnit Unit.Percent
                    |> animateTranslate
                    |> firstTranslateLength
                    |> Expect.equal (Just Unit.Percent)
        , test "engine-level Keyframe.cssUnit flows through" <|
            \_ ->
                initBuilder
                    |> Keyframe.cssUnit Unit.Rem
                    |> animateTranslate
                    |> firstTranslateLength
                    |> Expect.equal (Just Unit.Rem)
        ]



-- ============================================================
-- SIZE CASCADE
-- ============================================================


sizeCascade : Test
sizeCascade =
    describe "Size.cssUnit cascade"
        [ test "defaults to Px when nothing is set" <|
            \_ ->
                initBuilder
                    |> animateSize
                    |> firstSizeLength
                    |> Expect.equal (Just Unit.Px)
        , test "engine-level WAAPI.cssUnit flows through" <|
            \_ ->
                initBuilder
                    |> WAAPI.cssUnit Unit.Vh
                    |> animateSize
                    |> firstSizeLength
                    |> Expect.equal (Just Unit.Vh)
        ]



-- ============================================================
-- PERSPECTIVE ORIGIN CASCADE
-- ============================================================


perspectiveOriginCascade : Test
perspectiveOriginCascade =
    describe "PerspectiveOrigin.cssUnit cascade"
        [ test "defaults to Percent when nothing is set" <|
            \_ ->
                initBuilder
                    |> animatePerspectiveOrigin
                    |> firstPerspectiveOriginLength
                    |> Expect.equal (Just Unit.Percent)
        , test "engine-level WAAPI.cssUnit flows through" <|
            \_ ->
                initBuilder
                    |> WAAPI.cssUnit Unit.Px
                    |> animatePerspectiveOrigin
                    |> firstPerspectiveOriginLength
                    |> Expect.equal (Just Unit.Px)
        ]



-- ============================================================
-- ENGINE-LEVEL DEFAULTS — render via toCssString
-- ============================================================


engineDefaults : Test
engineDefaults =
    describe "engine-level defaults render through toCssString"
        [ test "Translate renders Vw suffix when WAAPI.cssUnit Vw is set" <|
            \_ ->
                let
                    unit =
                        initBuilder
                            |> WAAPI.cssUnit Unit.Vw
                            |> animateTranslate
                            |> firstTranslateLength
                            |> Maybe.withDefault Unit.Px
                in
                InternalTranslate.fromTriple ( 10, 20, 0 )
                    |> InternalTranslate.toCssString { x = unit, y = unit, z = unit }
                    |> Expect.equal "translate3d(10vw, 20vw, 0vw)"
        , test "Size renders Percent suffix when WAAPI.cssUnit Percent is set" <|
            \_ ->
                let
                    unit =
                        initBuilder
                            |> WAAPI.cssUnit Unit.Percent
                            |> animateSize
                            |> firstSizeLength
                            |> Maybe.withDefault Unit.Px
                in
                InternalSize.fromTuple ( 100, 200 )
                    |> InternalSize.toCssString { x = unit, y = unit, z = unit }
                    |> Expect.equal "width: 100%; height: 200%"
        , test "PerspectiveOrigin renders Px suffix when WAAPI.cssUnit Px is set" <|
            \_ ->
                let
                    unit =
                        initBuilder
                            |> WAAPI.cssUnit Unit.Px
                            |> animatePerspectiveOrigin
                            |> firstPerspectiveOriginLength
                            |> Maybe.withDefault Unit.Percent
                in
                InternalPerspectiveOrigin.fromRecord { x = 200, y = 150 }
                    |> InternalPerspectiveOrigin.toCssString { x = unit, y = unit, z = unit }
                    |> Expect.equal "200px 150px"
        ]
