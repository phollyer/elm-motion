module Motion.Easing exposing
    ( Easing(..)
    , toString
    )

{-| Easing functions for animations and scrolls.

Use them to create smooth and natural movement.

If you don't set an easing function, the defaults are:

  - Animations: `EaseInOut`, which is a good general-purpose easing.
  - Scrolls: `QuintOut`, which gives a nice smooth scroll effect, with a natural "settling into place" feel.

📖 See [Easing Documentation](https://phollyer.github.io/elm-motion/animation/concepts/easing/) for details.


# Easing Type

@docs Easing


# Utility

@docs toString

-}

-- ============================================================
-- TYPES
-- ============================================================


{-| -}
type Easing
    = BackIn
    | BackOut
    | BackInOut
    | BounceIn
    | BounceOut
    | BounceInOut
    | CircIn
    | CircOut
    | CircInOut
    | CubicBezier Float Float Float Float
    | CubicIn
    | CubicOut
    | CubicInOut
    | Ease
    | EaseIn
    | EaseOut
    | EaseInOut
    | ElasticIn
    | ElasticOut
    | ElasticInOut
    | ExpoIn
    | ExpoOut
    | ExpoInOut
    | Linear
    | QuadIn
    | QuadOut
    | QuadInOut
    | QuartIn
    | QuartOut
    | QuartInOut
    | QuintIn
    | QuintOut
    | QuintInOut
    | SineIn
    | SineOut
    | SineInOut



-- ============================================================
-- UTILITY
-- ============================================================


{-| Convert an easing function to a string representation.

This is useful for debugging and logging purposes.

-}
toString : Easing -> String
toString easing =
    case easing of
        BackIn ->
            "BackIn"

        BackOut ->
            "BackOut"

        BackInOut ->
            "BackInOut"

        BounceIn ->
            "BounceIn"

        BounceOut ->
            "BounceOut"

        BounceInOut ->
            "BounceInOut"

        CircIn ->
            "CircIn"

        CircOut ->
            "CircOut"

        CircInOut ->
            "CircInOut"

        CubicBezier x1 y1 x2 y2 ->
            "CubicBezier("
                ++ String.fromFloat x1
                ++ ", "
                ++ String.fromFloat y1
                ++ ", "
                ++ String.fromFloat x2
                ++ ", "
                ++ String.fromFloat y2
                ++ ")"

        CubicIn ->
            "CubicIn"

        CubicOut ->
            "CubicOut"

        CubicInOut ->
            "CubicInOut"

        Ease ->
            "Ease"

        EaseIn ->
            "EaseIn"

        EaseOut ->
            "EaseOut"

        EaseInOut ->
            "EaseInOut"

        ElasticIn ->
            "ElasticIn"

        ElasticOut ->
            "ElasticOut"

        ElasticInOut ->
            "ElasticInOut"

        ExpoIn ->
            "ExpoIn"

        ExpoOut ->
            "ExpoOut"

        ExpoInOut ->
            "ExpoInOut"

        Linear ->
            "Linear"

        QuadIn ->
            "QuadIn"

        QuadOut ->
            "QuadOut"

        QuadInOut ->
            "QuadInOut"

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

        SineIn ->
            "SineIn"

        SineOut ->
            "SineOut"

        SineInOut ->
            "SineInOut"
