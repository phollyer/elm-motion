module Anim.Resize exposing
    ( AxisBounds, Bounds
    )

{-| Types used when responding to a viewport or container resize.

The `bounds` setter on each property module (Translate, Scale,
PerspectiveOrigin) takes a [`Bounds`](#Bounds) value. Compose those
setters inside an engine's `onResize` callback - the engine applies the
new bounds on the next animation frame.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for per-engine details and patterns.

Before reaching for these, consider whether a relative
[`Anim.Unit`](Anim-Unit) (`Percent`, `Vw`, `Vh`, `Rem`, `Em`, `Cqw`,
`Cqh`...) on the animated property would let the browser handle the
resize for you - no `onResize` plumbing required.


# Bounds

@docs AxisBounds, Bounds

-}


{-| Inclusive numeric range for one axis.
-}
type alias AxisBounds =
    { min : Float, max : Float }


{-| Per-axis resize bounds. Leave an axis as `Nothing` to ignore it.

    { x = Just { min = 0, max = newWidth - boxSize }
    , y = Nothing
    , z = Nothing
    }

-}
type alias Bounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    , z : Maybe AxisBounds
    }
