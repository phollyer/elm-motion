module Animation.Sub.DiscreteProperties.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))



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
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
                [ Sub.discreteEntry "display" "flex"
                    >> Opacity.init animGroup 1
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


fadeIn : AnimBuilder mode -> AnimBuilder mode
fadeIn =
    Opacity.for animGroup
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing QuartIn
        >> Opacity.build


fadeOut : AnimBuilder mode -> AnimBuilder mode
fadeOut =
    Opacity.for animGroup
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing CubicIn
        >> Opacity.build



-- UPDATE


type Msg
    = Show
    | Hide
    | GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.discreteEntry "display" "flex"
                            >> fadeIn
              }
            , Cmd.none
            )

        Hide ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.discreteExit "display" "flex" "none"
                            >> fadeOut
              }
            , Cmd.none
            )

        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ text ""
        , div [ class "example-controls" ]
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
            (Sub.attributes animGroup model.animState
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
