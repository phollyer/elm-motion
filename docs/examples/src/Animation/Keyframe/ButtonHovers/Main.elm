module Animation.Keyframe.ButtonHovers.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Extra.View3D as View3D
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events.Extra.Pointer as Pointer
import Motion.Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL
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


{-| Base resting size expressed in `cqmin` so each button scales with the
shorter axis of `.example-stage` (the stage itself declares
`container-type: size`). The hover state grows the box by ~15% on each
axis - container-relative units mean the demo stays naturally responsive
without any `onResize` plumbing in Elm.
-}
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



--8<-- [start:model]


type alias Model =
    { animState : Keyframe.AnimState }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Keyframe.init
                [ Size.initUnit Cqmin >> Size.initHW sizeButton baseHeight baseWidth
                , Size.initUnit Cqmin >> Size.initHW scaleButton baseHeight baseWidth
                , Size.initUnit Cqmin >> Size.initHW zButton baseHeight baseWidth
                ]
      }
    , Cmd.none
    )



--8<-- [end:model]
-- ANIMATIONS


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


scaleUp : AnimBuilder mode -> AnimBuilder mode
scaleUp =
    Scale.for scaleButton
        >> Scale.to 1.1
        >> Scale.duration hoverDuration
        >> Scale.easing hoverEasing
        >> Scale.build


scaleDown : AnimBuilder mode -> AnimBuilder mode
scaleDown =
    Scale.for scaleButton
        >> Scale.to 1
        >> Scale.duration hoverDuration
        >> Scale.easing unhoverEasing
        >> Scale.build


growSize : AnimBuilder mode -> AnimBuilder mode
growSize =
    Size.for sizeButton
        >> Size.cssUnit Cqmin
        >> Size.toHW hoverHeight hoverWidth
        >> Size.duration hoverDuration
        >> Size.easing hoverEasing
        >> Size.build


shrinkSize : AnimBuilder mode -> AnimBuilder mode
shrinkSize =
    Size.for sizeButton
        >> Size.cssUnit Cqmin
        >> Size.toHW baseHeight baseWidth
        >> Size.duration hoverDuration
        >> Size.easing unhoverEasing
        >> Size.build


liftUp : AnimBuilder mode -> AnimBuilder mode
liftUp =
    Translate.for zButton
        >> Translate.toZ 60
        >> Translate.duration hoverDuration
        >> Translate.easing hoverEasing
        >> Translate.build


setDown : AnimBuilder mode -> AnimBuilder mode
setDown =
    Translate.for zButton
        >> Translate.toZ 0
        >> Translate.duration hoverDuration
        >> Translate.easing unhoverEasing
        >> Translate.build



---8<-- [end:build]
-- UPDATE


type Msg
    = ScaleHover
    | ScaleUnhover
    | SizeHover
    | SizeUnhover
    | ZHover
    | ZUnhover


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScaleHover ->
            ( { model | animState = Keyframe.animate model.animState scaleUp }
            , Cmd.none
            )

        ScaleUnhover ->
            ( { model | animState = Keyframe.animate model.animState scaleDown }
            , Cmd.none
            )

        SizeHover ->
            ( { model | animState = Keyframe.animate model.animState growSize }
            , Cmd.none
            )

        SizeUnhover ->
            ( { model | animState = Keyframe.animate model.animState shrinkSize }
            , Cmd.none
            )

        ZHover ->
            ( { model | animState = Keyframe.animate model.animState liftUp }
            , Cmd.none
            )

        ZUnhover ->
            ( { model | animState = Keyframe.animate model.animState setDown }
            , Cmd.none
            )



---8<-- [end:trigger]
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



---8<-- [end:subscriptions]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "container-type" "size"
        ]
        [ div [ class "example-badge example-badge--responsive" ] [ text "RESPONSIVE" ]
        , Keyframe.styleNode model.animState
        , div
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


button : String -> Msg -> Msg -> String -> Keyframe.AnimState -> Html Msg
button label hoverMsg unhoverMsg groupName animState =
    div
        (Keyframe.attributes groupName animState
            ++ [ Pointer.onEnter (\_ -> hoverMsg)
               , Pointer.onLeave (\_ -> unhoverMsg)
               , style "display" "flex"
               , style "align-items" "center"
               , style "justify-content" "center"
               , style "background-color" "#3b82f6"
               , style "color" "white"
               , style "font-size" "clamp(13px, 10cqmin, 16px)"
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
