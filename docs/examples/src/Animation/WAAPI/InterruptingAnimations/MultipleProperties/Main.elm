port module Animation.WAAPI.InterruptingAnimations.MultipleProperties.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as BgColor
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


type alias Model =
    { animState : WAAPI.AnimState Msg }


animGroupName : String
animGroupName =
    "movingBox"


{-| Box width expressed as a percentage of the canvas. The box width is
`boxPct cqw`, height is `boxPct cqh`, and `Translate.toX` targets are
in `cqw` units, so the left, center and right anchors all scale with the
canvas. The box is vertically centered via CSS (`top: <centerYCqh>cqh`)
so no Y animation is needed - one less moving part and zero Elm-side
resize plumbing.
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


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initX animGroupName centerXCqw
                , BgColor.init animGroupName BgColor.BackgroundColor <| Color.rgb 118 118 118
                ]
      }
    , Cmd.none
    )



-- POSITION HELPERS


type XPos
    = XLeft
    | XCenter
    | XRight


targetX : XPos -> Float
targetX pos =
    case pos of
        XLeft ->
            0

        XCenter ->
            centerXCqw

        XRight ->
            100 - boxPct



-- COLORS


color1 : Color
color1 =
    Color.rgb 255 87 51


color2 : Color
color2 =
    Color.rgb 40 167 69


color3 : Color
color3 =
    Color.rgb 111 66 193


color4 : Color
color4 =
    Color.rgb 255 193 7



-- ANIMATIONS


moveBoxX : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxX x =
    Translate.for animGroupName
        >> Translate.cssUnit Cqw
        >> Translate.toX x
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build


changeColor : Color -> AnimBuilder mode -> AnimBuilder mode
changeColor color =
    BgColor.for animGroupName BgColor.BackgroundColor
        >> BgColor.to color
        >> BgColor.duration 3000
        >> BgColor.easing Linear
        >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
    | MoveLeft
    | MoveRight
    | ChangeColor Color


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

        MoveLeft ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        moveBoxX (targetX XLeft)
            in
            ( { model | animState = newAnimState }, cmd )

        MoveRight ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        moveBoxX (targetX XRight)
            in
            ( { model | animState = newAnimState }, cmd )

        ChangeColor color ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        changeColor color
            in
            ( { model | animState = newAnimState }, cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    WAAPI.subscriptions GotAnimationUpdate model.animState



-- VIEW


view : Model -> Html Msg
view model =
    let
        posButton bgColor label onClickMsg =
            Html.button
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "background-color" bgColor
                ]
                [ text label ]

        colorButton color label =
            Html.button
                [ onClick (ChangeColor color)
                , class "ui-action-button"
                , style "background-color" (Color.toHex color)
                ]
                [ text label ]
    in
    div [ class "example-stage" ]
        [ div [ class "example-badge example-badge--responsive" ] [ text "RESPONSIVE" ]
        , div [ class "example-controls" ]
            [ posButton "#333" "Move Left" MoveLeft
            , posButton "#333" "Move Right" MoveRight
            ]
        , div [ class "example-controls" ]
            [ colorButton color1 "Color 1"
            , colorButton color2 "Color 2"
            , colorButton color3 "Color 3"
            , colorButton color4 "Color 4"
            ]
        , div
            [ class "example-canvas--fluid"
            , style "container-type" "size"
            ]
            [ div
                (WAAPI.attributes animGroupName model.animState
                    ++ [ style "width" (String.fromFloat boxPct ++ "cqw")
                       , style "height" (String.fromFloat boxPct ++ "cqh")
                       , style "position" "absolute"
                       , style "top" (String.fromFloat centerYCqh ++ "cqh")
                       , style "left" "0"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]
