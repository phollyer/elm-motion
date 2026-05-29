module Animation.Sub.ButtonHovers.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Extra.View3D as View3D
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events.Extra.Pointer as Pointer
import Json.Decode as Decode exposing (Decoder)
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
--8<-- [start:model]


type alias Model =
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
                [ Size.initUnit Cqmin
                    >> Size.initHW sizeButton baseHeight baseWidth
                , Size.initUnit Cqmin
                    >> Size.initHW scaleButton baseHeight baseWidth
                , Size.initUnit Cqmin
                    >> Size.initHW zButton baseHeight baseWidth
                ]
      }
    , Cmd.none
    )



--8<-- [end:model]
-- ANIMATIONS
-- Avoid typos from hardcoding strings in multiple places


scaleButton : String
scaleButton =
    "scaleButton"


sizeButton : String
sizeButton =
    "sizeButton"


zButton : String
zButton =
    "zButton"


baseWidth : Float
baseWidth =
    51


baseHeight : Float
baseHeight =
    15.8


hoverWidth : Float
hoverWidth =
    60


hoverHeight : Float
hoverHeight =
    20


hoverDuration : Int
hoverDuration =
    200


hoverEasing : Easing
hoverEasing =
    CubicOut


unhoverEasing : Easing
unhoverEasing =
    CubicIn



---8<-- [start:build]


scaleUp : Sub.EngineBuilder -> Sub.EngineBuilder
scaleUp =
    Scale.for scaleButton
        >> Scale.to 1.1
        >> Scale.duration hoverDuration
        >> Scale.easing hoverEasing
        >> Scale.build


scaleDown : Sub.EngineBuilder -> Sub.EngineBuilder
scaleDown =
    Scale.for scaleButton
        >> Scale.to 1
        >> Scale.duration hoverDuration
        >> Scale.easing unhoverEasing
        >> Scale.build


growSize : Sub.EngineBuilder -> Sub.EngineBuilder
growSize =
    Size.for sizeButton
        >> Size.cssUnit Cqmin
        >> Size.toHW hoverHeight hoverWidth
        >> Size.duration hoverDuration
        >> Size.easing hoverEasing
        >> Size.build


shrinkSize : Sub.EngineBuilder -> Sub.EngineBuilder
shrinkSize =
    Size.for sizeButton
        >> Size.cssUnit Cqmin
        >> Size.toHW baseHeight baseWidth
        >> Size.duration hoverDuration
        >> Size.easing unhoverEasing
        >> Size.build


liftUp : Sub.EngineBuilder -> Sub.EngineBuilder
liftUp =
    Translate.for zButton
        >> Translate.toZ 60
        >> Translate.duration hoverDuration
        >> Translate.easing hoverEasing
        >> Translate.build


setDown : Sub.EngineBuilder -> Sub.EngineBuilder
setDown =
    Translate.for zButton
        >> Translate.toZ 0
        >> Translate.duration hoverDuration
        >> Translate.easing unhoverEasing
        >> Translate.build



---8<-- [end:build]
-- UPDATE
--8<-- [start:Msg]


type Msg
    = GotSubMsg Sub.AnimMsg
      --8<-- [end:Msg]
    | ScaleHover
    | ScaleUnhover
    | SizeHover
    | SizeUnhover
    | ZHover
    | ZUnhover



--8<-- [start:update]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg animMsg ->
            let
                ( animState, _ ) =
                    Sub.update animMsg model.animState
            in
            ( { model | animState = animState }
            , Cmd.none
            )

        ---8<-- [end:update]
        ---8<-- [start:trigger]
        ScaleHover ->
            ( { model | animState = Sub.animate model.animState scaleUp }
            , Cmd.none
            )

        ScaleUnhover ->
            ( { model | animState = Sub.animate model.animState scaleDown }
            , Cmd.none
            )

        SizeHover ->
            ( { model | animState = Sub.animate model.animState growSize }
            , Cmd.none
            )

        SizeUnhover ->
            ( { model | animState = Sub.animate model.animState shrinkSize }
            , Cmd.none
            )

        ZHover ->
            ( { model | animState = Sub.animate model.animState liftUp }
            , Cmd.none
            )

        ZUnhover ->
            ( { model | animState = Sub.animate model.animState setDown }
            , Cmd.none
            )



---8<-- [end:trigger]
-- SUBSCRIPTIONS
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



---8<-- [end:subscriptions]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "container-type" "size"
        ]
        [ div
            [ style "padding" "7px"
            , style "border-radius" "12px"
            , style "border" "2px solid #041e53"
            , style "justify-content" "center"
            , style "gap" "clamp(12px, 3vmin, 24px)"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "align-items" "center"
            ]
            [ button "Scale" ScaleHover ScaleUnhover scaleButton model.animState
            , button "Size" SizeHover SizeUnhover sizeButton model.animState
            , div
                [ View3D.perspective 600 ]
                [ button "Translate Z" ZHover ZUnhover zButton model.animState ]
            ]
        ]



---8<-- [start:render]


button : String -> Msg -> Msg -> String -> Sub.AnimState -> Html Msg
button label hoverMsg unhoverMsg groupName animState =
    div
        (Sub.attributes groupName animState
            ++ [ Pointer.onEnter (\_ -> hoverMsg)
               , Pointer.onLeave (\_ -> unhoverMsg)
               , style "display" "flex"
               , style "align-items" "center"
               , style "justify-content" "center"
               , style "background-color" "#3b82f6"
               , style "color" "white"
               , style "font-size" "clamp(14px, 3.5cqw, 26px)"
               , style "font-weight" "600"
               , style "padding" "0 clamp(8px, 2.2cqmin, 16px)"
               , style "border-radius" "8px"
               , style "cursor" "pointer"
               , style "touch-action" "manipulation"
               , style "-webkit-tap-highlight-color" "transparent"
               , style "user-select" "none"
               , style "box-sizing" "border-box"
               , style "box-shadow" "0 3px 5px rgba(0, 0, 0, 0.5), 0 1px 3px rgba(0, 0, 0, 0.4)"
               ]
        )
        [ text label ]



---8<-- [end:render]
