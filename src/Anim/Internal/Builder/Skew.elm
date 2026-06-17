module Anim.Internal.Builder.Skew exposing
    ( SkewBuilder
    , build
    , byX
    , byXY
    , byY
    , clampX
    , clampY
    , delay
    , duration
    , easing
    , for
    , fromX
    , fromXY
    , fromY
    , setX
    , setXY
    , setY
    , snap
    , speed
    , spring
    , toX
    , toXY
    , toY
    , unclampX
    , unclampY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type SkewBuilder eng
    = SkewBuilder (Builder.AnimationConfig Skew) (AnimBuilder eng)


type alias SkewConfig =
    Builder.AnimationConfig Skew



-- ============================================================
-- BUILD
-- ============================================================


default : Float
default =
    0.0


defaultConfig : SkewConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Skew.fromTuple ( default, default )


for : String -> AnimBuilder eng -> SkewBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.SkewConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "skew" PropertyBaselines.getSkew extractExisting defaultConfig builder
    in
    SkewBuilder config <|
        Builder.for animGroupName builder


build : SkewBuilder eng -> AnimBuilder eng
build (SkewBuilder config builder) =
    PropertyBuilder.upsert (Builder.SkewConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder eng -> SkewConfig -> SkewConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "skew" "x" builder

                cy =
                    Builder.getClamp animGroupName "skew" "y" builder
            in
            if cx == Nothing && cy == Nothing then
                config

            else
                let
                    clampValue value =
                        Skew.fromTuple
                            ( PropertyBuilder.clampAxis cx (Skew.getX value)
                            , PropertyBuilder.clampAxis cy (Skew.getY value)
                            )

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Skew.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Skew.distance startForDistance clampedEnd
                }



-- ============================================================
-- FROM
-- ============================================================


fromXY : Float -> Float -> SkewBuilder eng -> SkewBuilder eng
fromXY x y (SkewBuilder config builder) =
    SkewBuilder
        { config
            | start =
                Just <|
                    Skew.fromTuple ( x, y )
        }
        builder


fromX : Float -> SkewBuilder eng -> SkewBuilder eng
fromX x (SkewBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Skew.getY default config.start
    in
    fromXY x y <|
        SkewBuilder config builder


fromY : Float -> SkewBuilder eng -> SkewBuilder eng
fromY y (SkewBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Skew.getX default config.start
    in
    fromXY x y <|
        SkewBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Skew -> SkewBuilder eng -> SkewBuilder eng
to value (SkewBuilder config builder) =
    SkewBuilder
        (setEnd value config)
        (markAxes [ "x", "y" ] builder)


toXY : Float -> Float -> SkewBuilder eng -> SkewBuilder eng
toXY x y =
    to (Skew.fromTuple ( x, y ))


toX : Float -> SkewBuilder eng -> SkewBuilder eng
toX x (SkewBuilder config builder) =
    let
        y =
            Skew.getY config.end

        newEnd =
            Skew.fromTuple ( x, y )
    in
    SkewBuilder
        (setEnd newEnd config)
        (markAxes [ "x" ] builder)


toY : Float -> SkewBuilder eng -> SkewBuilder eng
toY y (SkewBuilder config builder) =
    let
        x =
            Skew.getX config.end

        newEnd =
            Skew.fromTuple ( x, y )
    in
    SkewBuilder
        (setEnd newEnd config)
        (markAxes [ "y" ] builder)


setEnd : Skew -> SkewConfig -> SkewConfig
setEnd newEnd config =
    PropertyBuilder.setEnd Skew.default Skew.distance newEnd config


markAxes : List String -> AnimBuilder eng -> AnimBuilder eng
markAxes axes builder =
    Builder.markAxes "skew" axes builder



-- ============================================================
-- BY
-- ============================================================


byXY : Float -> Float -> SkewBuilder eng -> SkewBuilder eng
byXY deltaX deltaY (SkewBuilder config builder) =
    let
        startX =
            PropertyBuilder.getFloat Skew.getX default config.start

        startY =
            PropertyBuilder.getFloat Skew.getY default config.start
    in
    SkewBuilder config builder
        |> fromXY startX startY
        |> toXY (startX + deltaX) (startY + deltaY)


byX : Float -> SkewBuilder eng -> SkewBuilder eng
byX deltaX =
    byXY deltaX 0


byY : Float -> SkewBuilder eng -> SkewBuilder eng
byY deltaY =
    byXY 0 deltaY



-- ============================================================
-- SET (snap)
-- ============================================================


snap : SkewBuilder eng -> SkewBuilder eng
snap (SkewBuilder config builder) =
    SkewBuilder { config | mode = Builder.Snap } builder


setXY : Float -> Float -> SkewBuilder eng -> SkewBuilder eng
setXY x y =
    toXY x y >> snap


setX : Float -> SkewBuilder eng -> SkewBuilder eng
setX x =
    toX x >> snap


setY : Float -> SkewBuilder eng -> SkewBuilder eng
setY y =
    toY y >> snap



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> SkewBuilder { eng | withTiming : () } -> SkewBuilder { eng | withTiming : () }
delay delay_ (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> SkewBuilder { eng | withTiming : () } -> SkewBuilder { eng | withTiming : () }
duration ms (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> SkewBuilder { eng | withTiming : () } -> SkewBuilder { eng | withTiming : () }
speed value (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> SkewBuilder eng -> SkewBuilder eng
easing easing_ (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> SkewBuilder { eng | withSpring : () } -> SkewBuilder { eng | withSpring : () }
spring s (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- CLAMPS
-- ============================================================


clampX : Float -> Float -> SkewBuilder eng -> SkewBuilder eng
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "skew" "x" lo hi)


clampY : Float -> Float -> SkewBuilder eng -> SkewBuilder eng
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "skew" "y" lo hi)


unclampX : SkewBuilder eng -> SkewBuilder eng
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "skew" "x")


unclampY : SkewBuilder eng -> SkewBuilder eng
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "skew" "y")


updateBuilderClamp : (String -> AnimBuilder eng -> AnimBuilder eng) -> SkewBuilder eng -> SkewBuilder eng
updateBuilderClamp f (SkewBuilder config builder) =
    SkewBuilder config (Builder.withCurrentAnimGroup f builder)
