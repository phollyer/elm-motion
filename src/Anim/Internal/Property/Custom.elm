module Anim.Internal.Property.Custom exposing
    ( Builder
    , build
    , by
    , clamp
    , delay
    , duration
    , easing
    , for
    , from
    , set
    , snap
    , speed
    , spring
    , to
    , unclamp
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type Builder eng
    = Builder String String (Builder.AnimationConfig Float) (AnimBuilder eng)



-- ============================================================
-- BUILD
-- ============================================================


for : String -> String -> String -> AnimBuilder eng -> Builder eng
for animGroupName cssPropertyName unit builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.CustomPropertyConfig name _ cfg ->
                    if name == cssPropertyName then
                        Just cfg

                    else
                        Nothing

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName
                ("custom:" ++ cssPropertyName)
                (PropertyBaselines.getCustomProperty cssPropertyName)
                extractExisting
                defaultConfig
                builder
    in
    Builder cssPropertyName unit config <|
        Builder.for animGroupName builder


build : Builder eng -> AnimBuilder eng
build (Builder cssName unit config builder) =
    let
        clampedConfig =
            applyClamps cssName builder config
    in
    PropertyBuilder.upsert (Builder.CustomPropertyConfig cssName unit clampedConfig) builder


applyClamps : String -> AnimBuilder eng -> Builder.AnimationConfig Float -> Builder.AnimationConfig Float
applyClamps cssName builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            case Builder.getClamp animGroupName ("custom:" ++ cssName) "value" builder of
                Nothing ->
                    config

                Just ( lo, hi ) ->
                    let
                        clampedStart =
                            Maybe.map (Basics.clamp lo hi) config.start

                        clampedEnd =
                            Basics.clamp lo hi config.end

                        startForDistance =
                            Maybe.withDefault 0 clampedStart
                    in
                    { config
                        | start = clampedStart
                        , end = clampedEnd
                        , distance = abs (clampedEnd - startForDistance)
                    }



-- ============================================================
-- FROM
-- ============================================================


defaultConfig : Builder.AnimationConfig Float
defaultConfig =
    PropertyBuilder.defaultConfig 0


from : Float -> Builder eng -> Builder eng
from value (Builder cssName unit config builder) =
    Builder cssName unit { config | start = Just value } builder



-- ============================================================
-- TO
-- ============================================================


to : Float -> Builder eng -> Builder eng
to endValue (Builder cssName unit config builder) =
    let
        startValue =
            case config.start of
                Just v ->
                    v

                Nothing ->
                    0
    in
    Builder cssName
        unit
        { config
            | end = endValue
            , distance = abs (endValue - startValue)
            , start = Just startValue
        }
        builder



-- ============================================================
-- BY
-- ============================================================


by : Float -> Builder eng -> Builder eng
by delta (Builder cssName unit config builder) =
    let
        startValue =
            Maybe.withDefault 0 config.start

        endValue =
            startValue + delta
    in
    Builder cssName
        unit
        { config
            | start = Just startValue
            , end = endValue
            , distance = abs (endValue - startValue)
        }
        builder



-- ============================================================
-- SET (snap)
-- ============================================================


snap : Builder eng -> Builder eng
snap (Builder cssName unit config builder) =
    Builder cssName unit { config | mode = Builder.Snap } builder


set : Float -> Builder eng -> Builder eng
set value =
    to value >> snap



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
speed spd (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.speed spd config) builder


duration : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
duration dur (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.duration dur config) builder


easing : Easing -> Builder eng -> Builder eng
easing ease (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.easing ease config) builder


spring : Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }
spring s (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clamp : Float -> Float -> Builder eng -> Builder eng
clamp lo hi (Builder cssName unit config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            Builder cssName unit config (Builder.setClamp animGroupName ("custom:" ++ cssName) "value" lo hi builder)

        Nothing ->
            Builder cssName unit config builder


unclamp : Builder eng -> Builder eng
unclamp (Builder cssName unit config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            Builder cssName unit config (Builder.clearClamp animGroupName ("custom:" ++ cssName) "value" builder)

        Nothing ->
            Builder cssName unit config builder


delay : Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }
delay dly (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.delay dly config) builder
