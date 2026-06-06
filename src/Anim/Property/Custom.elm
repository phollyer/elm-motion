module Anim.Property.Custom exposing
    ( Builder, AnimGroupName, Property(..)
    , init
    , for, build
    , from
    , to
    , by
    , delay, duration, speed
    , easing
    , spring
    , clamp
    , unclamp
    , set
    )

{-| Animate any numeric CSS property not covered by the first-class
property modules (Translate, Rotate, Scale etc.).


# Types

@docs Builder, AnimGroupName, Property


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


### Absolute

@docs to


### Relative

Move by a delta instead of to a fixed value. The end value is
`current + delta`, where `current` is the live animated value.

Only available on the Sub and WAAPI engines. Using these with
any other engine results in a type error.

@docs by


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


## Clamping

Keep property values within a range you choose.

Values outside the range are clamped to the nearest boundary.

The range stays in effect for future animations
until you [Unclamp](#unclamp) it:

    update msg model =
        case msg of
            FontSizeChanged size ->
                let
                    ( animState, cmd ) =
                        WAAPI.animate model.animState <|
                            Custom.for animGroupName (Custom.FontSize Px)
                                >> Custom.clamp 12 32
                                >> Custom.build
                in
                ( { model | animState = animState }
                , cmd
                )

Useful if `to` values are coming from external sources; user input, slider values, or external data
etc, and you need to keep them within a specific range.

Pairs well with [by](#by) for relative animations where the delta could push the value outside the desired range.


### Clamp

@docs clamp


### Unclamp

@docs unclamp


## Snap

@docs set

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Property.Custom as Internal
import Anim.Internal.Unit as InternalUnit
import Anim.Unit exposing (Unit)
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
type alias Builder eng =
    Internal.Builder eng


{-| A typed set of common numeric CSS properties with a custom escape hatch.

    import Anim.Property.Custom as Property
    import Anim.Unit exposing (Unit(..))


    Property.for "labelAnim" (Property.LineHeight Em)
        >> Property.to 1.4 -- Animate to "1.4em"
        >> Property.build

    Property.for "labelAnim" (Property.LineHeight Unitless)
        >> Property.to 1.4 -- Animate to "1.4" - 1.4x the element's font-size
        >> Property.build

    Property.for "boxAnim" (Property.Custom "property-name" "unit")
        >> Property.to 32 -- Animate to "32unit"
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
    | LineHeight Unit
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
    | TabSize Unit
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
init : AnimGroupName -> Property -> Float -> AnimBuilder eng -> AnimBuilder eng
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


toCssArgs : Property -> ( String, String )
toCssArgs cssProperty =
    case cssProperty of
        -- Standard CSS
        BorderBottomLeftRadius unit ->
            ( "border-bottom-left-radius", InternalUnit.toCssSuffix unit )

        BorderBottomRightRadius unit ->
            ( "border-bottom-right-radius", InternalUnit.toCssSuffix unit )

        BorderBottomWidth unit ->
            ( "border-bottom-width", InternalUnit.toCssSuffix unit )

        BorderLeftWidth unit ->
            ( "border-left-width", InternalUnit.toCssSuffix unit )

        BorderRadius unit ->
            ( "border-radius", InternalUnit.toCssSuffix unit )

        BorderRightWidth unit ->
            ( "border-right-width", InternalUnit.toCssSuffix unit )

        BorderTopLeftRadius unit ->
            ( "border-top-left-radius", InternalUnit.toCssSuffix unit )

        BorderTopRightRadius unit ->
            ( "border-top-right-radius", InternalUnit.toCssSuffix unit )

        BorderTopWidth unit ->
            ( "border-top-width", InternalUnit.toCssSuffix unit )

        BorderWidth unit ->
            ( "border-width", InternalUnit.toCssSuffix unit )

        Bottom unit ->
            ( "bottom", InternalUnit.toCssSuffix unit )

        ColumnGap unit ->
            ( "column-gap", InternalUnit.toCssSuffix unit )

        ColumnWidth unit ->
            ( "column-width", InternalUnit.toCssSuffix unit )

        FontSize unit ->
            ( "font-size", InternalUnit.toCssSuffix unit )

        Gap unit ->
            ( "gap", InternalUnit.toCssSuffix unit )

        Inset unit ->
            ( "inset", InternalUnit.toCssSuffix unit )

        Left unit ->
            ( "left", InternalUnit.toCssSuffix unit )

        LetterSpacing unit ->
            ( "letter-spacing", InternalUnit.toCssSuffix unit )

        LineHeight unit ->
            ( "line-height", InternalUnit.toCssSuffix unit )

        Margin unit ->
            ( "margin", InternalUnit.toCssSuffix unit )

        MarginBottom unit ->
            ( "margin-bottom", InternalUnit.toCssSuffix unit )

        MarginLeft unit ->
            ( "margin-left", InternalUnit.toCssSuffix unit )

        MarginRight unit ->
            ( "margin-right", InternalUnit.toCssSuffix unit )

        MarginTop unit ->
            ( "margin-top", InternalUnit.toCssSuffix unit )

        MaxHeight unit ->
            ( "max-height", InternalUnit.toCssSuffix unit )

        MaxWidth unit ->
            ( "max-width", InternalUnit.toCssSuffix unit )

        MinHeight unit ->
            ( "min-height", InternalUnit.toCssSuffix unit )

        MinWidth unit ->
            ( "min-width", InternalUnit.toCssSuffix unit )

        OutlineOffset unit ->
            ( "outline-offset", InternalUnit.toCssSuffix unit )

        OutlineWidth unit ->
            ( "outline-width", InternalUnit.toCssSuffix unit )

        Padding unit ->
            ( "padding", InternalUnit.toCssSuffix unit )

        PaddingBottom unit ->
            ( "padding-bottom", InternalUnit.toCssSuffix unit )

        PaddingLeft unit ->
            ( "padding-left", InternalUnit.toCssSuffix unit )

        PaddingRight unit ->
            ( "padding-right", InternalUnit.toCssSuffix unit )

        PaddingTop unit ->
            ( "padding-top", InternalUnit.toCssSuffix unit )

        Perspective unit ->
            ( "perspective", InternalUnit.toCssSuffix unit )

        Right unit ->
            ( "right", InternalUnit.toCssSuffix unit )

        RowGap unit ->
            ( "row-gap", InternalUnit.toCssSuffix unit )

        TabSize unit ->
            ( "tab-size", InternalUnit.toCssSuffix unit )

        TextIndent unit ->
            ( "text-indent", InternalUnit.toCssSuffix unit )

        Top unit ->
            ( "top", InternalUnit.toCssSuffix unit )

        WordSpacing unit ->
            ( "word-spacing", InternalUnit.toCssSuffix unit )

        -- Flex
        FlexBasis unit ->
            ( "flex-basis", InternalUnit.toCssSuffix unit )

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
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a custom property animation `Builder`.

The first argument is the animation group name, the second is the CSS property.

    import Anim.Unit exposing (Unit(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Property.for "box" (BorderRadius Px)
            >> Property.to 16
            >> Property.build

-}
for : AnimGroupName -> Property -> AnimBuilder eng -> Builder eng
for animGroupName cssProperty =
    let
        ( name, unit ) =
            toCssArgs cssProperty
    in
    Internal.for animGroupName name unit


{-| Complete the animation configuration and return an `AnimBuilder`.
-}
build : Builder eng -> AnimBuilder eng
build =
    Internal.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting value.
-}
from : Float -> Builder eng -> Builder eng
from =
    Internal.from



-- ============================================================
-- TO
-- ============================================================


{-| Set the target value.
-}
to : Float -> Builder eng -> Builder eng
to =
    Internal.to



-- ============================================================
-- BY
-- ============================================================


{-| Move by a delta instead of to a fixed value.

    import Anim.Property.Custom as Property
    import Anim.Unit exposing (Unit(..))

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Property.for "box" (Property.BorderRadius Px)
            >> Property.by 4
            >> Property.build

-}
by : Float -> Builder { eng | withLiveDelta : () } -> Builder { eng | withLiveDelta : () }
by =
    Internal.by



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

    Property.easing EaseInOut

-}
easing : Easing -> Builder eng -> Builder eng
easing =
    Internal.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring.

    import Motion.Spring as Spring

    Property.spring Spring.wobbly

-}
spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring =
    Internal.spring



-- ============================================================
-- CLAMPING
-- ============================================================


{-| Keep this CSS property's value within the min and max range.

If `min > max`, the values are swapped.

-}
clamp : Float -> Float -> Builder eng -> Builder eng
clamp =
    Internal.clamp


{-| Remove the range for this CSS property. Does nothing if no range is set.
-}
unclamp : Builder eng -> Builder eng
unclamp =
    Internal.unclamp



-- ============================================================
-- SNAP
-- ============================================================


{-| Snap the value silently, cancelling any in-flight animation
on this property.
-}
set : Float -> Builder eng -> Builder eng
set =
    Internal.set
