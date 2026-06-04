module Anim.Internal.Builder.Rotate exposing
    ( RotateBuilder
    , build
    , clampX
    , clampY
    , clampZ
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , byXYZ
    , byXY
    , byXZ
    , byX
    , byYZ
    , byY
    , byZ
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
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type RotateBuilder eng
    = RotateBuilder (Builder.AnimationConfig Rotate) (AnimBuilder eng)


type alias RotateConfig =
    Builder.AnimationConfig Rotate


default : Float
default =
    0.0


defaultConfig : RotateConfig
defaultConfig =
    PropertyBuilder.defaultConfig Rotate.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder eng -> RotateBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.RotateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "rotate" PropertyBaselines.getRotate extractExisting defaultConfig builder
    in
    RotateBuilder config <|
        Builder.for animGroupName builder


build : RotateBuilder eng -> AnimBuilder eng
build (RotateBuilder config builder) =
    let
        clampedConfig =
            applyClamps builder config
    in
    PropertyBuilder.upsert
        (Builder.RotateConfig
            (PropertyBuilder.applyFrozenAxes "rotate"
                Rotate.toRecord
                Rotate.fromRecord
                Rotate.distance
                builder
                clampedConfig
            )
        )
        builder


applyClamps : AnimBuilder eng -> RotateConfig -> RotateConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "rotate" "x" builder

                cy =
                    Builder.getClamp animGroupName "rotate" "y" builder

                cz =
                    Builder.getClamp animGroupName "rotate" "z" builder
            in
            if cx == Nothing && cy == Nothing && cz == Nothing then
                config

            else
                let
                    clampValue value =
                        Rotate.fromTriple
                            ( PropertyBuilder.clampAxis cx (Rotate.getX value)
                            , PropertyBuilder.clampAxis cy (Rotate.getY value)
                            , PropertyBuilder.clampAxis cz (Rotate.getZ value)
                            )

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Rotate.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Rotate.distance startForDistance clampedEnd
                }



-- ============================================================
-- FROM
-- ============================================================


from : Rotate -> RotateBuilder eng -> RotateBuilder eng
from rotate (RotateBuilder config builder) =
    RotateBuilder { config | start = Just rotate } builder


fromXYZ : Float -> Float -> Float -> RotateBuilder eng -> RotateBuilder eng
fromXYZ x y z =
    from (Rotate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
fromXY x y (RotateBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromXZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
fromXZ x z (RotateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Rotate.getY default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromX : Float -> RotateBuilder eng -> RotateBuilder eng
fromX x (RotateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Rotate.getY default config.start

        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromYZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
fromYZ y z (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromY : Float -> RotateBuilder eng -> RotateBuilder eng
fromY y (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start

        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromZ : Float -> RotateBuilder eng -> RotateBuilder eng
fromZ z (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start

        y =
            PropertyBuilder.getFloat Rotate.getY default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


byXYZ : Float -> Float -> Float -> RotateBuilder eng -> RotateBuilder eng
byXYZ deltaX deltaY deltaZ (RotateBuilder config builder) =
    let
        startX =
            PropertyBuilder.getFloat Rotate.getX default config.start

        startY =
            PropertyBuilder.getFloat Rotate.getY default config.start

        startZ =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    RotateBuilder config builder
        |> fromXYZ startX startY startZ
        |> toXYZ (startX + deltaX) (startY + deltaY) (startZ + deltaZ)


byXY : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
byXY deltaX deltaY =
    byXYZ deltaX deltaY 0


byXZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
byXZ deltaX deltaZ =
    byXYZ deltaX 0 deltaZ


byX : Float -> RotateBuilder eng -> RotateBuilder eng
byX deltaX =
    byXYZ deltaX 0 0


byYZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
byYZ deltaY deltaZ =
    byXYZ 0 deltaY deltaZ


byY : Float -> RotateBuilder eng -> RotateBuilder eng
byY deltaY =
    byXYZ 0 deltaY 0


byZ : Float -> RotateBuilder eng -> RotateBuilder eng
byZ deltaZ =
    byXYZ 0 0 deltaZ



-- ============================================================
-- TO
-- ============================================================


to : Rotate -> RotateBuilder eng -> RotateBuilder eng
to value (RotateBuilder config builder) =
    RotateBuilder
        (setEnd value config)
        (markAxes [ "x", "y", "z" ] builder)


toXYZ : Float -> Float -> Float -> RotateBuilder eng -> RotateBuilder eng
toXYZ x y z =
    to (Rotate.fromTriple ( x, y, z ))


toXY : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
toXY x y (RotateBuilder config builder) =
    let
        z =
            Rotate.getZ config.end

        newEnd =
            Rotate.fromTriple ( x, y, z )
    in
    RotateBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "y" ] builder)


toXZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
toXZ x z (RotateBuilder config builder) =
    let
        y =
            Rotate.getY config.end

        newEnd =
            Rotate.fromTriple ( x, y, z )
    in
    RotateBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "z" ] builder)


toX : Float -> RotateBuilder eng -> RotateBuilder eng
toX x (RotateBuilder config builder) =
    let
        y =
            Rotate.getY config.end

        z =
            Rotate.getZ config.end

        newEnd =
            Rotate.fromTriple ( x, y, z )
    in
    RotateBuilder
        (setEnd newEnd config)
        (markAxes [ "x" ] builder)


toYZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
toYZ y z (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end

        newEnd =
            Rotate.fromTriple ( x, y, z )
    in
    RotateBuilder
        (setEnd newEnd config)
        (markAxes [ "y", "z" ] builder)


toY : Float -> RotateBuilder eng -> RotateBuilder eng
toY y (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end

        z =
            Rotate.getZ config.end

        newEnd =
            Rotate.fromTriple ( x, y, z )
    in
    RotateBuilder
        (setEnd newEnd config)
        (markAxes [ "y" ] builder)


toZ : Float -> RotateBuilder eng -> RotateBuilder eng
toZ z (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end

        y =
            Rotate.getY config.end

        newEnd =
            Rotate.fromTriple ( x, y, z )
    in
    RotateBuilder
        (setEnd newEnd config)
        (markAxes [ "z" ] builder)



-- Private helpers shared by TO setters.


setEnd : Rotate -> RotateConfig -> RotateConfig
setEnd newEnd config =
    PropertyBuilder.setEnd Rotate.default Rotate.distance newEnd config


markAxes : List String -> AnimBuilder eng -> AnimBuilder eng
markAxes axes builder =
    Builder.markAxes "rotate" axes builder



-- ============================================================
-- SET (snap)
-- ============================================================


snap : RotateBuilder eng -> RotateBuilder eng
snap (RotateBuilder config builder) =
    RotateBuilder { config | mode = Builder.Snap } builder


set : Rotate -> RotateBuilder eng -> RotateBuilder eng
set value =
    to value >> snap


setXYZ : Float -> Float -> Float -> RotateBuilder eng -> RotateBuilder eng
setXYZ x y z =
    toXYZ x y z >> snap


setXY : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
setXY x y =
    toXY x y >> snap


setXZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
setXZ x z =
    toXZ x z >> snap


setX : Float -> RotateBuilder eng -> RotateBuilder eng
setX x =
    toX x >> snap


setYZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
setYZ y z =
    toYZ y z >> snap


setY : Float -> RotateBuilder eng -> RotateBuilder eng
setY y =
    toY y >> snap


setZ : Float -> RotateBuilder eng -> RotateBuilder eng
setZ z =
    toZ z >> snap



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> RotateBuilder { eng | withTiming : () } -> RotateBuilder { eng | withTiming : () }
delay ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.delay ms config) builder


duration : Int -> RotateBuilder { eng | withTiming : () } -> RotateBuilder { eng | withTiming : () }
duration ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> RotateBuilder { eng | withTiming : () } -> RotateBuilder { eng | withTiming : () }
speed value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> RotateBuilder eng -> RotateBuilder eng
easing easing_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> RotateBuilder { eng | withSpring : () } -> RotateBuilder { eng | withSpring : () }
spring s (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "rotate" "x" lo hi)


clampY : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "rotate" "y" lo hi)


clampZ : Float -> Float -> RotateBuilder eng -> RotateBuilder eng
clampZ lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "rotate" "z" lo hi)


unclampX : RotateBuilder eng -> RotateBuilder eng
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "rotate" "x")


unclampY : RotateBuilder eng -> RotateBuilder eng
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "rotate" "y")


unclampZ : RotateBuilder eng -> RotateBuilder eng
unclampZ =
    updateBuilderClamp (\name -> Builder.clearClamp name "rotate" "z")


updateBuilderClamp : (String -> AnimBuilder eng -> AnimBuilder eng) -> RotateBuilder eng -> RotateBuilder eng
updateBuilderClamp f (RotateBuilder config builder) =
    RotateBuilder config (Builder.withCurrentAnimGroup f builder)
