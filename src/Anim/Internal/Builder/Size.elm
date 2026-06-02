module Anim.Internal.Builder.Size exposing
    ( SizeBuilder
    , applyInitCssUnit
    , bounds
    , build
    , clampHeight
    , clampWidth
    , cssUnit
    , cssUnitHeight
    , cssUnitWidth
    , delay
    , duration
    , easing
    , for
    , from
    , fromH
    , fromHW
    , fromW
    , set
    , setH
    , setHW
    , setW
    , snap
    , speed
    , spring
    , to
    , toH
    , toHW
    , toW
    , unclampHeight
    , unclampWidth
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Unit exposing (Unit)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type SizeBuilder eng
    = SizeBuilder (Builder.AnimationConfig Size) (AnimBuilder eng)


type alias SizeConfig =
    Builder.AnimationConfig Size


default : Float
default =
    0.0


defaultConfig : SizeConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Size.fromTuple ( default, default )



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder eng -> SizeBuilder eng
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.SizeConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "size" PropertyBaselines.getSize extractExisting defaultConfig builder
    in
    SizeBuilder config <|
        Builder.for animGroupName builder


build : SizeBuilder eng -> AnimBuilder eng
build (SizeBuilder config builder) =
    PropertyBuilder.upsert (Builder.SizeConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder eng -> SizeConfig -> SizeConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cw =
                    Builder.getClamp animGroupName "size" "width" builder

                ch =
                    Builder.getClamp animGroupName "size" "height" builder
            in
            if cw == Nothing && ch == Nothing then
                config

            else
                let
                    clampValue value =
                        let
                            r =
                                Size.toRecord value
                        in
                        Size.fromRecord
                            { width = clampAxis cw r.width
                            , height = clampAxis ch r.height
                            }

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Size.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Size.distance startForDistance clampedEnd
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


from : Size -> SizeBuilder eng -> SizeBuilder eng
from size (SizeBuilder config builder) =
    SizeBuilder
        { config | start = Just size }
        builder


fromHW : Float -> Float -> SizeBuilder eng -> SizeBuilder eng
fromHW height width (SizeBuilder config builder) =
    SizeBuilder
        { config
            | start =
                Just <|
                    Size.fromTuple ( width, height )
        }
        builder


fromH : Float -> SizeBuilder eng -> SizeBuilder eng
fromH h (SizeBuilder config builder) =
    let
        w =
            PropertyBuilder.getFloat Size.getW default config.start
    in
    fromHW h w (SizeBuilder config builder)


fromW : Float -> SizeBuilder eng -> SizeBuilder eng
fromW w (SizeBuilder config builder) =
    let
        h =
            PropertyBuilder.getFloat Size.getH default config.start
    in
    fromHW h w (SizeBuilder config builder)



-- ============================================================
-- TO
-- ============================================================


to : Size -> SizeBuilder eng -> SizeBuilder eng
to size (SizeBuilder config builder) =
    let
        start =
            Maybe.withDefault Size.default config.start
    in
    SizeBuilder
        { config
            | start = Just start
            , end = size
            , distance = Size.distance start size
        }
        builder


toHW : Float -> Float -> SizeBuilder eng -> SizeBuilder eng
toHW height width =
    to (Size.fromTuple ( width, height ))


toH : Float -> SizeBuilder eng -> SizeBuilder eng
toH h (SizeBuilder config builder) =
    let
        w =
            Size.getW config.end
    in
    toHW h w (SizeBuilder config builder)


toW : Float -> SizeBuilder eng -> SizeBuilder eng
toW w (SizeBuilder config builder) =
    let
        h =
            Size.getH config.end
    in
    toHW h w (SizeBuilder config builder)



-- ============================================================
-- SET (snap)
-- ============================================================


snap : SizeBuilder eng -> SizeBuilder eng
snap (SizeBuilder config builder) =
    SizeBuilder { config | mode = Builder.Snap } builder


set : Size -> SizeBuilder eng -> SizeBuilder eng
set value =
    to value >> snap


setHW : Float -> Float -> SizeBuilder eng -> SizeBuilder eng
setHW h w =
    toHW h w >> snap


setH : Float -> SizeBuilder eng -> SizeBuilder eng
setH h =
    toH h >> snap


setW : Float -> SizeBuilder eng -> SizeBuilder eng
setW w =
    toW w >> snap



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> SizeBuilder { eng | withTiming : () } -> SizeBuilder { eng | withTiming : () }
delay ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.delay ms config) builder


duration : Int -> SizeBuilder { eng | withTiming : () } -> SizeBuilder { eng | withTiming : () }
duration ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> SizeBuilder { eng | withTiming : () } -> SizeBuilder { eng | withTiming : () }
speed pixelsPerSecond (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.speed pixelsPerSecond config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> SizeBuilder eng -> SizeBuilder eng
easing easingFunction (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.easing easingFunction config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> SizeBuilder { eng | withSpring : () } -> SizeBuilder { eng | withSpring : () }
spring s (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.spring s config) builder


cssUnit : Unit -> SizeBuilder eng -> SizeBuilder eng
cssUnit unit (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.cssUnit unit config) builder


cssUnitWidth : Unit -> SizeBuilder eng -> SizeBuilder eng
cssUnitWidth unit (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.cssUnitX unit config) builder


cssUnitHeight : Unit -> SizeBuilder eng -> SizeBuilder eng
cssUnitHeight unit (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.cssUnitY unit config) builder


{-| Seed the per-property `cssUnit` axes on the config from the AnimBuilder's
stored init-time unit defaults. Called at the start of every public `init*`
helper so values supplied during initialization are rendered with whatever
`initUnit*` was active at that point in the pipeline.
-}
applyInitCssUnit : SizeBuilder eng -> SizeBuilder eng
applyInitCssUnit (SizeBuilder config builder) =
    SizeBuilder
        { config | cssUnit = Builder.getSizeInitCssUnit builder }
        builder



-- ============================================================
-- BOUNDS (resize)
-- ============================================================


{-| Mark this size config as a `RemapToBounds` resize directive for
the current animation group. See `Anim.Internal.Builder.Translate.bounds`
for the design.
-}
bounds : Builder.AxisBounds -> SizeBuilder { eng | withBounds : () } -> SizeBuilder { eng | withBounds : () }
bounds ranges (SizeBuilder config builder) =
    SizeBuilder { config | mode = Builder.RemapToBounds ranges } builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampWidth : Float -> Float -> SizeBuilder eng -> SizeBuilder eng
clampWidth lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "size" "width" lo hi)


clampHeight : Float -> Float -> SizeBuilder eng -> SizeBuilder eng
clampHeight lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "size" "height" lo hi)


unclampWidth : SizeBuilder eng -> SizeBuilder eng
unclampWidth =
    updateBuilderClamp (\name -> Builder.clearClamp name "size" "width")


unclampHeight : SizeBuilder eng -> SizeBuilder eng
unclampHeight =
    updateBuilderClamp (\name -> Builder.clearClamp name "size" "height")


updateBuilderClamp : (String -> AnimBuilder eng -> AnimBuilder eng) -> SizeBuilder eng -> SizeBuilder eng
updateBuilderClamp f (SizeBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            SizeBuilder config (f animGroupName builder)

        Nothing ->
            SizeBuilder config builder
