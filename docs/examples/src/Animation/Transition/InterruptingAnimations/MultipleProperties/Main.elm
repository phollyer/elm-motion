module Animation.Transition.InterruptingAnimations.MultipleProperties.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as CustomColor
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animState : Transition.AnimState }


animGroupName : String
animGroupName =
    "movingBox"


{-| Box size expressed as a percentage of the canvas width. The box uses
`boxPct cqw` for both width and height so it always stays square, and
`Translate.toX` targets are
in `cqw` units, so the left, center and right anchors all scale with the
canvas. The box is vertically centered via CSS (`top: calc(50% - half box)`)
so no Y animation is needed - one less moving part and zero Elm-side
resize plumbing.
-}
boxPct : Float
boxPct =
    12


centerXCqw : Float
centerXCqw =
    (100 - boxPct) / 2


boxHalfPct : Float
boxHalfPct =
    boxPct / 2


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Transition.init
                [ Translate.initUnitX Cqw
                    >> Translate.initX animGroupName centerXCqw
                , CustomColor.init animGroupName CustomColor.BackgroundColor <| Color.rgb 118 118 118
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
        >> Translate.speed 25
        >> Translate.easing BounceOut
        >> Translate.build


changeColor : Color -> AnimBuilder mode -> AnimBuilder mode
changeColor color =
    CustomColor.for animGroupName CustomColor.BackgroundColor
        >> CustomColor.to color
        >> CustomColor.duration 3000
        >> CustomColor.easing Linear
        >> CustomColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transition.AnimMsg
    | MoveLeft
    | MoveRight
    | ChangeColor Color


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    Transition.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        moveBoxX (targetX XLeft)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        moveBoxX (targetX XRight)
              }
            , Cmd.none
            )

        ChangeColor color ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        changeColor color
              }
            , Cmd.none
            )



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
        [ text ""
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
                (Transition.attributes animGroupName model.animState
                    ++ Transition.events GotAnimationUpdate
                    ++ [ style "width" (String.fromFloat boxPct ++ "cqw")
                       , style "height" (String.fromFloat boxPct ++ "cqw")
                       , style "position" "absolute"
                       , style "top" ("calc(50% - " ++ String.fromFloat boxHalfPct ++ "cqw)")
                       , style "left" "0"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]
