module Factories.Properties.Opacity exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity exposing (Builder)
import Factories.Capabilities exposing (WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing as Easing
import Motion.Spring as Spring


type alias Factory animBuilder eng =
    { init : String -> Float -> (animBuilder -> animBuilder)
    , begin : animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , from : Float -> Builder eng -> Builder eng
    , to : Float -> Builder eng -> Builder eng
    , by : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing.Easing -> Builder eng -> Builder eng
    , spring : Spring.Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , clamp : Float -> Float -> Builder eng -> Builder eng
    , unclamp : Builder eng -> Builder eng
    , set : Float -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { init = Opacity.init
    , begin = Opacity.begin
    , end = Opacity.end
    , from = Opacity.from
    , to = Opacity.to
    , by = Opacity.by
    , delay = Opacity.delay
    , duration = Opacity.duration
    , speed = Opacity.speed
    , easing = Opacity.easing
    , spring = Opacity.spring
    , clamp = Opacity.clamp
    , unclamp = Opacity.unclamp
    , set = Opacity.set
    }
