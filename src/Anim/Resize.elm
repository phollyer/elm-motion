module Anim.Resize exposing
    ( Builder
    , AxisBounds, Bounds, bounds
    )

{-| Update animation bounds when the viewport or a container resizes.

Use [bounds](#bounds) together with an Engine's `onResize` function. The Engine applies the
new bounds on the next animation frame.


# When to use `Resize.bounds`

`Resize.bounds` is the escape hatch for animations whose endpoints are calculated in
pixels (for example `containerWidth - boxWidth`).

Before reaching for it, consider whether a relative [`Anim.Unit`](Anim-Unit)
(`Percent`, `Vw`, `Vh`, `Rem`, `Em`, `Cqw`, `Cqh`...) on the animated property
would let the browser handle the resize for you - no `onResize` plumbing required.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for per-engine details and patterns.

After a resize event, pass the new bounds to the engine:

    OnResize width height ->
        let
            newBounds =
                { x = Just { min = 0, max = toFloat width }
                , y = Just { min = 0, max = toFloat height }
                , z = Nothing
                }
        in
        ( { model
            | animState =
                Sub.onResize model.animState <|
                    Resize.bounds "box" newBounds
          }
        , Cmd.none
        )

The animation will respect the new bounds on the next animation frame.


# Builder

@docs Builder


# Bounds

@docs AxisBounds, Bounds, bounds

-}

import Anim.Internal.Resize.Builder as Internal



-- ============================================================
-- BUILDER
-- ============================================================


{-| Builder type passed to an Engine's `onResize` function.

Holds per-group resize bounds so the Engine can apply them on the next frame.

-}
type alias Builder =
    Internal.Builder



-- ============================================================
-- BOUNDS
-- ============================================================


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


{-| Set group-wide bounds for an animation group when a resize occurs.

    Sub.onResize model.animState <|
        Resize.bounds "box" <|
            { x = Just { min = 0, max = newWidth - boxWidth }
            , y = Nothing
            , z = Nothing
            }

    Sub.onResize model.animState <|
        Resize.bounds "box" newBoxBounds
            >> Resize.bounds "otherGroup" otherBounds

-}
bounds : Internal.AnimGroupName -> Bounds -> Builder -> Builder
bounds =
    Internal.bounds
