module Animation.Keyframe.Retarget.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init
                [ Translate.initXY animGroup 0 0 >> Translate.cssUnitX Cqw >> Translate.cssUnitY Cqh
                ]
      }
    , Cmd.none
    )


animGroup : String
animGroup =
    "square"


boxSize : Float
boxSize =
    12


endXY : Float
endXY =
    100 - boxSize



-- ANIMATION


animateDiagonal : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
animateDiagonal =
    Keyframe.for animGroup
        >> Translate.begin
        >> Translate.toXY endXY endXY
        >> Translate.duration 5000
        >> Translate.easing Linear
        >> Translate.end


retargetYToTop : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
retargetYToTop =
    Keyframe.for animGroup
        >> Translate.begin
        >> Translate.toY 0
        >> Translate.end



-- UPDATE


type Msg
    = Animate
    | RetargetY
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model | animState = Keyframe.animate model.animState animateDiagonal }
            , Cmd.none
            )

        RetargetY ->
            ( { model | animState = Keyframe.retarget model.animState retargetYToTop }
            , Cmd.none
            )

        Reset ->
            ( { model | animState = Keyframe.reset animGroup model.animState }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ Keyframe.styleNode model.animState
        , div [ class "example-controls" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "▶️ Animate diagonally" ]
            , button [ onClick RetargetY, class "ui-action-button warning" ] [ text "⬆️ Retarget Y to 0" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            ]
        , p [ style "margin" "0 0 8px 0", style "font-size" "13px" ]
            [ text "Press Animate, then mid-flight press \"Retarget Y to 0\". The Keyframe engine snaps Y to 0; X to it's end value." ]
        , animationArea model.animState
        ]


animationArea : Keyframe.AnimState -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "container-type" "size"
        , style "background-color" "#ffffff"
        , style "border" "2px solid #333"
        , style "border-radius" "8px"
        ]
        [ div
            (Keyframe.attributes animGroup animState
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
