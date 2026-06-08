module Anim.Engine.Transition.RetargetSpec exposing (suite)

{-| End-to-end tests for `Transition.retarget`.

The Transition engine has no JavaScript-side runtime snapshot of the
currently rendered values, so `retarget` cannot smoothly continue an
in-flight transition. Instead it snaps to the freshly computed end values
with `transition: none` and marks the group complete - safe to call
repeatedly during a drag or resize without accumulating partial
transitions.

-}

import Anim.Engine.Transition as Transition
import Anim.Internal.Engine.CSS.CSS as CSS
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.Transition.AnimGroup as TAnimGroup
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Expect
import Motion.Easing exposing (Easing(..))
import Set
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.Transition retarget"
        [ propertyKeysTests
        , snapTests
        , scopingTests
        , resetAfterRetargetTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


initState : Transition.AnimState
initState =
    Transition.init [ Translate.initXY "el" 0 0 ]


cqwInitState : Transition.AnimState
cqwInitState =
    Transition.init
        [ Translate.initXY "el" 0 0
            >> Translate.cssUnitX Cqw
            >> Translate.cssUnitY Cqh
        ]


stylesFor : String -> Transition.AnimState -> Maybe Styles
stylesFor groupName (CSS.AnimState _ animGroups) =
    AnimGroups.get groupName animGroups
        |> Maybe.map TAnimGroup.getStyles


transitionCss : String -> Transition.AnimState -> Maybe String
transitionCss groupName state =
    stylesFor groupName state
        |> Maybe.andThen (Styles.get "transition")


propertyKeysFor : String -> Transition.AnimState -> Maybe (List String)
propertyKeysFor groupName (CSS.AnimState _ animGroups) =
    AnimGroups.get groupName animGroups
        |> Maybe.map (TAnimGroup.getPropertyKeys >> setToSortedList)


setToSortedList : Set.Set String -> List String
setToSortedList =
    Set.toList >> List.sort



-- ============================================================
-- propertyKeys (low-level state tracking)
-- ============================================================


propertyKeysTests : Test
propertyKeysTests =
    describe "property keys reported by AnimGroup"
        [ test "animate populates propertyKeys with every Builder key in the group" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.end
                                    >> Opacity.begin
                                    >> Opacity.to 0.5
                                    >> Opacity.duration 500
                                    >> Opacity.end
                                )
                       )
                    |> propertyKeysFor "el"
                    |> Expect.equal (Just [ "opacity", "translate" ])
        , test "second animate on the same group merges existing + new keys" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Opacity.begin
                                    >> Opacity.to 0.5
                                    >> Opacity.duration 500
                                    >> Opacity.end
                                )
                       )
                    |> propertyKeysFor "el"
                    |> Expect.equal (Just [ "opacity", "translate" ])
        ]



-- ============================================================
-- SNAP SEMANTICS
-- ============================================================


snapTests : Test
snapTests =
    describe "retarget snaps to the new end values with transition: none"
        [ test "retarget on a running group emits transition: none" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.easing BounceOut
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 300
                                    >> Translate.end
                                )
                       )
                    |> transitionCss "el"
                    |> Expect.equal (Just "none")
        , test "retarget sets the new value styles on the group" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 300
                                    >> Translate.end
                                )
                       )
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "translate")
                    |> Maybe.map (String.contains "300px")
                    |> Expect.equal (Just True)
        , test "retarget on an idle group also snaps (transition: none)" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toX 250
                                    >> Translate.end
                                )
                       )
                    |> transitionCss "el"
                    |> Expect.equal (Just "none")
        , test "transition-behavior is cleared so the snap is unambiguous" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Opacity.begin
                                    >> Opacity.to 1
                                    >> Opacity.duration 500
                                    >> Opacity.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "el"
                                    >> Opacity.begin
                                    >> Opacity.to 0
                                    >> Opacity.end
                                )
                       )
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "transition-behavior")
                    |> Expect.equal Nothing
        ]



-- ============================================================
-- SCOPING
-- ============================================================


scopingTests : Test
scopingTests =
    describe "retarget scoping"
        [ test "retarget on group B does not snap group A's in-flight transition" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "a"
                                    >> Translate.begin
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "b"
                                    >> Translate.begin
                                    >> Translate.toX 300
                                    >> Translate.end
                                )
                       )
                    |> transitionCss "a"
                    |> Maybe.map (String.contains "500ms")
                    |> Expect.equal (Just True)
        , test "retarget snaps the touched group only" <|
            \_ ->
                initState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "a"
                                    >> Translate.begin
                                    >> Translate.toX 100
                                    >> Translate.duration 500
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "b"
                                    >> Translate.begin
                                    >> Translate.toX 300
                                    >> Translate.end
                                )
                       )
                    |> transitionCss "b"
                    |> Expect.equal (Just "none")
        ]



-- ============================================================
-- RESET AFTER RETARGET
-- ============================================================


resetAfterRetargetTests : Test
resetAfterRetargetTests =
    describe "reset after retarget returns to the original animate's start, not the retarget's synthesised start"
        [ test "animate XY 0->88, retarget Y to 0, reset -> snaps back to 0 0" <|
            \_ ->
                cqwInitState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 88 88
                                    >> Translate.duration 5000
                                    >> Translate.easing Linear
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toY 0
                                    >> Translate.end
                                )
                       )
                    |> Transition.reset "el"
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "translate")
                    |> Expect.equal (Just "0cqw 0cqh 0px")
        , test "two full A→R→Reset cycles - the second reset still snaps to 0 0" <|
            \_ ->
                let
                    runCycle s =
                        s
                            |> (\inner ->
                                    Transition.animate inner <|
                                        (Transition.for "el"
                                            >> Translate.begin
                                            >> Translate.toXY 88 88
                                            >> Translate.duration 5000
                                            >> Translate.easing Linear
                                            >> Translate.end
                                        )
                               )
                            |> (\inner ->
                                    Transition.retarget inner <|
                                        (Transition.for "el"
                                            >> Translate.begin
                                            >> Translate.toY 0
                                            >> Translate.end
                                        )
                               )
                            |> Transition.reset "el"
                in
                cqwInitState
                    |> runCycle
                    |> runCycle
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "translate")
                    |> Expect.equal (Just "0cqw 0cqh 0px")
        , test "A→R→Reset→A - the next animate's start is the original anchor, not the retarget end" <|
            \_ ->
                cqwInitState
                    |> (\s ->
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 88 88
                                    >> Translate.duration 5000
                                    >> Translate.easing Linear
                                    >> Translate.end
                                )
                       )
                    |> (\s ->
                            Transition.retarget s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toY 0
                                    >> Translate.end
                                )
                       )
                    |> Transition.reset "el"
                    |> (\s ->
                            -- Second animate: should be (0,0)->(88,88), not (88,0)->(88,88)
                            Transition.animate s <|
                                (Transition.for "el"
                                    >> Translate.begin
                                    >> Translate.toXY 88 88
                                    >> Translate.duration 5000
                                    >> Translate.easing Linear
                                    >> Translate.end
                                )
                       )
                    |> stylesFor "el"
                    |> Maybe.andThen (Styles.get "translate")
                    |> Expect.equal (Just "88cqw 88cqh 0px")
        ]
