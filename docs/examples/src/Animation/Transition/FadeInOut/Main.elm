module Animation.Transition.FadeInOut.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)



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
---8<-- [start:model]


type alias Model =
    { animState : Transition.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ Opacity.init animGroup 0 ]
      }
    , Cmd.none
    )



---8<-- [end:model]
-- ANIMATION
---8<-- [start:build]


animGroup : String
animGroup =
    "fadeAnim"


fadeTo : Float -> Transition.EngineBuilder -> Transition.EngineBuilder
fadeTo to =
    Opacity.for animGroup
        >> Opacity.to to
        >> Opacity.duration 2500
        >> Opacity.build


fadeIn : Transition.EngineBuilder -> Transition.EngineBuilder
fadeIn =
    fadeTo 1


fadeOut : Transition.EngineBuilder -> Transition.EngineBuilder
fadeOut =
    fadeTo 0



---8<-- [end:build]
-- UPDATE


type Msg
    = TriggerFadeIn
    | TriggerFadeOut


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        TriggerFadeIn ->
            ( { model | animState = Transition.animate model.animState fadeIn }
            , Cmd.none
            )

        TriggerFadeOut ->
            ( { model | animState = Transition.animate model.animState fadeOut }
            , Cmd.none
            )



---8<-- [end:trigger]
-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ button
                [ onClick TriggerFadeIn
                , class "ui-action-button primary"
                ]
                [ text "Fade In" ]
            , button
                [ onClick TriggerFadeOut
                , class "ui-action-button primary"
                ]
                [ text "Fade Out" ]
            ]

        ---8<-- [start:render]
        , div
            (Transition.attributes animGroup model.animState
                ++ [ style "background-color" "red"
                   , style "border-radius" "8px"
                   , style "width" "100%"
                   , style "flex" "1 1 auto"
                   , style "min-height" "0"
                   ]
            )
            []

        ---8<-- [end:render]
        ]
