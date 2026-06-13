module Scroll.Sub.HorizontalGallery.Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
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
---8<-- [start:model]


type alias Model =
    { scrollState : Sub.ScrollState
    , status : ScrollStatus
    }


type ScrollStatus
    = Idle
    | Scrolling Float Float
    | Arrived


init : ( Model, Cmd Msg )
init =
    ( { scrollState = Sub.init
      , status = Idle
      }
    , Cmd.none
    )



---8<-- [end:model]
-- UPDATE


type Msg
    = ScrollTo String
    | GotScrollMsg Sub.ScrollMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScrollTo cardId ->
            let
                ( newScrollState, scrollCmd ) =
                    Sub.scroll GotScrollMsg model.scrollState <|
                        scrollToCard cardId
            in
            ( { model | scrollState = newScrollState }, scrollCmd )

        ---8<-- [end:trigger]
        ---8<-- [start:updateScroll]
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



---8<-- [end:updateScroll]


applyEvent : Sub.ScrollEvent -> ScrollStatus -> ScrollStatus
applyEvent event _ =
    case event of
        Sub.Progress _ pos progress ->
            Scrolling pos.x progress

        Sub.Ended _ ->
            Arrived

        _ ->
            Idle



---8<-- [start:build]


scrollToCard : String -> ScrollBuilder -> ScrollBuilder
scrollToCard cardId =
    Scroll.forContainer "gallery"
        >> Scroll.toElement cardId
        >> Scroll.onXAxis
        >> Scroll.speed 500
        >> Scroll.easing EaseInOut
        >> Scroll.build



---8<-- [end:build]
-- SUBSCRIPTIONS
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotScrollMsg model.scrollState



---8<-- [end:subscriptions]
-- VIEW


photos : List { id : String, label : String, color : String, emoji : String }
photos =
    [ { id = "photo-mountains", label = "Mountains", color = "#4a6f8a", emoji = "🏔️" }
    , { id = "photo-ocean", label = "Ocean", color = "#1a7a6e", emoji = "🌊" }
    , { id = "photo-desert", label = "Desert", color = "#c47b3a", emoji = "🏜️" }
    , { id = "photo-forest", label = "Forest", color = "#3a7a45", emoji = "🌲" }
    , { id = "photo-arctic", label = "Arctic", color = "#5b7fa6", emoji = "🧊" }
    , { id = "photo-volcano", label = "Volcano", color = "#8b3a3a", emoji = "🌋" }
    , { id = "photo-savanna", label = "Savanna", color = "#8b7a3a", emoji = "🦁" }
    , { id = "photo-reef", label = "Reef", color = "#2a7a8b", emoji = "🐠" }
    ]


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ buttonRow
        , statusBar model.status
        , filmStrip
        ]


statusBar : ScrollStatus -> Html msg
statusBar status =
    let
        ( color, message ) =
            case status of
                Idle ->
                    ( "#94a3b8", "Click a photo to navigate" )

                Scrolling xPos progress ->
                    ( "#3b82f6"
                    , "x = "
                        ++ String.fromInt (round xPos)
                        ++ "px  ("
                        ++ String.fromInt (round (progress * 100))
                        ++ "%)"
                    )

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
        , style "font-family" "monospace"
        , style "flex" "0 0 auto"
        ]
        [ text message ]


buttonRow : Html Msg
buttonRow =
    div [ class "example-controls" ]
        (List.map navButton photos)


navButton : { id : String, label : String, color : String, emoji : String } -> Html Msg
navButton photo =
    button
        [ onClick (ScrollTo photo.id)
        , class "ui-action-button"
        , style "background-color" photo.color
        ]
        [ text (photo.emoji ++ " " ++ photo.label) ]


filmStrip : Html Msg
filmStrip =
    ---8<-- [start:render]
    div
        [ id "gallery"
        , style "display" "flex"
        , style "overflow-x" "auto"
        , style "overflow-y" "hidden"
        , style "gap" "12px"
        , style "padding" "12px"
        , style "border" "2px solid #333"
        , style "border-radius" "8px"
        , style "width" "100%"
        , style "flex" "1 1 auto"
        , style "min-height" "0"
        , style "box-sizing" "border-box"
        ]
        (List.map photoCard photos)



---8<-- [end:render]


photoCard : { id : String, label : String, color : String, emoji : String } -> Html Msg
photoCard photo =
    div
        [ id photo.id
        , style "min-width" "clamp(140px, 35vmin, 220px)"
        , style "height" "100%"
        , style "background-color" photo.color
        , style "border-radius" "8px"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "color" "white"
        , style "flex-shrink" "0"
        ]
        [ div [ style "font-size" "clamp(36px, 9vmin, 64px)" ] [ text photo.emoji ]
        , div
            [ style "font-size" "clamp(13px, 2.2vmin, 18px)"
            , style "font-weight" "700"
            , style "margin-top" "12px"
            , style "letter-spacing" "0.5px"
            ]
            [ text photo.label ]
        ]
