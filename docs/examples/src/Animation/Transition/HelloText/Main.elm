module Animation.Transition.HelloText.Main exposing (main)

import Anim.Engine.Transition as Transition exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Process
import Task



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



---8<-- [start:trigger-cmd]


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ Opacity.init textLineOne 0
                , Opacity.init dotOne 0
                , Opacity.init dotTwo 0
                , Opacity.init dotThree 0
                , Opacity.init textLineTwo 0
                ]
      }
    , Process.sleep 0
        |> Task.perform (always TriggerAnimation)
    )



---8<-- [end:model]
---8<-- [end:trigger-cmd]
-- ANIMATION
---8<-- [start:build]
-- Avoid typos from hardcoding strings in multiple places


duration : Int
duration =
    500


textLineOne : String
textLineOne =
    "textLineOne"


dotOne : String
dotOne =
    "dotOne"


dotTwo : String
dotTwo =
    "dotTwo"


dotThree : String
dotThree =
    "dotThree"


textLineTwo : String
textLineTwo =
    "textLineTwo"


fadeIn : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
fadeIn =
    Opacity.begin
        >> Opacity.to 1
        >> Opacity.duration duration
        >> Opacity.end



---8<-- [end:build]
-- UPDATE


type Msg
    = TriggerAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        TriggerAnimation ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        Transition.for textLineOne
                            >> fadeIn
                            >> Transition.for dotOne
                            >> Transition.delay duration
                            >> fadeIn
                            >> Transition.for dotTwo
                            >> Transition.delay (duration * 2)
                            >> fadeIn
                            >> Transition.for dotThree
                            >> Transition.delay (duration * 3)
                            >> fadeIn
                            >> Transition.for textLineTwo
                            >> Transition.delay (duration * 4)
                            >> fadeIn
              }
            , Cmd.none
            )



---8<-- [end:trigger]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "font-size" "clamp(28px, 10vw, 48px)"
        , style "font-weight" "bold"
        , style "text-align" "center"
        ]
        ---8<-- [start:render]
        [ div
            [ style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "gap" "0.25em"
            ]
            [ div
                (Transition.attributes textLineOne model.animState ++ [])
                [ text "Elm Motion says" ]
            , div
                (Transition.attributes dotOne model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (Transition.attributes dotTwo model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (Transition.attributes dotThree model.animState
                    ++ []
                )
                [ text "." ]
            ]
        , div
            (Transition.attributes textLineTwo model.animState
                ++ [ style "width" "100%" ]
            )
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
