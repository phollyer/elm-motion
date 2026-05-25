module Anim.Property.Custom exposing
    ( Builder, AnimGroupName, Property(..)
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    , spring
    , clamp, unclamp
    )

{-| Animate any numeric CSS property not covered by the first-class
property modules (Translate, Rotate, Scale etc.).

    import Anim.Property.Custom as Property
    import Anim.Unit exposing (Unit(..))
    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Property.for "box" (BorderRadius Px)
            >> Property.to 16
            >> Property.duration 300
            >> Property.easing EaseInOut
            >> Property.build

Length-typed constructors (`BorderRadius`, `Padding`, `Margin*`, `FontSize`,
`Top`/`Left`/`Right`/`Bottom`, etc.) take a typed [`Unit`](Anim.Unit#Unit), so
they share the same CSS-unit vocabulary as the first-class transform
properties (including the container-query and dynamic-viewport units).

The escape hatch [`Custom`](#Property) and the awkward `LineHeight` /
`TabSize` constructors keep a free-form `String` unit, since they target
properties that may be unitless or use units outside the [`Unit`](Anim.Unit#Unit)
vocabulary (`ch`, `ex`, `lh`, `deg`, `s`, `fr`, ...). Use
[`Anim.Unit.toCssSuffix`](Anim.Unit#toCssSuffix) when you want to feed a
typed `Unit` into one of those.


# Types

@docs Builder, AnimGroupName, Property


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs from


## End Value

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring


## Bounds

Keep this property's value within a range you choose. Each custom property keeps its own range,
even on the same animation group.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

@docs clamp, unclamp

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Property.Custom as Internal
import Anim.Unit as Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Builder type for custom property animations.
-}
type alias Builder mode =
    Internal.Builder mode


{-| A typed set of common numeric CSS properties with a custom escape hatch.

Length-typed constructors take a [`Unit`](Anim.Unit#Unit). The escape hatch
`Custom`, plus `LineHeight` and `TabSize`, take a free-form `String` unit
(use `""` for unitless values, or [`Anim.Unit.toCssSuffix`](Anim.Unit#toCssSuffix)
to bridge a typed `Unit`).

    import Anim.Property.Custom as Property
    import Anim.Unit exposing (Unit(..))

    Property.for "box" (Property.Custom "property-name" "unit")
        >> Property.to 32
        >> Property.build

    Property.for "label" (Property.LineHeight "") --- unitless
        >> Property.to 1.4
        >> Property.build

-}
type Property
    = -- Standard CSS
      BorderBottomLeftRadius Unit
    | BorderBottomRightRadius Unit
    | BorderBottomWidth Unit
    | BorderLeftWidth Unit
    | BorderRadius Unit
    | BorderRightWidth Unit
    | BorderTopLeftRadius Unit
    | BorderTopRightRadius Unit
    | BorderTopWidth Unit
    | BorderWidth Unit
    | Bottom Unit
    | ColumnGap Unit
    | ColumnWidth Unit
    | FontSize Unit
    | Gap Unit
    | Inset Unit
    | Left Unit
    | LetterSpacing Unit
    | LineHeight String
    | Margin Unit
    | MarginBottom Unit
    | MarginLeft Unit
    | MarginRight Unit
    | MarginTop Unit
    | MaxHeight Unit
    | MaxWidth Unit
    | MinHeight Unit
    | MinWidth Unit
    | OutlineOffset Unit
    | OutlineWidth Unit
    | Padding Unit
    | PaddingBottom Unit
    | PaddingLeft Unit
    | PaddingRight Unit
    | PaddingTop Unit
    | Perspective Unit
    | Right Unit
    | RowGap Unit
    | TabSize String
    | TextIndent Unit
    | Top Unit
    | WordSpacing Unit
      -- Flex
    | FlexBasis Unit
    | FlexGrow
    | FlexShrink
      -- SVG
    | Cx
    | Cy
    | R
    | Rx
    | Ry
    | StrokeDashOffset
    | StrokeWidth
      -- Escape hatch
    | Custom String String


toCssArgs : Property -> ( String, String )
toCssArgs cssProperty =
    case cssProperty of
        -- Standard CSS
        BorderBottomLeftRadius unit ->
            ( "border-bottom-left-radius", Unit.toCssSuffix unit )

        BorderBottomRightRadius unit ->
            ( "border-bottom-right-radius", Unit.toCssSuffix unit )

        BorderBottomWidth unit ->
            ( "border-bottom-width", Unit.toCssSuffix unit )

        BorderLeftWidth unit ->
            ( "border-left-width", Unit.toCssSuffix unit )

        BorderRadius unit ->
            ( "border-radius", Unit.toCssSuffix unit )

        BorderRightWidth unit ->
            ( "border-right-width", Unit.toCssSuffix unit )

        BorderTopLeftRadius unit ->
            ( "border-top-left-radius", Unit.toCssSuffix unit )

        BorderTopRightRadius unit ->
            ( "border-top-right-radius", Unit.toCssSuffix unit )

        BorderTopWidth unit ->
            ( "border-top-width", Unit.toCssSuffix unit )

        BorderWidth unit ->
            ( "border-width", Unit.toCssSuffix unit )

        Bottom unit ->
            ( "bottom", Unit.toCssSuffix unit )

        ColumnGap unit ->
            ( "column-gap", Unit.toCssSuffix unit )

        ColumnWidth unit ->
            ( "column-width", Unit.toCssSuffix unit )

        FontSize unit ->
            ( "font-size", Unit.toCssSuffix unit )

        Gap unit ->
            ( "gap", Unit.toCssSuffix unit )

        Inset unit ->
            ( "inset", Unit.toCssSuffix unit )

        Left unit ->
            ( "left", Unit.toCssSuffix unit )

        LetterSpacing unit ->
            ( "letter-spacing", Unit.toCssSuffix unit )

        LineHeight unit ->
            ( "line-height", unit )

        Margin unit ->
            ( "margin", Unit.toCssSuffix unit )

        MarginBottom unit ->
            ( "margin-bottom", Unit.toCssSuffix unit )

        MarginLeft unit ->
            ( "margin-left", Unit.toCssSuffix unit )

        MarginRight unit ->
            ( "margin-right", Unit.toCssSuffix unit )

        MarginTop unit ->
            ( "margin-top", Unit.toCssSuffix unit )

        MaxHeight unit ->
            ( "max-height", Unit.toCssSuffix unit )

        MaxWidth unit ->
            ( "max-width", Unit.toCssSuffix unit )

        MinHeight unit ->
            ( "min-height", Unit.toCssSuffix unit )

        MinWidth unit ->
            ( "min-width", Unit.toCssSuffix unit )

        OutlineOffset unit ->
            ( "outline-offset", Unit.toCssSuffix unit )

        OutlineWidth unit ->
            ( "outline-width", Unit.toCssSuffix unit )

        Padding unit ->
            ( "padding", Unit.toCssSuffix unit )

        PaddingBottom unit ->
            ( "padding-bottom", Unit.toCssSuffix unit )

        PaddingLeft unit ->
            ( "padding-left", Unit.toCssSuffix unit )

        PaddingRight unit ->
            ( "padding-right", Unit.toCssSuffix unit )

        PaddingTop unit ->
            ( "padding-top", Unit.toCssSuffix unit )

        Perspective unit ->
            ( "perspective", Unit.toCssSuffix unit )

        Right unit ->
            ( "right", Unit.toCssSuffix unit )

        RowGap unit ->
            ( "row-gap", Unit.toCssSuffix unit )

        TabSize unit ->
            ( "tab-size", unit )

        TextIndent unit ->
            ( "text-indent", Unit.toCssSuffix unit )

        Top unit ->
            ( "top", Unit.toCssSuffix unit )

        WordSpacing unit ->
            ( "word-spacing", Unit.toCssSuffix unit )

        -- Flex
        FlexBasis unit ->
            ( "flex-basis", Unit.toCssSuffix unit )

        FlexGrow ->
            ( "flex-grow", "" )

        FlexShrink ->
            ( "flex-shrink", "" )

        -- SVG
        Cx ->
            ( "cx", "" )

        Cy ->
            ( "cy", "" )

        R ->
            ( "r", "" )

        Rx ->
            ( "rx", "" )

        Ry ->
            ( "ry", "" )

        StrokeDashOffset ->
            ( "stroke-dashoffset", "" )

        StrokeWidth ->
            ( "stroke-width", "" )

        -- Escape hatch
        Custom name unit ->
            ( name, unit )



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial value for a custom CSS property.

Use this to initialize the property in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Custom as Property
    import Anim.Unit exposing (Unit(..))

    init : ( Model, Cmd Msg )
    init =
        ( { animState =
                Engine.init
                    [ Property.init "box" (BorderRadius Px) 0 ]
          }
        , Cmd.none
        )

-}
init : AnimGroupName -> Property -> Float -> AnimBuilder mode -> AnimBuilder mode
init animGroupName cssProperty value animBuilder =
    let
        ( name, unit ) =
            toCssArgs cssProperty
    in
    animBuilder
        |> Internal.for animGroupName name unit
        |> Internal.from value
        |> Internal.to value
        |> Internal.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom property animation `Builder`.

The first argument is the animation group name, the second is the CSS property.

    import Anim.Unit exposing (Unit(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Property.for "box" (BorderRadius Px)
            >> Property.to 16
            >> Property.build

-}
for : AnimGroupName -> Property -> AnimBuilder mode -> Builder mode
for animGroupName cssProperty =
    let
        ( name, unit ) =
            toCssArgs cssProperty
    in
    Internal.for animGroupName name unit


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder mode -> AnimBuilder mode
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting value.
-}
from : Float -> Builder mode -> Builder mode
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target value.
-}
to : Float -> Builder mode -> Builder mode
to =
    Internal.to



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the animation speed (units per second).
-}
speed : Float -> Builder mode -> Builder mode
speed =
    Internal.speed


{-| Set the animation duration (milliseconds).
-}
duration : Int -> Builder mode -> Builder mode
duration =
    Internal.duration


{-| Set the delay (milliseconds) before the animation starts.
-}
delay : Int -> Builder mode -> Builder mode
delay =
    Internal.delay



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> Builder mode -> Builder mode
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

    import Anim.Property.Custom as Property
    import Anim.Unit exposing (Unit(..))
    import Motion.Spring as Spring

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Property.for "box" (BorderRadius Px)
            >> Property.to 16
            >> Property.spring Spring.wobbly

-}
spring : Spring -> Builder mode -> Builder mode
spring =
    Internal.spring



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Keep this CSS property's value within `[min, max]` for this animation group.

Each custom property keeps its own range, so different properties on the same
animation group are independent. The range stays in effect for future
`animate` / `retarget` calls until you call [unclamp](#unclamp).
If `min > max`, the values are swapped.

📖 See [Responsive Animations](https://phollyer.github.io/elm-motion/animation/concepts/responsive-animations/)
for patterns and examples.

-}
clamp : Float -> Float -> Builder mode -> Builder mode
clamp =
    Internal.clamp


{-| Remove the range for this CSS property on this animation group. Does nothing if no range is set.
-}
unclamp : Builder mode -> Builder mode
unclamp =
    Internal.unclamp
