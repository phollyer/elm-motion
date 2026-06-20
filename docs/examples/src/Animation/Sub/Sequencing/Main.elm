module Animation.Sub.Sequencing.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Dict exposing (Dict)
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
        , subscriptions = subscriptions
        }



-- MODEL


type Direction
    = Forward
    | Backward


type alias Model =
    { animState : Sub.AnimState
    , direction : Maybe Direction
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
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
    , speed = 100
    , easing = Linear
    }


rowOne : String
rowOne =
    "rowOne"


rowOneConfig : MotionConfig
rowOneConfig =
    { delay = 0
    , speed = 400
    , easing = BounceOut
    }


rowTwo : String
rowTwo =
    "rowTwo"


rowTwoConfig : MotionConfig
rowTwoConfig =
    { delay = 250
    , speed = 300
    , easing = BackOut
    }


rowThree : String
rowThree =
    "rowThree"


rowThreeConfig : MotionConfig
rowThreeConfig =
    { delay = 500
    , speed = 200
    , easing = ExpoOut
    }


rowFour : String
rowFour =
    "rowFour"


moveTo : Float -> AnimBuilder eng -> AnimBuilder eng
moveTo targetX =
    Translate.begin
        >> Translate.toX targetX
        >> Translate.end


animateRows : Float -> Sub.EngineBuilder -> Sub.EngineBuilder
animateRows targetX =
    Sub.delay globalConfig.delay
        >> Sub.speed globalConfig.speed
        >> Sub.easing globalConfig.easing
        >> Sub.cssUnitX Cqw
        >> Sub.for rowOne
        >> Sub.delay rowOneConfig.delay
        >> Sub.speed rowOneConfig.speed
        >> Sub.easing rowOneConfig.easing
        >> moveTo targetX
        >> Sub.for rowTwo
        >> Sub.delay rowTwoConfig.delay
        >> Sub.speed rowTwoConfig.speed
        >> Sub.easing rowTwoConfig.easing
        >> moveTo targetX
        >> Sub.for rowThree
        >> Sub.delay rowThreeConfig.delay
        >> Sub.speed rowThreeConfig.speed
        >> Sub.easing rowThreeConfig.easing
        >> moveTo targetX
        >> Sub.for rowFour
        >> moveTo targetX



-- UPDATE


type Msg
    = GotSubMsg Sub.AnimMsg
    | Toggle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
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
            in
            ( { model
                | animState = Sub.animate model.animState (animateRows targetX)
                , direction = direction
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


rows : List ( String, String, String )
rows =
    [ ( rowOne, "Row 1", "delay " ++ String.fromInt rowOneConfig.delay ++ " | speed " ++ String.fromFloat rowOneConfig.speed ++ " | " ++ Easing.toString rowOneConfig.easing )
    , ( rowTwo, "Row 2", "delay " ++ String.fromInt rowTwoConfig.delay ++ " | speed " ++ String.fromFloat rowTwoConfig.speed ++ " | " ++ Easing.toString rowTwoConfig.easing )
    , ( rowThree, "Row 3", "delay " ++ String.fromInt rowThreeConfig.delay ++ " | speed " ++ String.fromFloat rowThreeConfig.speed ++ " | " ++ Easing.toString rowThreeConfig.easing )
    , ( rowFour, "Row 4", "delay " ++ String.fromInt globalConfig.delay ++ " | speed " ++ String.fromFloat globalConfig.speed ++ " | " ++ Easing.toString globalConfig.easing )
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


rowView : Model -> ( String, String, String ) -> Html Msg
rowView model ( groupName, title, meta ) =
    div
        [ style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "align-items" "center"
        , style "gap" "8px"
        ]
        [ div
            [ style "width" "220px"
            , style "font-size" "13px"
            , style "line-height" "1.2"
            ]
            [ div [ style "font-weight" "700" ] [ text title ]
            , div [ style "opacity" "0.75" ] [ text meta ]
            ]
        , div
            [ style "position" "relative"
            , style "container-type" "size"
            , style "flex" "1"
            , style "min-width" "0"
            , style "height" "42px"
            , style "border" "1px solid #d4d4d8"
            , style "border-radius" "10px"
            , style "background" "#f8fafc"
            , style "overflow" "hidden"
            ]
            [ div
                (Sub.attributes groupName model.animState
                    ++ [ style "width" "10cqw"
                       , style "height" "100%"
                       , style "border-radius" "8px"
                       , style "background" "linear-gradient(135deg, #0ea5e9 0%, #22c55e 100%)"
                       ]
                )
                []
            ]
        ]
