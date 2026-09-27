module Factories.Properties.CustomColor exposing
    ( Factory
    , factory
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color exposing (Color)
import Anim.Property.CustomColor as CustomColor exposing (Builder, ColorProperty)
import Factories.Capabilities exposing (WithSpring, WithTiming)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)


type alias Factory animBuilder eng =
    { init : String -> ColorProperty -> Color -> (animBuilder -> animBuilder)
    , begin : ColorProperty -> animBuilder -> Builder eng
    , end : Builder eng -> animBuilder
    , from : Color -> Builder eng -> Builder eng
    , to : Color -> Builder eng -> Builder eng
    , delay : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , duration : Int -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , speed : Float -> Builder (WithTiming eng) -> Builder (WithTiming eng)
    , easing : Easing -> Builder eng -> Builder eng
    , spring : Spring -> Builder (WithSpring eng) -> Builder (WithSpring eng)
    , set : Color -> Builder eng -> Builder eng
    }


factory : Factory (AnimBuilder eng) eng
factory =
    { init = CustomColor.init
    , begin = CustomColor.begin
    , end = CustomColor.end
    , from = CustomColor.from
    , to = CustomColor.to
    , delay = CustomColor.delay
    , duration = CustomColor.duration
    , speed = CustomColor.speed
    , easing = CustomColor.easing
    , spring = CustomColor.spring
    , set = CustomColor.set
    }
