module Anim.Internal.Builder.Translate exposing
    ( TranslateBuilder
    , applyInitCssUnitX
    , applyInitCssUnitY
    , applyInitCssUnitZ
    , build
    , by
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
    , cssUnit
    , cssUnitX
    , cssUnitY
    , cssUnitZ
    , delay
    , duration
    , easing
    , for
    , forContinuing
    , from
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
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing(..))
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type TranslateBuilder eng
    = TranslateBuilder (Builder.AnimationConfig Translate) (AnimBuilder eng)


type alias TranslateConfig =
    Builder.AnimationConfig Translate


default : Float
default =
    0.0


defaultConfig : TranslateConfig
defaultConfig =
    PropertyBuilder.defaultConfig Translate.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder eng -> TranslateBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.TranslateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "translate" PropertyBaselines.getTranslate extractExisting defaultConfig builder
    in
    TranslateBuilder config <|
        Builder.for animGroupName builder


forContinuing : String -> AnimBuilder eng -> TranslateBuilder eng
forContinuing animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.TranslateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        extractProcessedTiming processed =
            case processed of
                Builder.ProcessedTranslateConfig p ->
                    Just
                        { timing = Just p.timing
                        , easing = Just p.easing
                        , spring = p.spring
                        , delay = Just p.delay
                        }

                _ ->
                    Nothing

        config =
            PropertyBuilder.forContinuing animGroupName "translate" PropertyBaselines.getTranslate extractExisting extractProcessedTiming defaultConfig builder
    in
    TranslateBuilder config <|
        Builder.for animGroupName builder


build : TranslateBuilder eng -> AnimBuilder eng
build (TranslateBuilder config builder) =
    let
        clampedConfig =
            applyClamps builder config
    in
    PropertyBuilder.upsert
        (Builder.TranslateConfig
            (PropertyBuilder.applyFrozenAxes "translate"
                Translate.toRecord
                Translate.fromRecord
                Translate.distance
                builder
                clampedConfig
            )
        )
        builder


applyClamps : AnimBuilder eng -> TranslateConfig -> TranslateConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "translate" "x" builder

                cy =
                    Builder.getClamp animGroupName "translate" "y" builder

                cz =
                    Builder.getClamp animGroupName "translate" "z" builder
            in
            if cx == Nothing && cy == Nothing && cz == Nothing then
                config

            else
                let
                    clampValue value =
                        Translate.fromTriple
                            ( clampAxis cx (Translate.getX value)
                            , clampAxis cy (Translate.getY value)
                            , clampAxis cz (Translate.getZ value)
                            )

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Translate.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Translate.distance startForDistance clampedEnd
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


from : Translate -> TranslateBuilder eng -> TranslateBuilder eng
from value (TranslateBuilder config builder) =
    TranslateBuilder { config | start = Just value } builder


fromXYZ : Float -> Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
fromXYZ x y z =
    from (Translate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
fromXY x y (TranslateBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromXZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
fromXZ x z (TranslateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Translate.getY default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromX : Float -> TranslateBuilder eng -> TranslateBuilder eng
fromX x (TranslateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Translate.getY default config.start

        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromYZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
fromYZ y z (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromY : Float -> TranslateBuilder eng -> TranslateBuilder eng
fromY y (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start

        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromZ : Float -> TranslateBuilder eng -> TranslateBuilder eng
fromZ z (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start

        y =
            PropertyBuilder.getFloat Translate.getY default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Translate -> TranslateBuilder eng -> TranslateBuilder eng
to value (TranslateBuilder config builder) =
    TranslateBuilder
        (setEnd value config)
        (markAxes [ "x", "y", "z" ] builder)


toXYZ : Float -> Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
toXYZ x y z =
    to (Translate.fromTriple ( x, y, z ))


toXY : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
toXY x y (TranslateBuilder config builder) =
    let
        z =
            Translate.getZ config.end

        newEnd =
            Translate.fromTriple ( x, y, z )
    in
    TranslateBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "y" ] builder)


toXZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
toXZ x z (TranslateBuilder config builder) =
    let
        y =
            Translate.getY config.end

        newEnd =
            Translate.fromTriple ( x, y, z )
    in
    TranslateBuilder
        (setEnd newEnd config)
        (markAxes [ "x", "z" ] builder)


toX : Float -> TranslateBuilder eng -> TranslateBuilder eng
toX x (TranslateBuilder config builder) =
    let
        y =
            Translate.getY config.end

        z =
            Translate.getZ config.end

        newEnd =
            Translate.fromTriple ( x, y, z )
    in
    TranslateBuilder
        (setEnd newEnd config)
        (markAxes [ "x" ] builder)


toYZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
toYZ y z (TranslateBuilder config builder) =
    let
        x =
            Translate.getX config.end

        newEnd =
            Translate.fromTriple ( x, y, z )
    in
    TranslateBuilder
        (setEnd newEnd config)
        (markAxes [ "y", "z" ] builder)


toY : Float -> TranslateBuilder eng -> TranslateBuilder eng
toY y (TranslateBuilder config builder) =
    let
        x =
            Translate.getX config.end

        z =
            Translate.getZ config.end

        newEnd =
            Translate.fromTriple ( x, y, z )
    in
    TranslateBuilder
        (setEnd newEnd config)
        (markAxes [ "y" ] builder)


toZ : Float -> TranslateBuilder eng -> TranslateBuilder eng
toZ z (TranslateBuilder config builder) =
    let
        x =
            Translate.getX config.end

        y =
            Translate.getY config.end

        newEnd =
            Translate.fromTriple ( x, y, z )
    in
    TranslateBuilder
        (setEnd newEnd config)
        (markAxes [ "z" ] builder)



-- ============================================================
-- BY
-- ============================================================


by : Translate -> TranslateBuilder eng -> TranslateBuilder eng
by delta (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal + Translate.getX delta
                , Translate.getY startVal + Translate.getY delta
                , Translate.getZ startVal + Translate.getZ delta
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "x", "y", "z" ] builder)


byXYZ : Float -> Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
byXYZ dx dy dz =
    by (Translate.fromTriple ( dx, dy, dz ))


byXY : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
byXY dx dy (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal + dx
                , Translate.getY startVal + dy
                , Translate.getZ startVal
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "x", "y" ] builder)


byXZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
byXZ dx dz (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal + dx
                , Translate.getY startVal
                , Translate.getZ startVal + dz
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "x", "z" ] builder)


byX : Float -> TranslateBuilder eng -> TranslateBuilder eng
byX dx (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal + dx
                , Translate.getY startVal
                , Translate.getZ startVal
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "x" ] builder)


byYZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
byYZ dy dz (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal
                , Translate.getY startVal + dy
                , Translate.getZ startVal + dz
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "y", "z" ] builder)


byY : Float -> TranslateBuilder eng -> TranslateBuilder eng
byY dy (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal
                , Translate.getY startVal + dy
                , Translate.getZ startVal
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "y" ] builder)


byZ : Float -> TranslateBuilder eng -> TranslateBuilder eng
byZ dz (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal
                , Translate.getY startVal
                , Translate.getZ startVal + dz
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        (markAxes [ "z" ] builder)



-- Private helpers shared by TO setters.


setEnd : Translate -> TranslateConfig -> TranslateConfig
setEnd newEnd config =
    let
        startVal =
            Maybe.withDefault Translate.default config.start
    in
    { config
        | start = Just startVal
        , end = newEnd
        , distance = Translate.distance startVal newEnd
    }


markAxes : List String -> AnimBuilder eng -> AnimBuilder eng
markAxes axes builder =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            Builder.markTouchedAxes animGroupName "translate" axes builder

        Nothing ->
            builder



-- ============================================================
-- SET (snap)
-- ============================================================


snap : TranslateBuilder eng -> TranslateBuilder eng
snap (TranslateBuilder config builder) =
    TranslateBuilder { config | mode = Builder.Snap } builder


set : Translate -> TranslateBuilder eng -> TranslateBuilder eng
set value =
    to value >> snap


setXYZ : Float -> Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
setXYZ x y z =
    toXYZ x y z >> snap


setXY : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
setXY x y =
    toXY x y >> snap


setXZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
setXZ x z =
    toXZ x z >> snap


setX : Float -> TranslateBuilder eng -> TranslateBuilder eng
setX x =
    toX x >> snap


setYZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
setYZ y z =
    toYZ y z >> snap


setY : Float -> TranslateBuilder eng -> TranslateBuilder eng
setY y =
    toY y >> snap


setZ : Float -> TranslateBuilder eng -> TranslateBuilder eng
setZ z =
    toZ z >> snap



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> TranslateBuilder { eng | withTiming : () } -> TranslateBuilder { eng | withTiming : () }
delay delay_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> TranslateBuilder { eng | withTiming : () } -> TranslateBuilder { eng | withTiming : () }
duration ms (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> TranslateBuilder { eng | withTiming : () } -> TranslateBuilder { eng | withTiming : () }
speed value (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> TranslateBuilder eng -> TranslateBuilder eng
easing easing_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> TranslateBuilder { eng | withSpring : () } -> TranslateBuilder { eng | withSpring : () }
spring s (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.spring s config) builder


cssUnit : Unit -> TranslateBuilder eng -> TranslateBuilder eng
cssUnit unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnit unit config) builder


cssUnitX : Unit -> TranslateBuilder eng -> TranslateBuilder eng
cssUnitX unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnitX unit config) builder


cssUnitY : Unit -> TranslateBuilder eng -> TranslateBuilder eng
cssUnitY unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnitY unit config) builder


cssUnitZ : Unit -> TranslateBuilder eng -> TranslateBuilder eng
cssUnitZ unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnitZ unit config) builder


{-| Seed the per-property `cssUnit` axes on the config from the AnimBuilder's
stored init-time unit defaults. Called at the start of every public `init*`
helper so values supplied during initialization are rendered with whatever
`initUnit*` was active at that point in the pipeline.
-}
applyInitCssUnitX : TranslateBuilder eng -> TranslateBuilder eng
applyInitCssUnitX (TranslateBuilder config builder) =
    let
        initUnits =
            Builder.getTranslateInitCssUnit builder

        cssUnit_ =
            config.cssUnit
    in
    TranslateBuilder
        { config | cssUnit = { cssUnit_ | x = initUnits.x } }
        builder


applyInitCssUnitY : TranslateBuilder eng -> TranslateBuilder eng
applyInitCssUnitY (TranslateBuilder config builder) =
    let
        initUnits =
            Builder.getTranslateInitCssUnit builder

        cssUnit_ =
            config.cssUnit
    in
    TranslateBuilder
        { config | cssUnit = { cssUnit_ | y = initUnits.y } }
        builder


applyInitCssUnitZ : TranslateBuilder eng -> TranslateBuilder eng
applyInitCssUnitZ (TranslateBuilder config builder) =
    let
        initUnits =
            Builder.getTranslateInitCssUnit builder

        cssUnit_ =
            config.cssUnit
    in
    TranslateBuilder
        { config | cssUnit = { cssUnit_ | z = initUnits.z } }
        builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "translate" "x" lo hi)


clampY : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "translate" "y" lo hi)


clampZ : Float -> Float -> TranslateBuilder eng -> TranslateBuilder eng
clampZ lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "translate" "z" lo hi)


unclampX : TranslateBuilder eng -> TranslateBuilder eng
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "translate" "x")


unclampY : TranslateBuilder eng -> TranslateBuilder eng
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "translate" "y")


unclampZ : TranslateBuilder eng -> TranslateBuilder eng
unclampZ =
    updateBuilderClamp (\name -> Builder.clearClamp name "translate" "z")


updateBuilderClamp : (String -> AnimBuilder eng -> AnimBuilder eng) -> TranslateBuilder eng -> TranslateBuilder eng
updateBuilderClamp f (TranslateBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            TranslateBuilder config (f animGroupName builder)

        Nothing ->
            TranslateBuilder config builder
