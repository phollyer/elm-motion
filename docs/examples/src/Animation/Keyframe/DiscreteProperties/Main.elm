module Animation.Keyframe.DiscreteProperties.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
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
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init
                [ Keyframe.discreteEntry "display" "none"
                    >> Opacity.init animGroup 0
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "fadeAnim"


fadeIn : AnimBuilder mode -> AnimBuilder mode
fadeIn =
    Opacity.for animGroup
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing QuartIn
        >> Opacity.build


fadeOut : AnimBuilder mode -> AnimBuilder mode
fadeOut =
    Opacity.for animGroup
        >> Opacity.from 1
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing CubicIn
        >> Opacity.build



-- UPDATE


type Msg
    = Show
    | Hide
    | GotAnimMsg Keyframe.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.discreteEntry "display" "flex"
                            >> fadeIn
              }
            , Cmd.none
            )

        Hide ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.discreteExit "display" "flex" "none"
                            >> fadeOut
              }
            , Cmd.none
            )

        GotAnimMsg animMsg ->
            let
                ( newAnimState, _ ) =
                    Keyframe.update animMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ Keyframe.styleNode model.animState
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
            (Keyframe.attributes animGroup model.animState
                ++ Keyframe.events GotAnimMsg
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
