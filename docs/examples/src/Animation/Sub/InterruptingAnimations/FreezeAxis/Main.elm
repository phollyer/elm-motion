module Animation.Sub.InterruptingAnimations.FreezeAxis.Main exposing (main)

import Anim.Builder exposing (AnimBuilder, ForSub)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : Sub.AnimState }


type XPos
    = XLeft
    | XCenter
    | XRight


type YPos
    = YTop
    | YCenter
    | YBottom


boxPct : Float
boxPct =
    12


centerXCqw : Float
centerXCqw =
    (100 - boxPct) / 2


centerYCqh : Float
centerYCqh =
    (100 - boxPct) / 2


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
                [ Translate.initXY animGroupName centerXCqw centerYCqh
                    >> Translate.initCssUnitX Cqw
                    >> Translate.initCssUnitY Cqh
                ]
      }
    , Cmd.none
    )



-- POSITION HELPERS


targetX : XPos -> Float
targetX pos =
    case pos of
        XLeft ->
            0

        XCenter ->
            (100 - boxPct) / 2

        XRight ->
            100 - boxPct


targetY : YPos -> Float
targetY pos =
    case pos of
        YTop ->
            0

        YCenter ->
            (100 - boxPct) / 2

        YBottom ->
            100 - boxPct



-- ANIMATIONS


moveBoxX : Float -> Sub.EngineBuilder -> Sub.EngineBuilder
moveBoxX x =
    moveBox <|
        Translate.toX x


moveBoxY : Float -> Sub.EngineBuilder -> Sub.EngineBuilder
moveBoxY y =
    moveBox <|
        Translate.toY y


moveBox : (Translate.Builder ForSub -> Translate.Builder ForSub) -> Sub.EngineBuilder -> Sub.EngineBuilder
moveBox moveFunc =
    Translate.begin
        >> moveFunc
        >> Translate.speed 25
        >> Translate.easing BounceOut
        >> Translate.end



-- UPDATE


type Msg
    = GotAnimationUpdate Sub.AnimMsg
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        ---8<-- [start:WithFreeze]
        MoveLeft ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeY [ Sub.translate ]
                            >> Sub.for animGroupName
                            >> moveBoxX (targetX XLeft)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeY [ Sub.translate ]
                            >> Sub.for animGroupName
                            >> moveBoxX (targetX XRight)
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeX [ Sub.translate ]
                            >> Sub.for animGroupName
                            >> moveBoxY (targetY YTop)
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeX [ Sub.translate ]
                            >> Sub.for animGroupName
                            >> moveBoxY (targetY YBottom)
              }
            , Cmd.none
            )



---8<-- [end:WithFreeze]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimationUpdate model.animState



-- VIEW


view : Model -> Html Msg
view model =
    let
        button bgColor label onClickMsg =
            Html.button
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "background-color" bgColor
                ]
                [ text label ]

        moveLeftButton =
            button "#007BFF" "Move Left" MoveLeft

        moveRightButton =
            button "#28A745" "Move Right" MoveRight

        moveUpButton =
            button "#6F42C1" "Move Up" MoveUp

        moveDownButton =
            button "#FFC107" "Move Down" MoveDown

        box =
            div
                (Sub.attributes animGroupName model.animState
                    ++ [ style "width" (String.fromFloat boxPct ++ "cqw")
                       , style "height" (String.fromFloat boxPct ++ "cqh")
                       , style "background-color" "#FF5733"
                       , style "border-radius" "8px"
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
                       ]
                )
                []
    in
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ moveLeftButton
            , moveRightButton
            , moveUpButton
            , moveDownButton
            ]
        , div
            [ class "example-canvas--fluid"
            , style "container-type" "size"
            ]
            [ box ]
        ]
