module Anim.Internal.Builder.PerspectiveOrigin exposing
    ( PerspectiveOriginBuilder
    , applyInitCssUnit
    , build
    , clampX
    , clampY
    , cssUnit
    , cssUnitX
    , cssUnitY
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
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type PerspectiveOriginBuilder eng
    = PerspectiveOriginBuilder (Builder.AnimationConfig PerspectiveOrigin) (AnimBuilder eng)


type alias PerspectiveOriginConfig =
    Builder.AnimationConfig PerspectiveOrigin


default : Float
default =
    0.5


defaultConfig : PerspectiveOriginConfig
defaultConfig =
    PropertyBuilder.defaultConfig PerspectiveOrigin.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder eng -> PerspectiveOriginBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.PerspectiveOriginConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "perspectiveOrigin" PropertyBaselines.getPerspectiveOrigin extractExisting defaultConfig builder
    in
    PerspectiveOriginBuilder config <|
        Builder.for animGroupName builder


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
                            { x = clampAxis cx r.x
                            , y = clampAxis cy r.y
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


clampAxis : Maybe ( Float, Float ) -> Float -> Float
clampAxis range v =
    case range of
        Just ( lo, hi ) ->
            clamp lo hi v

        Nothing ->
            v



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
to perspectiveOrigin (PerspectiveOriginBuilder config builder) =
    let
        start =
            Maybe.withDefault PerspectiveOrigin.default config.start
    in
    PerspectiveOriginBuilder
        { config
            | start = Just start
            , end = perspectiveOrigin
            , distance = PerspectiveOrigin.distance start perspectiveOrigin
        }
        builder


toXY : Float -> Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
toXY x y (PerspectiveOriginBuilder config builder) =
    to (PerspectiveOrigin.fromRecord { x = x, y = y }) <|
        PerspectiveOriginBuilder config builder


toX : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
toX x (PerspectiveOriginBuilder config builder) =
    let
        y =
            PerspectiveOrigin.getY config.end
    in
    toXY x y (PerspectiveOriginBuilder config builder)


toY : Float -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
toY y (PerspectiveOriginBuilder config builder) =
    let
        x =
            PerspectiveOrigin.getX config.end
    in
    toXY x y (PerspectiveOriginBuilder config builder)



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
-- UNIT
-- ============================================================


cssUnit : Unit -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
cssUnit unit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.cssUnit unit config) builder


cssUnitX : Unit -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
cssUnitX unit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.cssUnitX unit config) builder


cssUnitY : Unit -> PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
cssUnitY unit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.cssUnitY unit config) builder


{-| Seed the per-property `cssUnit` axes on the config from the AnimBuilder's
stored init-time unit defaults. Called at the start of every public `init*`
helper so values supplied during initialization are rendered with whatever
`initUnit*` was active at that point in the pipeline.
-}
applyInitCssUnit : PerspectiveOriginBuilder eng -> PerspectiveOriginBuilder eng
applyInitCssUnit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder
        { config | cssUnit = Builder.getPerspectiveOriginInitCssUnit builder }
        builder



-- ============================================================
-- BOUNDS
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
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            PerspectiveOriginBuilder config (f animGroupName builder)

        Nothing ->
            PerspectiveOriginBuilder config builder
