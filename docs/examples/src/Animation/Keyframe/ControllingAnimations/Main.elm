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
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Keyframe.init
                [ Translate.initY animGroup 0 ]
      }
    , Cmd.none
    )


animGroup : String
animGroup =
    "bouncingBall"


{-| Ball size as a percentage of the canvas height (in `cqh` units). The
canvas declares `container-type: size`, so `cqh` resolves against the
canvas itself - the animation, ball size and travel distance all scale
with the canvas regardless of viewport size or surrounding chrome. No
Elm-side resize plumbing required; the browser re-evaluates `cqh` against
current layout on every frame.
-}
ballSize : Float
ballSize =
    12


ballSizeCqh : String
ballSizeCqh =
    String.fromFloat ballSize ++ "cqh"



-- ANIMATION


dropBall : AnimBuilder mode -> AnimBuilder mode
dropBall =
    Translate.for animGroup
        >> Translate.cssUnit Cqh
        >> Translate.fromY 0
        >> Translate.toY (100 - ballSize)
        >> Translate.speed 100
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-badge example-badge--static" ] [ text "Static" ]
        , Keyframe.styleNodeFor animGroup model.animState
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
