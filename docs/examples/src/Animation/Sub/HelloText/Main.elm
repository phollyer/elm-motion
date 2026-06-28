module Animation.Sub.HelloText.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)



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
                [ Opacity.init textLineOne 0
                , Opacity.init dotOne 0
                , Opacity.init dotTwo 0
                , Opacity.init dotThree 0
                , Opacity.init textLineTwo 0
                ]
    in
    ( { animState =
            Sub.animate animState <|
                Sub.for textLineOne
                    >> fadeIn
                    >> Sub.for dotOne
                    >> Sub.delay duration
                    >> fadeIn
                    >> Sub.for dotTwo
                    >> Sub.delay (duration * 2)
                    >> fadeIn
                    >> Sub.for dotThree
                    >> Sub.delay (duration * 3)
                    >> fadeIn
                    >> Sub.for textLineTwo
                    >> Sub.delay (duration * 4)
                    >> fadeIn
      }
    , Cmd.none
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



--8<-- [end:build]
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
        [ class "example-stage"
        , style "font-size" "clamp(22px, 7vw, 40px)"
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
                (Sub.attributes textLineOne model.animState ++ [])
                [ text "Elm Motion says" ]
            , div
                (Sub.attributes dotOne model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (Sub.attributes dotTwo model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (Sub.attributes dotThree model.animState
                    ++ []
                )
                [ text "." ]
            ]
        , div
            (Sub.attributes textLineTwo model.animState
                ++ [ style "width" "100%" ]
            )
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
