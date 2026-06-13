port module Animation.WAAPI.DiscreteProperties.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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


type alias Model =
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ WAAPI.discreteEntry "display" "none"
                    >> Opacity.init animGroup 0
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "fadeAnim"


fadeIn : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
fadeIn =
    Opacity.begin
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing QuartIn
        >> Opacity.end


fadeOut : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
fadeOut =
    Opacity.begin
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing CubicIn
        >> Opacity.end



-- UPDATE


type Msg
    = Show
    | Hide
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.for animGroup
                            >> WAAPI.discreteEntry "display" "flex"
                            >> fadeIn
            in
            ( { model
                | animState = newAnimState
              }
            , cmd
            )

        Hide ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.for animGroup
                            >> WAAPI.discreteExit "display" "flex" "none"
                            >> fadeOut
            in
            ( { model
                | animState = newAnimState
              }
            , cmd
            )

        GotWaapiMsg waapiMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update waapiMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ button
                [ onClick Show
                , class "ui-action-button primary"
                ]
                [ text "Show" ]
            , button
                [ onClick Hide
                , class "ui-action-button primary"
                ]
                [ text "Hide" ]
            ]
        , p
            [ style "color" "#666"
            , style "font-size" "13px"
            , style "text-align" "center"
            , style "margin" "0"
            ]
            [ text "Uses discreteEntry/discreteExit to flip display on first/last frames." ]
        , div
            (WAAPI.attributes animGroup model.animState
                ++ [ class "example-box"
                   , style "background-color" "#4a90d9"
                   , style "border-radius" "12px"
                   , style "align-items" "center"
                   , style "justify-content" "center"
                   , style "color" "white"
                   , style "font-size" "18px"
                   , style "font-weight" "bold"
                   ]
            )
            [ text "Hello!" ]
        ]
