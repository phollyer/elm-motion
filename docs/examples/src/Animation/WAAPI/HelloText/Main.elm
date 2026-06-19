port module Animation.WAAPI.HelloText.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Json.Encode as Encode
import Process
import Task



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
                [ Opacity.init textLineOne 0
                , Opacity.init dotOne 0
                , Opacity.init dotTwo 0
                , Opacity.init dotThree 0
                , Opacity.init textLineTwo 0
                ]

        ( newAnimState, cmd ) =
            WAAPI.animate animState <|
                WAAPI.for textLineOne
                    >> fadeIn
                    >> WAAPI.for dotOne
                    >> WAAPI.delay duration
                    >> fadeIn
                    >> WAAPI.for dotTwo
                    >> WAAPI.delay (duration * 2)
                    >> fadeIn
                    >> WAAPI.for dotThree
                    >> WAAPI.delay (duration * 3)
                    >> fadeIn
                    >> WAAPI.for textLineTwo
                    >> WAAPI.delay (duration * 4)
                    >> fadeIn
    in
    ( { animState = newAnimState }
    , cmd
    )



---8<-- [end:trigger]
---8<-- [end:model]
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
-- VIEW


view : Model msg -> Html msg
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
                (WAAPI.attributes textLineOne model.animState ++ [])
                [ text "Elm Motion says" ]
            , div
                (WAAPI.attributes dotOne model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (WAAPI.attributes dotTwo model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (WAAPI.attributes dotThree model.animState
                    ++ []
                )
                [ text "." ]
            ]
        , div
            (WAAPI.attributes textLineTwo model.animState
                ++ [ style "width" "100%" ]
            )
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
