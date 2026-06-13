module Scroll.Cmd.HorizontalGallery.Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Scroll.Builder as Scroll
import Scroll.Engine.Cmd as Cmd exposing (ScrollBuilder)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( {}, Cmd.none )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    {}



-- UPDATE


type Msg
    = ScrollTo String
    | ScrollComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScrollTo cardId ->
            ( model
            , Cmd.scroll ScrollComplete <|
                scrollToCard cardId
            )

        ---8<-- [end:trigger]
        ScrollComplete ->
            ( model, Cmd.none )



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
view _ =
    div [ class "example-stage" ]
        [ buttonRow
        , filmStrip
        ]


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
