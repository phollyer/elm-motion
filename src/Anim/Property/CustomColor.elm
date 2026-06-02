module Anim.Property.CustomColor exposing
    ( Builder, AnimGroupName, ColorProperty(..)
    , init
    , for, build
    , from
    , to
    , set
    , delay, duration, speed
    , easing
    , spring
    )

{-| Animate any CSS color property.

    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as CustomColor
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        CustomColor.for "box" BackgroundColor
            >> CustomColor.to (Color.rgb 255 0 0)
            >> CustomColor.duration 300
            >> CustomColor.easing EaseInOut
            >> CustomColor.build


# Types

@docs Builder, AnimGroupName, ColorProperty


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#start-values)
for details.

@docs from


## End Value

📖 See [End Values](https://phollyer.github.io/elm-motion/animation/properties/overview/?h=start+values#end-values)
for details.

@docs to


## Snap

@docs set


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

    CustomColor.for "box" (Custom "property-name")
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


{-| Set the initial value for a custom color CSS property.

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


{-| Set the starting color.
-}
from : Color -> Builder eng -> Builder eng
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target color.
-}
to : Color -> Builder eng -> Builder eng
to =
    Internal.to



-- ============================================================
-- SET (snap)
-- ============================================================


{-| Snap the color silently, cancelling any in-flight animation
on this property.
-}
set : Color -> Builder eng -> Builder eng
set =
    Internal.set



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (0.0 to 1.0 range per second).
-}
speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed =
    Internal.speed


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration =
    Internal.duration


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay =
    Internal.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> Builder eng -> Builder eng
easing =
    Internal.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring instead of an easing curve.

Spring-driven motion has _emergent_ duration: the motion ends when
the value has settled at the target. Any `duration` or `speed` set on
this property is ignored when a spring is used. `delay` is honoured.

Setting `spring` clears any previously-set `easing` on this property,
and vice versa — they are mutually exclusive.

    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as CustomColor
    import Motion.Spring as Spring

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        CustomColor.for "box" BackgroundColor
            >> CustomColor.to (Color.rgb 255 0 0)
            >> CustomColor.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    Internal.spring
