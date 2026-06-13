module Animation.Sub.BorderRadius.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Custom as Property
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, button, div, text)
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
            Sub.init <|
                [ Property.init animGroup (Property.BorderRadius Px) 0 ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "radiusAnim"


standardTiming : Property.Builder { prop | withTiming : () } -> Property.Builder { prop | withTiming : () }
standardTiming =
    Property.duration 800
        >> Property.easing CubicInOut


roundCorners : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
roundCorners =
    Property.begin (Property.BorderRadius Px)
        >> Property.to 48
        >> standardTiming
        >> Property.end


squareCorners : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
squareCorners =
    Property.begin (Property.BorderRadius Px)
        >> Property.to 0
        >> standardTiming
        >> Property.end



-- UPDATE


type Msg
    = GotSubMsg Sub.AnimMsg
    | TriggerRound
    | TriggerSquare


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        TriggerRound ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.for animGroup
                            >> roundCorners
              }
            , Cmd.none
            )

        TriggerSquare ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.for animGroup
                            >> squareCorners
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ button
                [ onClick TriggerRound
                , class "ui-action-button primary"
                ]
                [ text "Round" ]
            , button
                [ onClick TriggerSquare
                , class "ui-action-button primary"
                ]
                [ text "Square" ]
            ]
        , div
            [ style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            [ div
                (Sub.attributes animGroup model.animState
                    ++ [ class "example-box"
                       , style "background-color" "#6366f1"
                       ]
                )
                []
            ]
        ]
