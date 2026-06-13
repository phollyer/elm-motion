port module Animation.WAAPI.PulsingDot.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Anim.Property.Scale as Scale
import Browser
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))



-- PORTS
-- Outgoing Port


port motionCmd : Encode.Value -> Cmd msg



-- Incoming Port


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () (Model msg) msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- MODEL
---8<-- [start:model]


type alias Model msg =
    { animState : WAAPI.AnimState msg }



---8<-- [start:trigger]


init : ( Model msg, Cmd msg )
init =
    let
        animState =
            WAAPI.init motionCmd motionMsg <|
                [ Scale.init groupName 1
                , Opacity.init groupName 1
                ]

        ( newAnimState, cmd ) =
            WAAPI.animate animState <|
                WAAPI.for groupName
                    >> pulse
    in
    ( { animState = newAnimState }
    , cmd
    )



---8<-- [end:trigger]
---8<-- [end:model]
-- ANIMATION
---8<-- [start:build]
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "pulsingDot"


pulse : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
pulse =
    WAAPI.loopForever
        >> WAAPI.alternate
        >> WAAPI.duration 1000
        >> WAAPI.easing EaseInOut
        >> Scale.begin
        >> Scale.to 0.4
        >> Scale.end
        >> Opacity.begin
        >> Opacity.to 0.3
        >> Opacity.end



---8<-- [end:build]
-- VIEW


view : Model msg -> Html msg
view model =
    div
        [ class "example-stage" ]
        ---8<-- [start:render]
        [ div
            (WAAPI.attributes groupName model.animState
                ++ [ style "width" "80px"
                   , style "height" "80px"
                   , style "border-radius" "50%"
                   , style "background-color" "#e53935"
                   ]
            )
            []
        ]



---8<-- [end:render]
