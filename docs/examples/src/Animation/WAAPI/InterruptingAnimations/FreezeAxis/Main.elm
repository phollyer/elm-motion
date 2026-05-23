port module Animation.WAAPI.InterruptingAnimations.FreezeAxis.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MODEL


animGroup : String
animGroup =
    "movingBox"


type alias Model =
    { animState : WAAPI.AnimState Msg }


{-| Box size expressed as a percentage of the canvas on each axis.
The box width is `boxPct cqw`, height is `boxPct cqh`, and translate
targets are expressed in the matching axis-unit. Everything scales
with the canvas - no Elm-side resize handling required.
-}
boxPct : Float
boxPct =
    12


centerXCqw : Float
centerXCqw =
    (100 - boxPct) / 2


centerYCqh : Float
centerYCqh =
    (100 - boxPct) / 2



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initUnitX Cqw
                    >> Translate.initUnitY Cqh
                    >> Translate.initXY animGroup centerXCqw centerYCqh
                ]
      }
    , Cmd.none
    )



-- POSITION HELPERS


type XPos
    = XLeft
    | XCenter
    | XRight


type YPos
    = YTop
    | YCenter
    | YBottom


{-| X target in `cqw` (0..100 - boxPct).
-}
targetX : XPos -> Float
targetX pos =
    case pos of
        XLeft ->
            0

        XCenter ->
            (100 - boxPct) / 2

        XRight ->
            100 - boxPct


{-| Y target in `cqh` (0..100 - boxPct).
-}
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


moveBoxX : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxX x =
    moveBox <|
        Translate.toX x


moveBoxY : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxY y =
    moveBox <|
        Translate.toY y


moveBox : (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveBox moveFunc =
    Translate.for animGroup
        >> Translate.cssUnitX Cqw
        >> Translate.cssUnitY Cqh
        >> moveFunc
        >> Translate.speed 25
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
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
                    WAAPI.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        ---8<-- [start:WithFreeze]
        MoveLeft ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeY [ WAAPI.translate ]
                            >> moveBoxX (targetX XLeft)
            in
            ( { model | animState = newAnimState }, cmd )

        MoveRight ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeY [ WAAPI.translate ]
                            >> moveBoxX (targetX XRight)
            in
            ( { model | animState = newAnimState }, cmd )

        MoveUp ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeX [ WAAPI.translate ]
                            >> moveBoxY (targetY YTop)
            in
            ( { model | animState = newAnimState }, cmd )

        MoveDown ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeX [ WAAPI.translate ]
                            >> moveBoxY (targetY YBottom)
            in
            ( { model | animState = newAnimState }, cmd )



---8<-- [end:WithFreeze]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    WAAPI.subscriptions GotAnimationUpdate model.animState



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
                (WAAPI.attributes animGroup model.animState
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
        [ div [ class "example-badge example-badge--responsive" ] [ text "RESPONSIVE" ]
        , div [ class "example-controls" ]
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
