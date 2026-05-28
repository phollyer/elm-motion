module Scroll.Sub.FirstScroll.Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Scroll.Builder as ScrollTo
import Scroll.Engine.Sub as Scroll exposing (ScrollBuilder)



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
    { scrollState : Scroll.ScrollState
    , status : ScrollStatus
    }


type ScrollStatus
    = Idle
    | Scrolling
    | Progress { x : Float, y : Float } Float
    | Completed Scroll.Container
    | Failed String


init : ( Model, Cmd Msg )
init =
    ( { scrollState = Scroll.init
      , status = Idle
      }
    , Cmd.none
    )



---8<-- [end:model]
-- UPDATE


type Msg
    = ScrollTo String
    | GotScrollMsg Scroll.ScrollMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScrollTo targetId ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.scroll GotScrollMsg model.scrollState <|
                        scrollToElement targetId
            in
            ( { model | scrollState = newScrollState }, scrollCmd )

        ---8<-- [end:trigger]
        ---8<-- [start:updateScroll]
        GotScrollMsg scrollMsg ->
            let
                ( newScrollState, events, scrollCmd ) =
                    Scroll.update GotScrollMsg scrollMsg model.scrollState

                updatedModel =
                    handleEvents { model | scrollState = newScrollState } events
            in
            ( updatedModel, scrollCmd )



---8<-- [end:updateScroll]


handleEvents : Model -> List Scroll.ScrollEvent -> Model
handleEvents =
    List.foldl handleEvent


handleEvent : Scroll.ScrollEvent -> Model -> Model
handleEvent event model =
    { model
        | status =
            case event of
                Scroll.Started _ ->
                    Scrolling

                Scroll.Ended container ->
                    Completed container

                Scroll.Progress _ xy progress ->
                    Progress xy progress

                _ ->
                    model.status
    }



---8<-- [start:build]


scrollToElement : String -> ScrollBuilder -> ScrollBuilder
scrollToElement targetId =
    ScrollTo.forContainer "scroll-container"
        >> ScrollTo.toElement targetId
        >> ScrollTo.speed 250
        >> ScrollTo.easing BounceOut
        >> ScrollTo.build



---8<-- [end:build]
-- SUBSCRIPTIONS
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions GotScrollMsg model.scrollState



---8<-- [end:subscriptions]
-- VIEW


view : Model -> Html Msg
view model =
    div [ class "example-stage" ]
        [ div [ class "example-controls" ]
            [ styledButton (ScrollTo "top-element") "Scroll to Top"
            , styledButton (ScrollTo "middle-element") "Scroll to Middle"
            , styledButton (ScrollTo "bottom-element") "Scroll to Bottom"
            ]
        , statusBar model.status
        , ---8<-- [start:render]
          div
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

        ---8<-- [end:render]
        ]


statusBar : ScrollStatus -> Html msg
statusBar status =
    let
        ( color, message ) =
            case status of
                Idle ->
                    ( "#94a3b8", "Click a button to scroll" )

                Scrolling ->
                    ( "#f59e0b", "Scrolling..." )

                Completed container ->
                    ( "#22c55e", "✓ Scroll complete for " ++ containerLabel container )

                Progress _ progress ->
                    ( "#3b82f6", "Progress... " ++ String.fromInt (round (progress * 100)) ++ "%" )

                Failed err ->
                    ( "#ef4444", "✗ " ++ err )
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


containerLabel : Scroll.Container -> String
containerLabel container =
    case container of
        Scroll.Document ->
            "document"

        Scroll.Container containerId ->
            containerId


styledButton : Msg -> String -> Html Msg
styledButton msg label =
    button
        [ onClick msg
        , class "ui-action-button"
        , style "background-color" "#6366f1"
        ]
        [ text label ]


scrollContent : Html Msg
scrollContent =
    div
        [ style "padding" "20px" ]
        [ targetElement "top-element" "Top Section" "#4CAF50"
        , spacer
        , targetElement "middle-element" "Middle Section" "#2196F3"
        , spacer
        , targetElement "bottom-element" "Bottom Section" "#9C27B0"
        ]


targetElement : String -> String -> String -> Html Msg
targetElement elementId label color =
    div
        [ id elementId
        , style "padding" "40px"
        , style "background-color" color
        , style "color" "white"
        , style "border-radius" "8px"
        , style "text-align" "center"
        , style "font-size" "24px"
        ]
        [ text label ]


spacer : Html Msg
spacer =
    div [ style "height" "400px" ] []
