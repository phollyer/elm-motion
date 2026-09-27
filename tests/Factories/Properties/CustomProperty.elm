module Factories.Properties.CustomProperty exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Custom as Property exposing (Builder, Property)
import Factories.Capabilities exposing (WithLiveDelta, WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { init : String -> Property -> Float -> (animBuilder -> animBuilder)
    , begin : Property -> animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , from : Float -> Builder eng -> Builder eng
    , to : Float -> Builder eng -> Builder eng
    , by : Float -> Builder (WithLiveDelta eng) -> Builder (WithLiveDelta eng)
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing -> Builder eng -> Builder eng
    , spring : Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , clamp : Float -> Float -> Builder eng -> Builder eng
    , unclamp : Builder eng -> Builder eng
    , set : Float -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { init = Property.init
    , begin = Property.begin
    , end = Property.end
    , from = Property.from
    , to = Property.to
    , by = Property.by
    , delay = Property.delay
    , duration = Property.duration
    , speed = Property.speed
    , easing = Property.easing
    , spring = Property.spring
    , clamp = Property.clamp
    , unclamp = Property.unclamp
    , set = Property.set
    }
