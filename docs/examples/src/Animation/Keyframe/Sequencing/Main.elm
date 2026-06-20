module Animation.Keyframe.Sequencing.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
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
    { animState : Keyframe.AnimState
    , direction : Maybe Direction
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init
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


animateRows : Float -> Keyframe.EngineBuilder -> Keyframe.EngineBuilder
animateRows targetX =
    Keyframe.delay globalConfig.delay
        >> Keyframe.speed globalConfig.speed
        >> Keyframe.easing globalConfig.easing
        >> Keyframe.cssUnitX Cqw
        >> Keyframe.for rowOne
        >> Keyframe.delay rowOneConfig.delay
        >> Keyframe.speed rowOneConfig.speed
        >> Keyframe.easing rowOneConfig.easing
        >> moveTo targetX
        >> Keyframe.for rowTwo
        >> Keyframe.delay rowTwoConfig.delay
        >> Keyframe.speed rowTwoConfig.speed
        >> Keyframe.easing rowTwoConfig.easing
        >> moveTo targetX
        >> Keyframe.for rowThree
        >> Keyframe.delay rowThreeConfig.delay
        >> Keyframe.speed rowThreeConfig.speed
        >> Keyframe.easing rowThreeConfig.easing
        >> moveTo targetX
        >> Keyframe.for rowFour
        >> moveTo targetX



-- UPDATE


type Msg
    = GotKeyframeMsg Keyframe.AnimMsg
    | Toggle


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotKeyframeMsg keyframeMsg ->
            let
                ( newAnimState, _ ) =
                    Keyframe.update keyframeMsg model.animState
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
                    Keyframe.animate model.animState <|
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
        [ Keyframe.styleNode model.animState
        , button
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
            ]
            [ div
                (Keyframe.attributes groupName model.animState
                    ++ Keyframe.events GotKeyframeMsg
                    ++ [ style "width" "10cqw"
                       , style "height" "100%"
                       , style "border-radius" "8px"
                       , style "background" "linear-gradient(135deg, #0ea5e9 0%, #22c55e 100%)"
                       ]
                )
                []
            ]
        ]
