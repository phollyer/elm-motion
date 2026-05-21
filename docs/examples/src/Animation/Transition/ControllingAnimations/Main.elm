module Animation.Transition.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animState : Transition.AnimState }



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
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
        >> Translate.length Cqh
        >> Translate.fromY 0
        >> Translate.toY (100 - ballSize)
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState =
                    Transition.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Transition.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Transition.reset animGroup model.animState }
            , Cmd.none
            )



---8<-- [end:reset]
-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-badge example-badge--responsive" ] [ text "RESPONSIVE" ]
        , div [ class "example-controls" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "🏀 Animate" ]
            , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            ]
        , animationArea model.animState
        ]


animationArea : Transition.AnimState -> Html msg
animationArea animState =
    div
        [ class "example-canvas--fluid"
        , style "border-bottom" "2px solid #333"
        , style "container-type" "size"
        ]
        [ div
            (Transition.attributes animGroup animState
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
