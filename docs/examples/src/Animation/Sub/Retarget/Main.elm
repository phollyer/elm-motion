module Animation.Sub.Retarget.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as SubEngine
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing exposing (Easing(..))



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
    { animState : SubEngine.AnimState }


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
            SubEngine.init
                [ Translate.initUnitX Cqw
                    >> Translate.initUnitY Cqh
                    >> Translate.initXY animGroup 0 0
                ]
      }
    , Cmd.none
    )



-- ANIMATION


motion : Translate.Builder { eng | withTiming : () } -> Translate.Builder { eng | withTiming : () }
motion =
    Translate.duration 5000
        >> Translate.easing Linear


animateDiagonal : SubEngine.EngineBuilder -> SubEngine.EngineBuilder
animateDiagonal =
    Translate.for animGroup
        >> Translate.toXY endXY endXY
        >> motion
        >> Translate.build


retargetYToTop : SubEngine.EngineBuilder -> SubEngine.EngineBuilder
retargetYToTop =
    Translate.for animGroup
        >> Translate.toY 0
        >> motion
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | RetargetY
    | Reset
    | GotSubMsg SubEngine.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    SubEngine.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate ->
            ( { model | animState = SubEngine.animate model.animState animateDiagonal }
            , Cmd.none
            )

        RetargetY ->
            ( { model | animState = SubEngine.retarget model.animState retargetYToTop }
            , Cmd.none
            )

        Reset ->
            ( { model | animState = SubEngine.reset animGroup model.animState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    SubEngine.subscriptions GotSubMsg model.animState



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
            [ text "Press Animate, then mid-flight press \"Retarget Y to 0\". The Sub engine snaps Y to 0 while X keeps gliding toward the right edge uninterrupted." ]
        , animationArea model.animState
        ]


animationArea : SubEngine.AnimState -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "container-type" "size"
        , style "background-color" "#ffffff"
        , style "border" "2px solid #333"
        , style "border-radius" "8px"
        ]
        [ div
            (SubEngine.attributes animGroup animState
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
