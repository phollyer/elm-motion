module Animation.Transition.Easings.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Property.Translate as Translate
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
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : Transition.AnimState
    , easing : Easing
    , atEnd : Bool
    }


animGroup : String
animGroup =
    "easingBox"


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ Translate.initX animGroup 0 ]
      , easing = CubicOut
      , atEnd = False
      }
    , Cmd.none
    )



-- ANIMATION


animateTo : Float -> Easing -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
animateTo x easing =
    Translate.begin
        >> Translate.toX x
        >> Translate.speed 350
        >> Translate.easing easing
        >> Translate.end



-- UPDATE


type Msg
    = Play Easing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Play easing ->
            let
                target =
                    if model.atEnd then
                        0

                    else
                        420
            in
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        Transition.for animGroup
                            >> animateTo target easing
                , easing = easing
                , atEnd = not model.atEnd
              }
            , Cmd.none
            )



-- VIEW


curves : List ( Easing, String )
curves =
    [ ( Linear, "Linear" )
    , ( QuadOut, "QuadOut" )
    , ( ExpoOut, "ExpoOut" )
    , ( ElasticOut, "ElasticOut" )
    , ( BounceOut, "BounceOut" )
    , ( BackInOut, "BackInOut" )
    ]


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "height" "auto"
        , style "min-height" "260px"
        ]
        [ div [ class "example-controls" ]
            (List.map (curveButton model.easing) curves)
        , div
            [ style "width" "100%"
            , style "max-width" "480px"
            , style "height" "70px"
            , style "display" "flex"
            , style "align-items" "center"
            ]
            [ div
                (Transition.attributes animGroup model.animState
                    ++ [ style "width" "60px"
                       , style "height" "60px"
                       , style "background-color" "#3498db"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]


curveButton : Easing -> ( Easing, String ) -> Html Msg
curveButton selected ( easing, label ) =
    let
        variant =
            if easing == selected then
                "primary"

            else
                "purple"
    in
    button
        [ onClick (Play easing)
        , class ("ui-action-button " ++ variant)
        ]
        [ text label ]
