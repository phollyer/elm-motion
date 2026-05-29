port module Animation.WAAPI.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))



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
    { animState : WAAPI.AnimState Msg
    }



-- INIT


init : ( Model, Cmd Msg )
init =
    let
        animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initY animGroup 0 ]
    in
    ( { animState = animState }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "bouncingBall"


{-| Ball size as a percentage of the canvas height (in `cqh` units).
-}
ballSize : Float
ballSize =
    12


ballSizeCqh : String
ballSizeCqh =
    String.fromFloat ballSize ++ "cqh"


dropBall : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
dropBall =
    Translate.for animGroup
        >> Translate.cssUnit Cqh
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
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState dropBall
            in
            ( { model | animState = newAnimState }
            , animCmd
            )

        ---8<-- [start:stop]
        Stop ->
            let
                ( newAnimState, stopCmd ) =
                    WAAPI.stop animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , stopCmd
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            let
                ( newAnimState, pauseCmd ) =
                    WAAPI.pause animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , pauseCmd
            )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            let
                ( newAnimState, resumeCmd ) =
                    WAAPI.resume animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resumeCmd
            )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resetCmd
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restart animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , restartCmd
            )



---8<-- [end:restart]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



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


animationArea : WAAPI.AnimState msg -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "border-bottom" "2px solid #333"
        , style "container-type" "size"
        ]
        [ div
            (WAAPI.attributes animGroup animState
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
