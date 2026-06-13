module Scroll.Sub.Interrupting.Main exposing (main)

import Browser
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Scroll.Builder as Scroll
import Scroll.Engine.Sub as Sub exposing (ScrollBuilder)



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


type alias Model =
    { scrollState : Sub.ScrollState
    , status : ScrollStatus
    }


type ScrollStatus
    = Idle
    | Scrolling
    | Interrupted
    | Arrived


init : ( Model, Cmd Msg )
init =
    ( { scrollState = Sub.init
      , status = Idle
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScrollTo String
    | GotScrollMsg Sub.ScrollMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo targetId ->
            let
                redirecting =
                    model.status == Scrolling

                ( newScrollState, scrollCmd ) =
                    Sub.scroll GotScrollMsg model.scrollState <|
                        scrollToElement targetId
            in
            ( { model
                | scrollState = newScrollState
                , status =
                    if redirecting then
                        Interrupted

                    else
                        Scrolling
              }
            , scrollCmd
            )

        GotScrollMsg scrollMsg ->
            let
                ( newScrollState, events, scrollCmd ) =
                    Sub.update GotScrollMsg scrollMsg model.scrollState
            in
            ( { model
                | scrollState = newScrollState
                , status = List.foldl applyEvent model.status events
              }
            , scrollCmd
            )


applyEvent : Sub.ScrollEvent -> ScrollStatus -> ScrollStatus
applyEvent event status =
    case event of
        Sub.Ended _ ->
            Arrived

        Sub.Started _ ->
            if status == Interrupted then
                Interrupted

            else
                Scrolling

        _ ->
            status


scrollToElement : String -> ScrollBuilder -> ScrollBuilder
scrollToElement targetId =
    Scroll.forContainer "scroll-container"
        >> Scroll.toElement targetId
        >> Scroll.speed 120
        >> Scroll.easing Linear
        >> Scroll.build



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotScrollMsg model.scrollState



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ button
                [ onClick (ScrollTo "top-target")
                , class "ui-action-button primary"
                ]
                [ text "⬆️ Scroll to Top" ]
            , button
                [ onClick (ScrollTo "bottom-target")
                , class "ui-action-button warning"
                ]
                [ text "⬇️ Scroll to Bottom" ]
            ]
        , statusBar model.status
        , div
            [ id "scroll-container"
            , style "width" "100%"
            , style "flex" "1 1 auto"
            , style "min-height" "0"
            , style "box-sizing" "border-box"
            , style "overflow-y" "auto"
            , style "border" "2px solid #333"
            , style "border-radius" "8px"
            ]
            [ scrollContent ]
        ]


statusBar : ScrollStatus -> Html msg
statusBar status =
    let
        ( color, message ) =
            case status of
                Idle ->
                    ( "#94a3b8", "Idle — try clicking one button, then the other before it finishes" )

                Scrolling ->
                    ( "#3b82f6", "Scrolling…" )

                Interrupted ->
                    ( "#a855f7", "Redirected mid-flight — smoothly continuing to new target" )

                Arrived ->
                    ( "#22c55e", "✓ Arrived" )
    in
    div
        [ style "padding" "6px 14px"
        , style "border-radius" "6px"
        , style "background-color" color
        , style "color" "white"
        , style "font-size" "clamp(11px, 1.8vmin, 14px)"
        , style "font-weight" "500"
        , style "flex" "0 0 auto"
        ]
        [ text message ]


scrollContent : Html msg
scrollContent =
    div [ style "padding" "20px" ]
        [ targetBlock "top-target" "🟢 Top Target" "#22c55e"
        , spacer
        , filler "Scroll through me…"
        , spacer
        , filler "…keep scrolling…"
        , spacer
        , targetBlock "bottom-target" "🔴 Bottom Target" "#ef4444"
        ]


targetBlock : String -> String -> String -> Html msg
targetBlock elementId label color =
    div
        [ id elementId
        , style "padding" "40px"
        , style "background-color" color
        , style "color" "white"
        , style "border-radius" "8px"
        , style "text-align" "center"
        , style "font-size" "clamp(16px, 3vmin, 24px)"
        , style "font-weight" "700"
        ]
        [ text label ]


filler : String -> Html msg
filler label =
    div
        [ style "padding" "16px"
        , style "background" "#f1f5f9"
        , style "border-radius" "8px"
        , style "color" "#475569"
        , style "text-align" "center"
        ]
        [ p [ style "margin" "0" ] [ text label ] ]


spacer : Html msg
spacer =
    div [ style "height" "300px" ] []
