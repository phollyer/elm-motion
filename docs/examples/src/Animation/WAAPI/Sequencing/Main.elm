port module Animation.WAAPI.Sequencing.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Dict exposing (Dict)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



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


type Direction
    = Forward
    | Backward


type alias Model =
    { animState : WAAPI.AnimState Msg
    , direction : Maybe Direction
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initX rowOne 0
                , Translate.initX rowTwo 0
                , Translate.initX rowThree 0
                , Translate.initX rowFour 0
                ]
      , direction = Nothing
      }
    , Cmd.none
    )



-- ANIMATION


type alias MotionConfig =
    { delay : Int
    , speed : Float
    , easing : Easing
    }


globalConfig : MotionConfig
globalConfig =
    { delay = 1000
    , speed = 50
    , easing = BounceOut
    }


rowOne : String
rowOne =
    "rowOne"


rowOneConfig : MotionConfig
rowOneConfig =
    { delay = 0
    , speed = 85
    , easing = EaseInOut
    }


rowTwo : String
rowTwo =
    "rowTwo"


rowTwoConfig : MotionConfig
rowTwoConfig =
    { delay = 250
    , speed = 75
    , easing = SineInOut
    }


rowThree : String
rowThree =
    "rowThree"


rowThreeConfig : MotionConfig
rowThreeConfig =
    { delay = 500
    , speed = 60
    , easing = QuadInOut
    }


rowFour : String
rowFour =
    "rowFour"


moveTo : Float -> AnimBuilder eng -> AnimBuilder eng
moveTo targetX =
    Translate.begin
        >> Translate.toX targetX
        >> Translate.end


animateRows : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
animateRows targetX =
    WAAPI.delay globalConfig.delay
        >> WAAPI.speed globalConfig.speed
        >> WAAPI.easing globalConfig.easing
        >> WAAPI.cssUnitX Cqw
        >> WAAPI.for rowOne
        >> WAAPI.delay rowOneConfig.delay
        >> WAAPI.speed rowOneConfig.speed
        >> WAAPI.easing rowOneConfig.easing
        >> moveTo targetX
        >> WAAPI.for rowTwo
        >> WAAPI.delay rowTwoConfig.delay
        >> WAAPI.speed rowTwoConfig.speed
        >> WAAPI.easing rowTwoConfig.easing
        >> moveTo targetX
        >> WAAPI.for rowThree
        >> WAAPI.delay rowThreeConfig.delay
        >> WAAPI.speed rowThreeConfig.speed
        >> WAAPI.easing rowThreeConfig.easing
        >> moveTo targetX
        >> WAAPI.for rowFour
        >> moveTo targetX



-- UPDATE


type Msg
    = GotWaapiMsg WAAPI.AnimMsg
    | Toggle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg waapiMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update waapiMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Toggle ->
            let
                ( targetX, direction ) =
                    case model.direction of
                        Just Forward ->
                            ( 0, Just Backward )

                        _ ->
                            ( 90, Just Forward )

                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        animateRows targetX
            in
            ( { model
                | animState = newAnimState
                , direction = direction
              }
            , cmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


rows : List String
rows =
    [ rowOne
    , rowTwo
    , rowThree
    , rowFour
    ]


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "height" "auto"
        , style "min-height" "360px"
        ]
        [ button
            [ class "ui-action-button primary"
            , onClick Toggle
            ]
            [ text "Animate Pipeline" ]
        , div
            [ style "width" "100%"
            , style "max-width" "560px"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "12px"
            , style "margin-top" "14px"
            ]
            (List.map (rowView model) rows)
        ]


rowView : Model -> String -> Html Msg
rowView model groupName =
    div
        [ style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "align-items" "center"
        , style "gap" "8px"
        ]
        [ div
            [ style "position" "relative"
            , style "container-type" "size"
            , style "flex" "1"
            , style "min-width" "0"
            , style "height" "42px"
            , style "border" "1px solid #d4d4d8"
            , style "border-radius" "10px"
            , style "background" "#f8fafc"
            ]
            [ div
                (WAAPI.attributes groupName model.animState
                    ++ [ style "width" "10cqw"
                       , style "height" "100%"
                       , style "border-radius" "8px"
                       , style "background" "linear-gradient(135deg, #0ea5e9 0%, #22c55e 100%)"
                       ]
                )
                []
            ]
        ]
