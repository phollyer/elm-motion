module Animation.Transition.Sequencing.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
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
        , subscriptions = always Sub.none
        }



-- MODEL


type Direction
    = Forward
    | Backward


type alias Model =
    { animState : Transition.AnimState
    , direction : Maybe Direction
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
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
    , easing = BackOut
    }


rowTwo : String
rowTwo =
    "rowTwo"


rowTwoConfig : MotionConfig
rowTwoConfig =
    { delay = 250
    , speed = 75
    , easing = ElasticOut
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


animateRows : Float -> Transition.EngineBuilder -> Transition.EngineBuilder
animateRows targetX =
    Transition.delay globalConfig.delay
        >> Transition.speed globalConfig.speed
        >> Transition.easing globalConfig.easing
        >> Transition.cssUnitX Cqw
        >> Transition.for rowOne
        >> Transition.delay rowOneConfig.delay
        >> Transition.speed rowOneConfig.speed
        >> Transition.easing rowOneConfig.easing
        >> moveTo targetX
        >> Transition.for rowTwo
        >> Transition.delay rowTwoConfig.delay
        >> Transition.speed rowTwoConfig.speed
        >> Transition.easing rowTwoConfig.easing
        >> moveTo targetX
        >> Transition.for rowThree
        >> Transition.delay rowThreeConfig.delay
        >> Transition.speed rowThreeConfig.speed
        >> Transition.easing rowThreeConfig.easing
        >> moveTo targetX
        >> Transition.for rowFour
        >> moveTo targetX



-- UPDATE


type Msg
    = GotTransitionMsg Transition.AnimMsg
    | Toggle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTransitionMsg transitionMsg ->
            let
                ( newAnimState, _ ) =
                    Transition.update transitionMsg model.animState
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
                | animState =
                    Transition.animate model.animState <|
                        animateRows targetX
                , direction = direction
              }
            , Cmd.none
            )



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
            , style "height" "42px"
            , style "border" "1px solid #d4d4d8"
            , style "border-radius" "10px"
            , style "background" "#f8fafc"
            , style "overflow" "hidden"
            ]
            [ div
                (Transition.attributes groupName model.animState
                    ++ Transition.events GotTransitionMsg
                    ++ [ style "width" "10cqw"
                       , style "height" "100%"
                       , style "border-radius" "8px"
                       , style "background" "linear-gradient(135deg, #0ea5e9 0%, #22c55e 100%)"
                       ]
                )
                []
            ]
        ]
