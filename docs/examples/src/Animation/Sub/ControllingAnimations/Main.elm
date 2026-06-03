module Animation.Sub.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
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


animGroup : String
animGroup =
    "bouncingBall"


ballSize : Float
ballSize =
    12


ballSizeCqh : String
ballSizeCqh =
    String.fromFloat ballSize ++ "cqh"



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
                [ Translate.initY animGroup 0 >> Translate.initUnitY Cqh ]
      }
    , Cmd.none
    )



-- ANIMATION


dropBall : Sub.EngineBuilder -> Sub.EngineBuilder
dropBall =
    Translate.for animGroup
        >> Translate.fromY 0
        >> Translate.toY (100 - ballSize)
        >> Translate.speed 75
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | GotSubMsg Sub.AnimMsg


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

        Animate ->
            ( { model
                | animState =
                    Sub.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Sub.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            ( { model | animState = Sub.pause animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            ( { model | animState = Sub.resume animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Sub.reset animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            ( { model | animState = Sub.restart animGroup model.animState }
            , Cmd.none
            )



---8<-- [end:restart]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "🏀 Animate" ]
            , button [ onClick Pause, class "ui-action-button success" ] [ text "⏸️ Pause" ]
            , button [ onClick Resume, class "ui-action-button success" ] [ text "▶️ Resume" ]
            , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            , button [ onClick Restart, class "ui-action-button purple" ] [ text "🔄 Restart" ]
            ]
        , animationArea model.animState
        ]


animationArea : Sub.AnimState -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "border-bottom" "2px solid #333"
        , style "container-type" "size"
        ]
        [ div
            (Sub.attributes animGroup animState
                ++ [ style "position" "absolute"
                   , style "left" ("calc(50% - " ++ String.fromFloat (ballSize / 2) ++ "cqh)")
                   , style "width" ballSizeCqh
                   , style "height" ballSizeCqh
                   , style "font-size" ballSizeCqh
                   , style "line-height" ballSizeCqh
                   ]
            )
            [ text "🏀" ]
        ]
