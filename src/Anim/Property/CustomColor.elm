module Anim.Property.CustomColor exposing
    ( Builder, AnimGroupName, ColorProperty(..)
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    , spring
    , set
    )

{-| Animate any CSS color property not covered by the first-class
property modules.

**Default**: transparent

When no start value is configured, the default will be used.


# Types

@docs Builder, AnimGroupName, ColorProperty


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#start-values)
for details.

@docs from


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/#end-values)
for details.

@docs to


## Timing

📖 See [Animation Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/)
for details.

@docs delay, duration, speed


## Easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/)
for details.

@docs easing


## Spring

📖 See [Spring](https://phollyer.github.io/elm-motion/animation/concepts/spring/)
for details.

@docs spring


## Snap

Snap to a specific color, cancelling any in-flight animation on this property.

@docs set

-}

import Anim.Extra.Color exposing (Color)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Property.CustomColor as Internal
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for custom color animations.
-}
type alias Builder eng =
    Internal.Builder eng


{-| A typed set of common color properties with a custom escape hatch.

Use the escape hatch `Custom` to animate any CSS color property not currently supported out of the box.

    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as CustomColor

    CustomColor.for "box" (Custom "outline-color")
        >> CustomColor.to (Color.rgb 255 0 0)
        >> CustomColor.build

-}
type ColorProperty
    = AccentColor
    | BackgroundColor
    | BorderColor
    | BorderTopColor
    | BorderRightColor
    | BorderBottomColor
    | BorderLeftColor
    | BorderBlockColor
    | BorderBlockStartColor
    | BorderBlockEndColor
    | BorderInlineColor
    | BorderInlineStartColor
    | BorderInlineEndColor
    | CaretColor
    | ColumnRuleColor
    | OutlineColor
    | TextColor
    | TextDecorationColor
    | TextEmphasisColor
    | Fill
    | Stroke
    | StopColor
    | FloodColor
    | LightingColor
    | Custom String



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial color value.

Use this to initialize the property in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as CustomColor

    init : ( Model, Cmd Msg )
    init =
        ( { animState =
                Engine.init
                    [ CustomColor.init "box" BorderColor <|
                        Color.rgb 99 102 241
                    ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> ColorProperty -> Color -> AnimBuilder eng -> AnimBuilder eng
init animGroupName cssProperty value animBuilder =
    animBuilder
        |> Internal.for animGroupName (toCssPropertyName cssProperty)
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom color property animation `Builder`.

The first argument is the animation group name, the second is the CSS property.

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        CustomColor.for "box" TextColor
            >> CustomColor.to (Color.rgb 255 0 0)
            >> CustomColor.build

-}
for : AnimGroupName -> ColorProperty -> AnimBuilder eng -> Builder eng
for animGroupName cssProperty =
    Internal.for animGroupName (toCssPropertyName cssProperty)


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder eng -> AnimBuilder eng
build =
    Internal.build


toCssPropertyName : ColorProperty -> String
toCssPropertyName cssProperty =
    case cssProperty of
        BackgroundColor ->
            "background-color"

        AccentColor ->
            "accent-color"

        TextColor ->
            "color"

        BorderColor ->
            "border-color"

        BorderTopColor ->
            "border-top-color"

        BorderRightColor ->
            "border-right-color"

        BorderBottomColor ->
            "border-bottom-color"

        BorderLeftColor ->
            "border-left-color"

        BorderBlockColor ->
            "border-block-color"

        BorderBlockStartColor ->
            "border-block-start-color"

        BorderBlockEndColor ->
            "border-block-end-color"

        BorderInlineColor ->
            "border-inline-color"

        BorderInlineStartColor ->
            "border-inline-start-color"

        BorderInlineEndColor ->
            "border-inline-end-color"

        OutlineColor ->
            "outline-color"

        TextDecorationColor ->
            "text-decoration-color"

        TextEmphasisColor ->
            "text-emphasis-color"

        CaretColor ->
            "caret-color"

        Fill ->
            "fill"

        Stroke ->
            "stroke"

        StopColor ->
            "stop-color"

        FloodColor ->
            "flood-color"

        LightingColor ->
            "lighting-color"

        ColumnRuleColor ->
            "column-rule-color"

        Custom cssName ->
            cssName



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting color value.
-}
from : Color -> Builder eng -> Builder eng
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target color value.
-}
to : Color -> Builder eng -> Builder eng
to =
    Internal.to



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap to a specific color, cancelling any in-flight animation on this property.
-}
set : Color -> Builder eng -> Builder eng
set =
    Internal.set



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    Internal.delay


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    Internal.duration


{-| Set the animation speed (units per second).
-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    Internal.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.

    import Easing exposing (Easing(..))

    CustomColor.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    Internal.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    CustomColor.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    Internal.spring
