module Animation.Sub.PulsingDot.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Opacity as Opacity
import Anim.Property.Scale as Scale
import Browser
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Motion.Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL
---8<-- [start:model]


type alias Model =
    { animState : Sub.AnimState }



---8<-- [start:trigger]


init : ( Model, Cmd Msg )
init =
    let
        animState =
            Sub.init
                [ Scale.init groupName 1
                , Opacity.init groupName 1
                ]
    in
    ( { animState = Sub.animate animState pulse }
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


pulse : Sub.EngineBuilder -> Sub.EngineBuilder
pulse =
    Sub.loopForever
        >> Sub.alternate
        >> Sub.duration 1000
        >> Sub.easing EaseInOut
        >> Scale.for groupName
        >> Scale.to 0.4
        >> Scale.build
        >> Opacity.for groupName
        >> Opacity.to 0.3
        >> Opacity.build



---8<-- [end:build]
-- UPDATE
---8<-- [start:update]


type Msg
    = GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg animMsg ->
            let
                ( animState, _ ) =
                    Sub.update animMsg model.animState
            in
            ( { model | animState = animState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



---8<-- [end:update]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage" ]
        ---8<-- [start:render]
        [ div
            (Sub.attributes groupName model.animState
                ++ [ style "width" "80px"
                   , style "height" "80px"
                   , style "border-radius" "50%"
                   , style "background-color" "#e53935"
                   ]
            )
            []
        ]



---8<-- [end:render]
