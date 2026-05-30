module Motion.EasingSpec exposing (suite)

{-| Tests for `Motion.Easing` and its renderings via `Shared.Easing`.

The `Motion.Easing` module only exposes the `Easing(..)` type; the
production logic lives in `Shared.Easing`:

  - `toCSS` and `toWebAnimations` map each constructor to a CSS string
    used by the Transition / Keyframe engines and the WAAPI / Timeline
    engines respectively.
  - `toFunction` returns the actual `Float -> Float` interpolation used
    by the pure-Elm Sub engine.

These tests lock in:

1.  Every constructor produces a stable, expected `cubic-bezier` (or
    keyword) string for both CSS and WAAPI output paths.
2.  Endpoint behaviour of every easing function: `f 0 ≈ 0` and
    `f 1 ≈ 1` (the contract every easing in the library must honour).
3.  The few easings that diverge between `toCSS` and `toWebAnimations`
    (custom Back, Bounce, Elastic) hold those documented differences.
4.  The `CubicBezier` formatter stringifies its four control points
    correctly.

-}

import Expect
import Motion.Easing exposing (Easing(..))
import Shared.Easing as Easing
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Motion.Easing"
        [ toCssTests
        , toWebAnimationsTests
        , divergenceTests
        , cubicBezierTests
        , endpointTests
        , monotonicityTests
        ]



-- ============================================================
-- toCSS
-- ============================================================
--
-- Lock in the CSS string emitted for every named easing. Future tweaks
-- to the cubic-bezier table become visible diffs here.


toCssTests : Test
toCssTests =
    describe "toCSS produces the expected cubic-bezier / keyword"
        (List.map cssCase cssCases)


cssCase : ( Easing, String ) -> Test
cssCase ( easing, expected ) =
    test ("toCSS " ++ easingLabel easing ++ " -> " ++ expected) <|
        \_ ->
            Easing.toCSS (Just easing) |> Expect.equal expected


cssCases : List ( Easing, String )
cssCases =
    [ ( Linear, "linear" )
    , ( Ease, "ease" )
    , ( EaseIn, "ease-in" )
    , ( EaseOut, "ease-out" )
    , ( EaseInOut, "ease-in-out" )
    , ( SineIn, "cubic-bezier(0.12, 0, 0.39, 0)" )
    , ( SineOut, "cubic-bezier(0.61, 1, 0.88, 1)" )
    , ( SineInOut, "cubic-bezier(0.37, 0, 0.63, 1)" )
    , ( QuadIn, "cubic-bezier(0.11, 0, 0.5, 0)" )
    , ( QuadOut, "cubic-bezier(0.5, 1, 0.89, 1)" )
    , ( QuadInOut, "cubic-bezier(0.45, 0, 0.55, 1)" )
    , ( CubicIn, "cubic-bezier(0.32, 0, 0.67, 0)" )
    , ( CubicOut, "cubic-bezier(0.33, 1, 0.68, 1)" )
    , ( CubicInOut, "cubic-bezier(0.65, 0, 0.35, 1)" )
    , ( QuartIn, "cubic-bezier(0.5, 0, 0.75, 0)" )
    , ( QuartOut, "cubic-bezier(0.25, 1, 0.5, 1)" )
    , ( QuartInOut, "cubic-bezier(0.76, 0, 0.24, 1)" )
    , ( QuintIn, "cubic-bezier(0.64, 0, 0.78, 0)" )
    , ( QuintOut, "cubic-bezier(0.22, 1, 0.36, 1)" )
    , ( QuintInOut, "cubic-bezier(0.83, 0, 0.17, 1)" )
    , ( ExpoIn, "cubic-bezier(0.7, 0, 0.84, 0)" )
    , ( ExpoOut, "cubic-bezier(0.16, 1, 0.3, 1)" )
    , ( ExpoInOut, "cubic-bezier(0.87, 0, 0.13, 1)" )
    , ( CircIn, "cubic-bezier(0.55, 0, 1, 0.45)" )
    , ( CircOut, "cubic-bezier(0, 0.55, 0.45, 1)" )
    , ( CircInOut, "cubic-bezier(0.85, 0, 0.15, 1)" )
    , ( BackIn, "cubic-bezier(0.36, 0, 0.66, -0.56)" )
    , ( BackOut, "cubic-bezier(0.34, 1.56, 0.64, 1)" )
    , ( BackInOut, "cubic-bezier(0.68, -0.6, 0.32, 1.6)" )
    , ( BackInCustom 1.5, "linear" )
    , ( BackOutCustom 1.5, "linear" )
    , ( BackInOutCustom ( 1.0, 1.0 ), "linear" )
    , ( ElasticIn, "cubic-bezier(0.55, 0.055, 0.675, 0.19)" )
    , ( ElasticOut, "cubic-bezier(0.175, 0.885, 0.32, 1.275)" )
    , ( ElasticInOut, "cubic-bezier(0.445, 0.05, 0.55, 0.95)" )
    , ( BounceIn, "cubic-bezier(0.6, 0.04, 0.98, 0.335)" )
    , ( BounceOut, "cubic-bezier(0.175, 0.885, 0.32, 1.275)" )
    , ( BounceInOut, "cubic-bezier(0.445, 0.050, 0.550, 0.950)" )
    ]



-- ============================================================
-- toWebAnimations
-- ============================================================
--
-- toWebAnimations diverges from toCSS for Elastic and Bounce: the WAAPI
-- engine renders those as keyframe arrays driven by the easing function,
-- so the timing string handed to element.animate() is "linear".


toWebAnimationsTests : Test
toWebAnimationsTests =
    describe "toWebAnimations produces the expected timing string"
        (List.map waCase waCases)


waCase : ( Easing, String ) -> Test
waCase ( easing, expected ) =
    test ("toWebAnimations " ++ easingLabel easing ++ " -> " ++ expected) <|
        \_ ->
            Easing.toWebAnimations easing |> Expect.equal expected


waCases : List ( Easing, String )
waCases =
    [ ( Linear, "linear" )
    , ( Ease, "ease" )
    , ( EaseIn, "ease-in" )
    , ( EaseOut, "ease-out" )
    , ( EaseInOut, "ease-in-out" )
    , ( SineIn, "cubic-bezier(0.12, 0, 0.39, 0)" )
    , ( QuadOut, "cubic-bezier(0.5, 1, 0.89, 1)" )
    , ( CubicOut, "cubic-bezier(0.67, 0, 0.32, 1)" )
    , ( BackOut, "cubic-bezier(0.34, 1.56, 0.64, 1)" )
    , ( BackInOut, "cubic-bezier(0.68, -0.6, 0.32, 1.6)" )
    , ( BackInCustom 2, "linear" )
    , ( BackOutCustom 2, "linear" )
    , ( BackInOutCustom ( 1, 2 ), "linear" )

    -- Elastic and Bounce are sampled as keyframes by WAAPI so the
    -- timing function passed to the browser is always "linear".
    , ( ElasticIn, "linear" )
    , ( ElasticOut, "linear" )
    , ( ElasticInOut, "linear" )
    , ( BounceIn, "linear" )
    , ( BounceOut, "linear" )
    , ( BounceInOut, "linear" )
    ]



-- ============================================================
-- DIVERGENCE
-- ============================================================
--
-- These cases must NOT agree between toCSS and toWebAnimations.
-- A regression that "harmonised" them would silently change the way
-- Bounce / Elastic render on the WAAPI engine.


divergenceTests : Test
divergenceTests =
    describe "toCSS and toWebAnimations diverge for sampled easings"
        [ test "BounceIn: CSS cubic-bezier vs WAAPI linear" <|
            \_ ->
                Expect.notEqual
                    (Easing.toCSS (Just BounceIn))
                    (Easing.toWebAnimations BounceIn)
        , test "ElasticOut: CSS cubic-bezier vs WAAPI linear" <|
            \_ ->
                Expect.notEqual
                    (Easing.toCSS (Just ElasticOut))
                    (Easing.toWebAnimations ElasticOut)
        , test "CubicOut control points differ between CSS and WAAPI" <|
            \_ ->
                Expect.notEqual
                    (Easing.toCSS (Just CubicOut))
                    (Easing.toWebAnimations CubicOut)
        ]



-- ============================================================
-- CubicBezier
-- ============================================================


cubicBezierTests : Test
cubicBezierTests =
    describe "CubicBezier formatting"
        [ test "toCSS formats the four control points" <|
            \_ ->
                Easing.toCSS (Just (CubicBezier 0.1 0.2 0.3 0.4))
                    |> Expect.equal "cubic-bezier(0.1, 0.2, 0.3, 0.4)"
        , test "toWebAnimations formats the four control points" <|
            \_ ->
                Easing.toWebAnimations (CubicBezier 0.5 -0.25 0.75 1.25)
                    |> Expect.equal "cubic-bezier(0.5, -0.25, 0.75, 1.25)"
        , test "Nothing falls back to \"ease\"" <|
            \_ ->
                Easing.toCSS Nothing |> Expect.equal "ease"
        ]



-- ============================================================
-- ENDPOINT BEHAVIOUR
-- ============================================================
--
-- Every easing function in the library must pass through (0,0) and
-- (1,1). A regression that broke this would silently desync the start
-- or end of every Sub-engine animation by a fraction.


endpointTests : Test
endpointTests =
    describe "toFunction satisfies f(0)≈0 and f(1)≈1 for every easing"
        (List.concatMap endpointCases allEasings)


endpointCases : Easing -> List Test
endpointCases easing =
    let
        f =
            Easing.toFunction easing

        label =
            easingLabel easing
    in
    [ test (label ++ " at t=0 returns 0") <|
        \_ ->
            f 0 |> Expect.within (Expect.Absolute 1.0e-6) 0
    , test (label ++ " at t=1 returns 1") <|
        \_ ->
            f 1 |> Expect.within (Expect.Absolute 1.0e-6) 1
    ]



-- ============================================================
-- MONOTONICITY (smoke)
-- ============================================================
--
-- Most easings (excluding Back, Elastic, and Bounce) are monotonic on
-- [0, 1]: f(0.5) sits strictly between f(0) and f(1).
-- Back/Elastic intentionally overshoot, and Bounce is non-monotonic;
-- they are exempted.


monotonicityTests : Test
monotonicityTests =
    describe "midpoint values for monotonic easings lie in (0, 1)"
        (List.map midpointCase monotonicEasings)


midpointCase : Easing -> Test
midpointCase easing =
    test (easingLabel easing ++ " at t=0.5 is in (0, 1)") <|
        \_ ->
            let
                mid =
                    Easing.toFunction easing 0.5
            in
            Expect.all
                [ \v -> v |> Expect.greaterThan 0
                , \v -> v |> Expect.lessThan 1
                ]
                mid


monotonicEasings : List Easing
monotonicEasings =
    [ Linear
    , Ease
    , EaseIn
    , EaseOut
    , EaseInOut
    , SineIn
    , SineOut
    , SineInOut
    , QuadIn
    , QuadOut
    , QuadInOut
    , CubicIn
    , CubicOut
    , CubicInOut
    , QuartIn
    , QuartOut
    , QuartInOut
    , QuintIn
    , QuintOut
    , QuintInOut
    , ExpoIn
    , ExpoOut
    , ExpoInOut
    , CircIn
    , CircOut
    , CircInOut
    ]



-- ============================================================
-- HELPERS
-- ============================================================


allEasings : List Easing
allEasings =
    monotonicEasings
        ++ [ BackIn
           , BackOut
           , BackInOut
           , BackInCustom 1.7
           , BackOutCustom 1.7
           , BackInOutCustom ( 1.7, 1.7 )
           , ElasticIn
           , ElasticOut
           , ElasticInOut
           , BounceIn
           , BounceOut
           , BounceInOut
           , CubicBezier 0.25 0.1 0.25 1.0
           ]


easingLabel : Easing -> String
easingLabel easing =
    case easing of
        Linear ->
            "Linear"

        Ease ->
            "Ease"

        EaseIn ->
            "EaseIn"

        EaseOut ->
            "EaseOut"

        EaseInOut ->
            "EaseInOut"

        SineIn ->
            "SineIn"

        SineOut ->
            "SineOut"

        SineInOut ->
            "SineInOut"

        QuadIn ->
            "QuadIn"

        QuadOut ->
            "QuadOut"

        QuadInOut ->
            "QuadInOut"

        CubicIn ->
            "CubicIn"

        CubicOut ->
            "CubicOut"

        CubicInOut ->
            "CubicInOut"

        QuartIn ->
            "QuartIn"

        QuartOut ->
            "QuartOut"

        QuartInOut ->
            "QuartInOut"

        QuintIn ->
            "QuintIn"

        QuintOut ->
            "QuintOut"

        QuintInOut ->
            "QuintInOut"

        ExpoIn ->
            "ExpoIn"

        ExpoOut ->
            "ExpoOut"

        ExpoInOut ->
            "ExpoInOut"

        CircIn ->
            "CircIn"

        CircOut ->
            "CircOut"

        CircInOut ->
            "CircInOut"

        BackIn ->
            "BackIn"

        BackOut ->
            "BackOut"

        BackInOut ->
            "BackInOut"

        BackInCustom _ ->
            "BackInCustom"

        BackOutCustom _ ->
            "BackOutCustom"

        BackInOutCustom _ ->
            "BackInOutCustom"

        ElasticIn ->
            "ElasticIn"

        ElasticOut ->
            "ElasticOut"

        ElasticInOut ->
            "ElasticInOut"

        BounceIn ->
            "BounceIn"

        BounceOut ->
            "BounceOut"

        BounceInOut ->
            "BounceInOut"

        CubicBezier _ _ _ _ ->
            "CubicBezier"
