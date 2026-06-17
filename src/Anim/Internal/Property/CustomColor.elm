module Anim.Internal.Property.CustomColor exposing
    ( Builder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , set
    , speed
    , spring
    , to
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Extra.Color as Color exposing (Color)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type Builder eng
    = Builder String (Builder.AnimationConfig Color) (AnimBuilder eng)



-- ============================================================
-- BUILD
-- ============================================================


defaultColor : Color
defaultColor =
    Color.fromRGBA { r = 255, g = 255, b = 255, a = 0 }


for : String -> String -> AnimBuilder eng -> Builder eng
for animGroupName cssPropertyName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.CustomColorPropertyConfig name cfg ->
                    if name == cssPropertyName then
                        Just cfg

                    else
                        Nothing

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName
                ("customColor:" ++ cssPropertyName)
                (PropertyBaselines.getCustomColorProperty cssPropertyName)
                extractExisting
                (PropertyBuilder.defaultConfig defaultColor)
                builder
    in
    Builder cssPropertyName config <|
        Builder.for animGroupName builder


build : Builder eng -> AnimBuilder eng
build (Builder cssName config builder) =
    PropertyBuilder.upsert (Builder.CustomColorPropertyConfig cssName config) builder



-- ============================================================
-- FROM
-- ============================================================


from : Color -> Builder eng -> Builder eng
from color (Builder cssName config builder) =
    let
        colorWithPreservedAlpha =
            case config.start of
                Nothing ->
                    color

                Just _ ->
                    case ( Color.hasExplicitAlpha color, Color.hasExplicitAlpha config.end ) of
                        ( False, True ) ->
                            Color.applyAlphaFromStart color config.end

                        _ ->
                            color
    in
    Builder cssName { config | start = Just colorWithPreservedAlpha } builder



-- ============================================================
-- TO
-- ============================================================


to : Color -> Builder eng -> Builder eng
to color (Builder cssName config builder) =
    let
        startPos =
            case config.start of
                Just c ->
                    c

                Nothing ->
                    defaultColor

        colorWithPreservedAlpha =
            case config.start of
                Nothing ->
                    color

                Just _ ->
                    case ( Color.hasExplicitAlpha color, Color.hasExplicitAlpha startPos ) of
                        ( False, True ) ->
                            Color.applyAlphaFromStart color startPos

                        _ ->
                            color
    in
    Builder cssName
        { config
            | end = colorWithPreservedAlpha
            , distance = Color.distance startPos colorWithPreservedAlpha
            , start = Just startPos
        }
        builder



-- ============================================================
-- SET (snap)
-- ============================================================


snap : Builder eng -> Builder eng
snap (Builder cssName config builder) =
    Builder cssName { config | mode = Builder.Snap } builder


set : Color -> Builder eng -> Builder eng
set value =
    to value >> snap



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed spd (Builder cssName config builder) =
    let
        maxColorDistance =
            441.67

        rgbDistancePerSecond =
            spd * maxColorDistance
    in
    Builder cssName
        { config
            | timing =
                Just <|
                    Speed rgbDistancePerSecond
        }
        builder


duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration dur (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.duration dur config) builder


delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay dly (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.delay dly config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> Builder eng -> Builder eng
easing ease (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.easing ease config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring s (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.spring s config) builder
