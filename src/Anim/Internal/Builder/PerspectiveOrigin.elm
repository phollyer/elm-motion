module Anim.Internal.Builder.PerspectiveOrigin exposing
    ( PerspectiveOriginBuilder
    , bounds
    , build
    , by
    , byX
    , byXY
    , byY
    , clampX
    , clampY
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXY
    , fromY
    , set
    , setX
    , setXY
    , setY
    , snap
    , speed
    , spring
    , to
    , toX
    , toXY
    , toY
    , unclampX
    , unclampY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin)
import Anim.Internal.Unit as InternalUnit
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type PerspectiveOriginBuilder eng
    = PerspectiveOriginBuilder (Builder.AnimationConfig PerspectiveOrigin) (AnimBuilder eng)


type alias PerspectiveOriginConfig =
    Builder.AnimationConfig PerspectiveOrigin



-- ============================================================
-- BUILD
-- ============================================================


default : Float
default =
    0.5


defaultConfig : PerspectiveOriginConfig
defaultConfig =
    PropertyBuilder.defaultConfig PerspectiveOrigin.default


for : String -> AnimBuilder eng -> PerspectiveOriginBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.PerspectiveOriginConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        baselineUnits =
            Builder.getBaseline animGroupName builder
                |> Maybe.andThen PropertyBaselines.getPerspectiveOriginConfiguredUnits

        storeUnits =
            Builder.getPerspectiveOriginInitCssUnitAxes animGroupName builder

        scopedGlobalUnits =
            Builder.getPerspectiveOriginCssUnitAxes animGroupName builder

        baseConfig =
            PropertyBuilder.for animGroupName "perspectiveOrigin" PropertyBaselines.getPerspectiveOrigin extractExisting defaultConfig builder

        config =
            { baseConfig
                | cssUnit =
                    InternalUnit.mergeBaselineUnits (Just scopedGlobalUnits) baseConfig.cssUnit
                        |> InternalUnit.mergeBaselineUnits baselineUnits
                        |> InternalUnit.mergeBaselineUnits (Just storeUnits)
            }
    in
    PerspectiveOriginBuilder config <|
        (Builder.for animGroupName builder
            |> Builder.setPerspectiveOriginCurrentGroup animGroupName
        )


build : PerspectiveOriginBuilder eng -> AnimBuilder eng
build (PerspectiveOriginBuilder config builder) =
    PropertyBuilder.upsert (Builder.PerspectiveOriginConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder eng -> PerspectiveOriginConfig -> PerspectiveOriginConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "perspectiveOrigin" "x" builder

                cy =
                    Builder.getClamp animGroupName "perspectiveOrigin" "y" builder
            in
            if cx == Nothing && cy == Nothing then
                config

            else
                let
                    clampValue value =
                        let
                            r =
                                PerspectiveOrigin.toRecord value
                        in
                        PerspectiveOrigin.fromRecord
                            { x = PropertyBuilder.clampAxis cx r.x
                            , y = PropertyBuilder.clampAxis cy r.y
                            }

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault PerspectiveOrigin.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = PerspectiveOrigin.distance startForDistance clampedEnd
                }



-- ============================================================
-- FROM
-- ============================================================


from : PerspectiveOrigin -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
from perspectiveOrigin (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder
        { config | start = Just perspectiveOrigin }
        builder


fromXY : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
fromXY x y (PerspectiveOriginBuilder config builder) =
    from (PerspectiveOrigin.fromRecord { x = x, y = y }) <|
        PerspectiveOriginBuilder config builder


fromX : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
fromX x (PerspectiveOriginBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat PerspectiveOrigin.getY default config.start
    in
    fromXY x y <|
        PerspectiveOriginBuilder config builder


fromY : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
fromY y (PerspectiveOriginBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat PerspectiveOrigin.getX default config.start
    in
    fromXY x y <|
        PerspectiveOriginBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : PerspectiveOrigin -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
to value (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder
        (setEnd value config)
        (markAxes [ "x", "y" ] builder)


toXY : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
toXY x y (PerspectiveOriginBuilder config builder) =
    let
        newEnd =
            PerspectiveOrigin.fromRecord { x = x, y = y }
    in
    PerspectiveOriginBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "y" ] builder)


toX : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
toX x (PerspectiveOriginBuilder config builder) =
    let
        y =
            PerspectiveOrigin.getY config.end

        newEnd =
            PerspectiveOrigin.fromRecord { x = x, y = y }
    in
    PerspectiveOriginBuilder
        (setEnd newEnd config)
        (markAxes [ "x" ] builder)


toY : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
toY y (PerspectiveOriginBuilder config builder) =
    let
        x =
            PerspectiveOrigin.getX config.end

        newEnd =
            PerspectiveOrigin.fromRecord { x = x, y = y }
    in
    PerspectiveOriginBuilder
        (setEnd newEnd config)
        (markAxes [ "y" ] builder)


setEnd : PerspectiveOrigin -> PerspectiveOriginConfig -> PerspectiveOriginConfig
setEnd newEnd config =
    PropertyBuilder.setEnd PerspectiveOrigin.default PerspectiveOrigin.distance newEnd config


markAxes : List String -> AnimBuilder eng -> AnimBuilder eng
markAxes axes builder =
    Builder.markAxes "perspectiveOrigin" axes builder



-- ============================================================
-- BY
-- ============================================================


by : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
by delta =
    byXY delta delta


byXY : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
byXY deltaX deltaY (PerspectiveOriginBuilder config builder) =
    let
        startX =
            PropertyBuilder.getFloat PerspectiveOrigin.getX default config.start

        startY =
            PropertyBuilder.getFloat PerspectiveOrigin.getY default config.start
    in
    PerspectiveOriginBuilder config builder
        |> fromXY startX startY
        |> toXY (startX + deltaX) (startY + deltaY)


byX : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
byX deltaX =
    byXY deltaX 0


byY : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
byY deltaY =
    byXY 0 deltaY



-- ============================================================
-- SET (snap)
-- ============================================================


snap : PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
snap (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder { config | mode = Builder.Snap } builder


set : PerspectiveOrigin -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
set value =
    to value >> snap


setXY : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
setXY x y =
    toXY x y >> snap


setX : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
setX x =
    toX x >> snap


setY : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
setY y =
    toY y >> snap



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> PerspectiveOriginBuilder { eng | withTiming : () } -> PerspectiveOriginBuilder { eng | withTiming : () }
delay delay_ (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> PerspectiveOriginBuilder { eng | withTiming : () } -> PerspectiveOriginBuilder { eng | withTiming : () }
duration ms (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> PerspectiveOriginBuilder { eng | withTiming : () } -> PerspectiveOriginBuilder { eng | withTiming : () }
speed value (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
easing easing_ (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> PerspectiveOriginBuilder { eng | withSpring : () } -> PerspectiveOriginBuilder { eng | withSpring : () }
spring s (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


bounds : Builder.AxisBounds -> PerspectiveOriginBuilder { eng | withBounds : () } -> PerspectiveOriginBuilder { eng | withBounds : () }
bounds ranges (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder { config | mode = Builder.RemapToBounds ranges } builder



-- ============================================================
-- CLAMPS
-- ============================================================


clampX : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "perspectiveOrigin" "x" lo hi)


clampY : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "perspectiveOrigin" "y" lo hi)


unclampX : PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "perspectiveOrigin" "x")


unclampY : PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "perspectiveOrigin" "y")


updateBuilderClamp : (String -> AnimBuilder eng -> AnimBuilder eng) -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
updateBuilderClamp f (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder config (Builder.withCurrentAnimGroup f builder)
