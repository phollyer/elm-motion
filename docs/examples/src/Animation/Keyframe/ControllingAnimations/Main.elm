module Animation.Keyframe.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, button, div, text)
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
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init
                [ Translate.initY animGroup 0 >> Translate.initUnitY Cqh ]
      }
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


dropBall : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
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
    | GotAnimMsg Keyframe.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState =
                    Keyframe.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Keyframe.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            let
                ( newState, pauseCmd ) =
                    Keyframe.pause animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, pauseCmd )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            let
                ( newState, resumeCmd ) =
                    Keyframe.resume animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, resumeCmd )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Keyframe.reset animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newState, restartCmd ) =
                    Keyframe.restart animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, restartCmd )

        ---8<-- [end:restart]
        GotAnimMsg _ ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ Keyframe.styleNodeFor animGroup model.animState
        , div [ class "example-controls" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "🏀 Animate" ]
            , button [ onClick Pause, class "ui-action-button success" ] [ text "⏸️ Pause" ]
            , button [ onClick Resume, class "ui-action-button success" ] [ text "▶️ Resume" ]
            , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            , button [ onClick Restart, class "ui-action-button purple" ] [ text "🔄 Restart" ]
            ]
        , animationArea model.animState
        ]


animationArea : Keyframe.AnimState -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "border-bottom" "2px solid #333"
        , style "container-type" "size"
        ]
        [ div
            (Keyframe.attributes animGroup animState
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
