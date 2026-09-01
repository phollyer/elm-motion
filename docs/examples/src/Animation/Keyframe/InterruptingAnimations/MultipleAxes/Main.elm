module Animation.Keyframe.InterruptingAnimations.MultipleAxes.Main exposing (main)

import Anim.Builder exposing (AnimBuilder, ForKeyframe)
import Anim.Engine.Keyframe as Keyframe
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
        { init = \_ -> init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : Keyframe.AnimState }


{-| Box size expressed as a percentage of the canvas on each axis.
The box width is `boxPct cqw`, height is `boxPct cqh`, and translate
targets are expressed in the matching axis-unit. Everything scales
with the canvas - no Elm-side resize handling required.
-}
boxPct : Float
boxPct =
    12


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init
                [ Translate.initXY animGroupName (targetX XCenter) (targetY YCenter)
                    >> Translate.initCssUnitX Cqw
                    >> Translate.initCssUnitY Cqh
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


moveBoxX : Float -> Keyframe.EngineBuilder -> Keyframe.EngineBuilder
moveBoxX x =
    moveBox (Translate.toX x)


moveBoxY : Float -> Keyframe.EngineBuilder -> Keyframe.EngineBuilder
moveBoxY y =
    moveBox (Translate.toY y)


moveBox : (Translate.Builder ForKeyframe -> Translate.Builder ForKeyframe) -> Keyframe.EngineBuilder -> Keyframe.EngineBuilder
moveBox moveFunc =
    Translate.begin
        >> moveFunc
        >> Translate.speed 25
        >> Translate.easing QuintOut
        >> Translate.end



-- UPDATE


type Msg
    = GotAnimationUpdate Keyframe.AnimMsg
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
                    Keyframe.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.for animGroupName
                            >> moveBoxX (targetX XLeft)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.for animGroupName
                            >> moveBoxX (targetX XRight)
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.for animGroupName
                            >> moveBoxY (targetY YTop)
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        Keyframe.for animGroupName
                            >> moveBoxY (targetY YBottom)
              }
            , Cmd.none
            )



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
                (Keyframe.attributes animGroupName model.animState
                    ++ Keyframe.events GotAnimationUpdate
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
        [ Keyframe.styleNode model.animState
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
