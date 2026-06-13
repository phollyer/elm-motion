port module Animation.WAAPI.Retarget.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, button, div, p, text)
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
    { animState : WAAPI.AnimState Msg }


animGroup : String
animGroup =
    "square"


boxSize : Float
boxSize =
    12


endXY : Float
endXY =
    100 - boxSize


init : ( Model, Cmd Msg )
init =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initXY animGroup 0 0 >> Translate.cssUnitX Cqw >> Translate.cssUnitY Cqh
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animateDiagonal : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
animateDiagonal =
    Translate.begin
        >> Translate.toXY endXY endXY
        >> Translate.duration 5000
        >> Translate.easing Linear
        >> Translate.end


retargetYToTop : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
retargetYToTop =
    Translate.begin
        >> Translate.toY 0
        >> Translate.end



-- UPDATE


type Msg
    = Animate
    | RetargetY
    | Reset
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
                    WAAPI.animate model.animState <|
                        WAAPI.for animGroup
                            >> animateDiagonal
            in
            ( { model | animState = newAnimState }
            , animCmd
            )

        RetargetY ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.retarget model.animState <|
                        WAAPI.for animGroup
                            >> retargetYToTop
            in
            ( { model | animState = newAnimState }
            , animCmd
            )

        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resetCmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "▶️ Animate diagonally" ]
            , button [ onClick RetargetY, class "ui-action-button warning" ] [ text "⬆️ Retarget Y to 0" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            ]
        , p [ style "margin" "0 0 8px 0", style "font-size" "13px" ]
            [ text "Press Animate, then mid-flight press \"Retarget Y to 0\". The WAAPI engine snaps Y to 0 while X keeps gliding toward the right edge uninterrupted." ]
        , animationArea model.animState
        ]


animationArea : WAAPI.AnimState msg -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "container-type" "size"
        , style "background-color" "#ffffff"
        , style "border" "2px solid #333"
        , style "border-radius" "8px"
        ]
        [ div
            (WAAPI.attributes animGroup animState
                ++ [ style "position" "absolute"
                   , style "top" "0"
                   , style "left" "0"
                   , style "width" (String.fromFloat boxSize ++ "cqw")
                   , style "height" (String.fromFloat boxSize ++ "cqh")
                   , style "background-color" "rgba(59, 130, 246, 0.35)"
                   , style "border" "0.4cqmin solid rgb(59, 130, 246)"
                   , style "border-radius" "1.6cqmin"
                   , style "box-sizing" "border-box"
                   ]
            )
            []
        ]
