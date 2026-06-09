module Anim.Internal.Builder.Scale exposing
    ( ScaleBuilder
    , bounds
    , build
    , byX
    , byXY
    , byXYZ
    , byXZ
    , byY
    , byYZ
    , byZ
    , clampX
    , clampY
    , clampZ
    , delay
    , duration
    , easing
    , for
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , set
    , setX
    , setXY
    , setXYZ
    , setXZ
    , setY
    , setYZ
    , setZ
    , snap
    , speed
    , spring
    , to
    , toX
    , toXY
    , toXYZ
    , toXZ
    , toY
    , toYZ
    , toZ
    , unclampX
    , unclampY
    , unclampZ
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type ScaleBuilder eng
    = ScaleBuilder (Builder.AnimationConfig Scale) (AnimBuilder eng)


type alias ScaleConfig =
    Builder.AnimationConfig Scale


default : Float
default =
    1.0


defaultConfig : ScaleConfig
defaultConfig =
    PropertyBuilder.defaultConfig Scale.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder eng -> ScaleBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.ScaleConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "scale" PropertyBaselines.getScale extractExisting defaultConfig builder
    in
    ScaleBuilder config <|
        Builder.for animGroupName builder


build : ScaleBuilder eng -> AnimBuilder eng
build (ScaleBuilder config builder) =
    let
        clampedConfig =
            applyClamps builder config
    in
    PropertyBuilder.upsert
        (Builder.ScaleConfig
            (PropertyBuilder.applyFrozenAxes "scale"
                Scale.toRecord
                Scale.fromRecord
                Scale.distance
                builder
                clampedConfig
            )
        )
        builder


applyClamps : AnimBuilder eng -> ScaleConfig -> ScaleConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "scale" "x" builder

                cy =
                    Builder.getClamp animGroupName "scale" "y" builder

                cz =
                    Builder.getClamp animGroupName "scale" "z" builder
            in
            if cx == Nothing && cy == Nothing && cz == Nothing then
                config

            else
                let
                    clampValue value =
                        Scale.fromTriple
                            ( PropertyBuilder.clampAxis cx (Scale.getX value)
                            , PropertyBuilder.clampAxis cy (Scale.getY value)
                            , PropertyBuilder.clampAxis cz (Scale.getZ value)
                            )

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Scale.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Scale.distance startForDistance clampedEnd
                }



-- ============================================================
-- FROM
-- ============================================================


from : Scale -> ScaleBuilder eng -> ScaleBuilder eng
from scale (ScaleBuilder config builder) =
    ScaleBuilder { config | start = Just scale } builder


fromXYZ : Float -> Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
fromXYZ x y z =
    from (Scale.fromTriple ( x, y, z ))


fromXY : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
fromXY x y (ScaleBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Scale.getZ default config.start
    in
    fromXYZ x y z <|
        ScaleBuilder config builder


fromXZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
fromXZ x z (ScaleBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Scale.getY default config.start
    in
    fromXYZ x y z <|
        ScaleBuilder config builder


fromX : Float -> ScaleBuilder eng -> ScaleBuilder eng
fromX scaleX (ScaleBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Scale.getY default config.start

        z =
            PropertyBuilder.getFloat Scale.getZ default config.start
    in
    fromXYZ scaleX y z <|
        ScaleBuilder config builder


fromYZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
fromYZ scaleY scaleZ (ScaleBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Scale.getX default config.start
    in
    fromXYZ x scaleY scaleZ <|
        ScaleBuilder config builder


fromY : Float -> ScaleBuilder eng -> ScaleBuilder eng
fromY scaleY (ScaleBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Scale.getX default config.start

        z =
            PropertyBuilder.getFloat Scale.getZ default config.start
    in
    fromXYZ x scaleY z <|
        ScaleBuilder config builder


fromZ : Float -> ScaleBuilder eng -> ScaleBuilder eng
fromZ scaleZ (ScaleBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Scale.getX default config.start

        y =
            PropertyBuilder.getFloat Scale.getY default config.start
    in
    fromXYZ x y scaleZ <|
        ScaleBuilder config builder


byXYZ : Float -> Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
byXYZ deltaX deltaY deltaZ (ScaleBuilder config builder) =
    let
        startX =
            PropertyBuilder.getFloat Scale.getX default config.start

        startY =
            PropertyBuilder.getFloat Scale.getY default config.start

        startZ =
            PropertyBuilder.getFloat Scale.getZ default config.start
    in
    ScaleBuilder config builder
        |> fromXYZ startX startY startZ
        |> toXYZ (startX + deltaX) (startY + deltaY) (startZ + deltaZ)


byXY : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
byXY deltaX deltaY =
    byXYZ deltaX deltaY 0


byXZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
byXZ deltaX deltaZ =
    byXYZ deltaX 0 deltaZ


byX : Float -> ScaleBuilder eng -> ScaleBuilder eng
byX deltaX =
    byXYZ deltaX 0 0


byYZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
byYZ deltaY deltaZ =
    byXYZ 0 deltaY deltaZ


byY : Float -> ScaleBuilder eng -> ScaleBuilder eng
byY deltaY =
    byXYZ 0 deltaY 0


byZ : Float -> ScaleBuilder eng -> ScaleBuilder eng
byZ deltaZ =
    byXYZ 0 0 deltaZ



-- ============================================================
-- TO
-- ============================================================


to : Scale -> ScaleBuilder eng -> ScaleBuilder eng
to value (ScaleBuilder config builder) =
    ScaleBuilder
        (setEnd value config)
        (markAxes [ "x", "y", "z" ] builder)


toXYZ : Float -> Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
toXYZ x y z =
    to (Scale.fromTriple ( x, y, z ))


toXY : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
toXY x y (ScaleBuilder config builder) =
    let
        z =
            Scale.getZ config.end

        newEnd =
            Scale.fromTriple ( x, y, z )
    in
    ScaleBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "y" ] builder)


toXZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
toXZ x z (ScaleBuilder config builder) =
    let
        y =
            Scale.getY config.end

        newEnd =
            Scale.fromTriple ( x, y, z )
    in
    ScaleBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "z" ] builder)


toX : Float -> ScaleBuilder eng -> ScaleBuilder eng
toX x (ScaleBuilder config builder) =
    let
        y =
            Scale.getY config.end

        z =
            Scale.getZ config.end

        newEnd =
            Scale.fromTriple ( x, y, z )
    in
    ScaleBuilder
        (setEnd newEnd config)
        (markAxes [ "x" ] builder)


toYZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
toYZ y z (ScaleBuilder config builder) =
    let
        x =
            Scale.getX config.end

        newEnd =
            Scale.fromTriple ( x, y, z )
    in
    ScaleBuilder
        (setEnd newEnd config)
        (markAxes [ "y", "z" ] builder)


toY : Float -> ScaleBuilder eng -> ScaleBuilder eng
toY y (ScaleBuilder config builder) =
    let
        x =
            Scale.getX config.end

        z =
            Scale.getZ config.end

        newEnd =
            Scale.fromTriple ( x, y, z )
    in
    ScaleBuilder
        (setEnd newEnd config)
        (markAxes [ "y" ] builder)


toZ : Float -> ScaleBuilder eng -> ScaleBuilder eng
toZ z (ScaleBuilder config builder) =
    let
        x =
            Scale.getX config.end

        y =
            Scale.getY config.end

        newEnd =
            Scale.fromTriple ( x, y, z )
    in
    ScaleBuilder
        (setEnd newEnd config)
        (markAxes [ "z" ] builder)



-- Private helpers shared by TO setters.


setEnd : Scale -> ScaleConfig -> ScaleConfig
setEnd newEnd config =
    PropertyBuilder.setEnd Scale.default Scale.distance newEnd config


markAxes : List String -> AnimBuilder eng -> AnimBuilder eng
markAxes axes builder =
    Builder.markAxes "scale" axes builder



-- ============================================================
-- SET (snap)
-- ============================================================


snap : ScaleBuilder eng -> ScaleBuilder eng
snap (ScaleBuilder config builder) =
    ScaleBuilder { config | mode = Builder.Snap } builder


set : Scale -> ScaleBuilder eng -> ScaleBuilder eng
set value =
    to value >> snap


setXYZ : Float -> Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
setXYZ x y z =
    toXYZ x y z >> snap


setXY : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
setXY x y =
    toXY x y >> snap


setXZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
setXZ x z =
    toXZ x z >> snap


setX : Float -> ScaleBuilder eng -> ScaleBuilder eng
setX x =
    toX x >> snap


setYZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
setYZ y z =
    toYZ y z >> snap


setY : Float -> ScaleBuilder eng -> ScaleBuilder eng
setY y =
    toY y >> snap


setZ : Float -> ScaleBuilder eng -> ScaleBuilder eng
setZ z =
    toZ z >> snap



-- ============================================================
-- BOUNDS (resize)
-- ============================================================


{-| Mark this scale config as a `RemapToBounds` resize directive for
the current animation group. See `Anim.Internal.Builder.Translate.bounds`
for the design.
-}
bounds : Builder.AxisBounds -> ScaleBuilder { eng | withBounds : () } -> ScaleBuilder { eng | withBounds : () }
bounds ranges (ScaleBuilder config builder) =
    ScaleBuilder { config | mode = Builder.RemapToBounds ranges } builder



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> ScaleBuilder { eng | withTiming : () } -> ScaleBuilder { eng | withTiming : () }
speed value (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.speed value config) builder


duration : Int -> ScaleBuilder { eng | withTiming : () } -> ScaleBuilder { eng | withTiming : () }
duration ms (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.duration ms config) builder


delay : Int -> ScaleBuilder { eng | withTiming : () } -> ScaleBuilder { eng | withTiming : () }
delay delay_ (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.delay delay_ config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> ScaleBuilder eng -> ScaleBuilder eng
easing easing_ (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> ScaleBuilder { eng | withSpring : () } -> ScaleBuilder { eng | withSpring : () }
spring s (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "scale" "x" lo hi)


clampY : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "scale" "y" lo hi)


clampZ : Float -> Float -> ScaleBuilder eng -> ScaleBuilder eng
clampZ lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "scale" "z" lo hi)


unclampX : ScaleBuilder eng -> ScaleBuilder eng
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "scale" "x")


unclampY : ScaleBuilder eng -> ScaleBuilder eng
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "scale" "y")


unclampZ : ScaleBuilder eng -> ScaleBuilder eng
unclampZ =
    updateBuilderClamp (\name -> Builder.clearClamp name "scale" "z")


updateBuilderClamp : (String -> AnimBuilder eng -> AnimBuilder eng) -> ScaleBuilder eng -> ScaleBuilder eng
updateBuilderClamp f (ScaleBuilder config builder) =
    ScaleBuilder config (Builder.withCurrentAnimGroup f builder)
