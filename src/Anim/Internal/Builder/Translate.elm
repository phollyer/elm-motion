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


type TranslateBuilder mode
    = TranslateBuilder (Builder.AnimationConfig Translate) (AnimBuilder mode)


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


for : String -> AnimBuilder mode -> TranslateBuilder mode
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


forContinuing : String -> AnimBuilder mode -> TranslateBuilder mode
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


build : TranslateBuilder mode -> AnimBuilder mode
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


applyClamps : AnimBuilder mode -> TranslateConfig -> TranslateConfig
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


from : Translate -> TranslateBuilder mode -> TranslateBuilder mode
from value (TranslateBuilder config builder) =
    TranslateBuilder { config | start = Just value } builder


fromXYZ : Float -> Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromXYZ x y z =
    from (Translate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromXY x y (TranslateBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromXZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromXZ x z (TranslateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Translate.getY default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromX : Float -> TranslateBuilder mode -> TranslateBuilder mode
fromX x (TranslateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Translate.getY default config.start

        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromYZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromYZ y z (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromY : Float -> TranslateBuilder mode -> TranslateBuilder mode
fromY y (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start

        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromZ : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


to : Translate -> TranslateBuilder mode -> TranslateBuilder mode
to value (TranslateBuilder config builder) =
    TranslateBuilder
        (setEnd value config)
        (markAxes [ "x", "y", "z" ] builder)


toXYZ : Float -> Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
toXYZ x y z =
    to (Translate.fromTriple ( x, y, z ))


toXY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
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


toXZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
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


toX : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


toYZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
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


toY : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


toZ : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


by : Translate -> TranslateBuilder mode -> TranslateBuilder mode
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


byXYZ : Float -> Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
byXYZ dx dy dz =
    by (Translate.fromTriple ( dx, dy, dz ))


byXY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
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


byXZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
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


byX : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


byYZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
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


byY : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


byZ : Float -> TranslateBuilder mode -> TranslateBuilder mode
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


markAxes : List String -> AnimBuilder mode -> AnimBuilder mode
markAxes axes builder =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            Builder.markTouchedAxes animGroupName "translate" axes builder

        Nothing ->
            builder



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> TranslateBuilder { m | supportsTime : () } -> TranslateBuilder { m | supportsTime : () }
delay delay_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> TranslateBuilder { m | supportsTime : () } -> TranslateBuilder { m | supportsTime : () }
duration ms (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> TranslateBuilder { m | supportsTime : () } -> TranslateBuilder { m | supportsTime : () }
speed value (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> TranslateBuilder mode -> TranslateBuilder mode
easing easing_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> TranslateBuilder { m | supportsSpring : () } -> TranslateBuilder { m | supportsSpring : () }
spring s (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.spring s config) builder


cssUnit : Unit -> TranslateBuilder mode -> TranslateBuilder mode
cssUnit unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnit unit config) builder


cssUnitX : Unit -> TranslateBuilder mode -> TranslateBuilder mode
cssUnitX unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnitX unit config) builder


cssUnitY : Unit -> TranslateBuilder mode -> TranslateBuilder mode
cssUnitY unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnitY unit config) builder


cssUnitZ : Unit -> TranslateBuilder mode -> TranslateBuilder mode
cssUnitZ unit (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.cssUnitZ unit config) builder


{-| Seed the per-property `cssUnit` axes on the config from the AnimBuilder's
stored init-time unit defaults. Called at the start of every public `init*`
helper so values supplied during initialization are rendered with whatever
`initUnit*` was active at that point in the pipeline.
-}
applyInitCssUnitX : TranslateBuilder mode -> TranslateBuilder mode
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


applyInitCssUnitY : TranslateBuilder mode -> TranslateBuilder mode
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


applyInitCssUnitZ : TranslateBuilder mode -> TranslateBuilder mode
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


clampX : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "translate" "x" lo hi)


clampY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "translate" "y" lo hi)


clampZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
clampZ lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "translate" "z" lo hi)


unclampX : TranslateBuilder mode -> TranslateBuilder mode
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "translate" "x")


unclampY : TranslateBuilder mode -> TranslateBuilder mode
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "translate" "y")


unclampZ : TranslateBuilder mode -> TranslateBuilder mode
unclampZ =
    updateBuilderClamp (\name -> Builder.clearClamp name "translate" "z")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> TranslateBuilder mode -> TranslateBuilder mode
updateBuilderClamp f (TranslateBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            TranslateBuilder config (f animGroupName builder)

        Nothing ->
            TranslateBuilder config builder
