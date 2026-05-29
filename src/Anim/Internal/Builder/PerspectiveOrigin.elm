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


type PerspectiveOriginBuilder mode
    = PerspectiveOriginBuilder (Builder.AnimationConfig PerspectiveOrigin) (AnimBuilder mode)


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


for : String -> AnimBuilder mode -> PerspectiveOriginBuilder mode
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


build : PerspectiveOriginBuilder mode -> AnimBuilder mode
build (PerspectiveOriginBuilder config builder) =
    PropertyBuilder.upsert (Builder.PerspectiveOriginConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder mode -> PerspectiveOriginConfig -> PerspectiveOriginConfig
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


from : PerspectiveOrigin -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
from perspectiveOrigin (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder
        { config | start = Just perspectiveOrigin }
        builder


fromXY : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
fromXY x y (PerspectiveOriginBuilder config builder) =
    from (PerspectiveOrigin.fromRecord { x = x, y = y }) <|
        PerspectiveOriginBuilder config builder


fromX : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
fromX x (PerspectiveOriginBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat PerspectiveOrigin.getY default config.start
    in
    fromXY x y <|
        PerspectiveOriginBuilder config builder


fromY : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
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


to : PerspectiveOrigin -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
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


toXY : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
toXY x y (PerspectiveOriginBuilder config builder) =
    to (PerspectiveOrigin.fromRecord { x = x, y = y }) <|
        PerspectiveOriginBuilder config builder


toX : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
toX x (PerspectiveOriginBuilder config builder) =
    let
        y =
            PerspectiveOrigin.getY config.end
    in
    toXY x y (PerspectiveOriginBuilder config builder)


toY : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
toY y (PerspectiveOriginBuilder config builder) =
    let
        x =
            PerspectiveOrigin.getX config.end
    in
    toXY x y (PerspectiveOriginBuilder config builder)



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> PerspectiveOriginBuilder { m | supportsTime : () } -> PerspectiveOriginBuilder { m | supportsTime : () }
delay delay_ (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> PerspectiveOriginBuilder { m | supportsTime : () } -> PerspectiveOriginBuilder { m | supportsTime : () }
duration ms (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> PerspectiveOriginBuilder { m | supportsTime : () } -> PerspectiveOriginBuilder { m | supportsTime : () }
speed value (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
easing easing_ (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> PerspectiveOriginBuilder { m | supportsSpring : () } -> PerspectiveOriginBuilder { m | supportsSpring : () }
spring s (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- UNIT
-- ============================================================


cssUnit : Unit -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
cssUnit unit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.cssUnit unit config) builder


cssUnitX : Unit -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
cssUnitX unit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.cssUnitX unit config) builder


cssUnitY : Unit -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
cssUnitY unit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder (PropertyBuilder.cssUnitY unit config) builder


{-| Seed the per-property `cssUnit` axes on the config from the AnimBuilder's
stored init-time unit defaults. Called at the start of every public `init*`
helper so values supplied during initialization are rendered with whatever
`initUnit*` was active at that point in the pipeline.
-}
applyInitCssUnit : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
applyInitCssUnit (PerspectiveOriginBuilder config builder) =
    PerspectiveOriginBuilder
        { config | cssUnit = Builder.getPerspectiveOriginInitCssUnit builder }
        builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "perspectiveOrigin" "x" lo hi)


clampY : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "perspectiveOrigin" "y" lo hi)


unclampX : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "perspectiveOrigin" "x")


unclampY : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "perspectiveOrigin" "y")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
updateBuilderClamp f (PerspectiveOriginBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            PerspectiveOriginBuilder config (f animGroupName builder)

        Nothing ->
            PerspectiveOriginBuilder config builder
