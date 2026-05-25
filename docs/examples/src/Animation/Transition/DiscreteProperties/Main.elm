module Animation.Transition.DiscreteProperties.Main exposing (main)

import Anim.Engine.Transition as Transition exposing (EngineBuilder)
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
    { animState : Transition.AnimState
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ Transition.discreteEntry "display" "flex"
                    >> Opacity.init animGroup 1
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "fadeAnim"


fadeIn : EngineBuilder -> EngineBuilder
fadeIn =
    Transition.discreteEntry "display" "flex"
        >> Opacity.for animGroup
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing QuartIn
        >> Opacity.build


fadeOut : EngineBuilder -> EngineBuilder
fadeOut =
    Transition.discreteExit "display" "flex" "none"
        >> Opacity.for animGroup
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing CubicIn
        >> Opacity.build



-- UPDATE


type Msg
    = Show
    | Hide
    | GotAnimMsg Transition.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            ( { model
                | animState = Transition.animate model.animState fadeIn
              }
            , Cmd.none
            )

        Hide ->
            ( { model
                | animState = Transition.animate model.animState fadeOut
              }
            , Cmd.none
            )

        GotAnimMsg animMsg ->
            let
                ( newAnimState, _ ) =
                    Transition.update animMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ Transition.startingStyleNode model.animState
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
            (Transition.attributes animGroup model.animState
                ++ Transition.events GotAnimMsg
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
