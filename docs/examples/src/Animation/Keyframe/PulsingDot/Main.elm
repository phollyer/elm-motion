module Animation.Keyframe.PulsingDot.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Opacity as Opacity
import Anim.Property.Scale as Scale
import Browser
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Motion.Easing exposing (Easing(..))



-- MAIN


main : Program () Model msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- MODEL
---8<-- [start:model]


type alias Model =
    { animState : Keyframe.AnimState }



---8<-- [start:trigger]


init : ( Model, Cmd msg )
init =
    let
        animState =
            Keyframe.init
                [ Scale.init groupName 1
                , Opacity.init groupName 1
                ]
    in
    ( { animState =
            Keyframe.animate animState <|
                Keyframe.for groupName
                    >> pulse
      }
    , Cmd.none
    )



---8<-- [end:trigger]
---8<-- [end:model]
-- ANIMATION
---8<-- [start:build]
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "pulsingDot"


pulse : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
pulse =
    Keyframe.loopForever
        >> Keyframe.alternate
        >> Keyframe.duration 1000
        >> Keyframe.easing EaseInOut
        >> Scale.begin
        >> Scale.to 0.4
        >> Scale.end
        >> Opacity.begin
        >> Opacity.to 0.3
        >> Opacity.end



---8<-- [end:build]
-- VIEW


view : Model -> Html msg
view model =
    div
        [ class "example-stage" ]
        ---8<-- [start:render]
        [ Keyframe.styleNode model.animState
        , div
            (Keyframe.attributes groupName model.animState
                ++ [ style "width" "80px"
                   , style "height" "80px"
                   , style "border-radius" "50%"
                   , style "background-color" "#e53935"
                   ]
            )
            []
        ]



---8<-- [end:render]
