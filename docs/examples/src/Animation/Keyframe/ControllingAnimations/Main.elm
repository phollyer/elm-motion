module Animation.Keyframe.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Translate as Translate
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState
    , canvasH : Float
    }


animGroup : String
animGroup =
    "bouncingBall"


canvasId : String
canvasId =
    "anim-canvas"


ballSize : Float
ballSize =
    50


topY : Float
topY =
    25



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Keyframe.init
                [ Translate.initY animGroup topY ]
      , canvasH = 0
      }
    , measureCanvas
    )


measureCanvas : Cmd Msg
measureCanvas =
    Task.attempt GotCanvas (Dom.getElement canvasId)



-- POSITION HELPERS


bottomY : Float -> Float
bottomY h =
    h - ballSize



-- ANIMATION


dropBall : Float -> AnimBuilder mode -> AnimBuilder mode
dropBall toBottomY =
    Translate.for animGroup
        >> Translate.fromY topY
        >> Translate.toY toBottomY
        >> Translate.speed 200
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
    | OnResize
    | GotCanvas (Result Dom.Error Dom.Element)
    | GotAnimMsg Keyframe.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        dropBall (bottomY model.canvasH)
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
        OnResize ->
            ( model, measureCanvas )

        GotCanvas (Ok element) ->
            let
                newCanvasH =
                    element.element.height

                isFirstMeasurement =
                    model.canvasH == 0
            in
            ( { model
                | canvasH = newCanvasH
                , animState =
                    if isFirstMeasurement then
                        model.animState

                    else
                        Keyframe.retarget model.animState <|
                            dropBall (bottomY newCanvasH)
              }
            , Cmd.none
            )

        GotCanvas (Err _) ->
            ( model, Cmd.none )

        GotAnimMsg _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize (\_ _ -> OnResize)



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-badge example-badge--static" ] [ text "Static" ]
        , Keyframe.styleNodeFor animGroup model.animState
        , div [ class "example-controls" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "🏀 Animate" ]
            , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
            , button [ onClick Pause, class "ui-action-button success" ] [ text "⏸️ Pause" ]
            , button [ onClick Resume, class "ui-action-button success" ] [ text "▶️ Resume" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            , button [ onClick Restart, class "ui-action-button purple" ] [ text "🔄 Restart" ]
            ]
        , animationArea model.animState
        ]


animationArea : Keyframe.AnimState -> Html msg
animationArea animState =
    div
        [ id canvasId
        , class "example-canvas--fluid"
        , style "border-bottom" "2px solid #333"
        ]
        [ div
            (Keyframe.attributes animGroup animState
                ++ [ style "position" "absolute"
                   , style "top" "0"
                   , style "left" "calc(50% - 25px)"
                   , style "width" "50px"
                   , style "height" "50px"
                   , style "font-size" "50px"
                   , style "line-height" "50px"
                   , style "text-align" "center"
                   ]
            )
            [ text "🏀" ]
        ]
