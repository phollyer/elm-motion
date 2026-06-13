module Scroll.Sub.ControllingScrolls.Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, p, text)
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
    { scrollState : Sub.ScrollState }



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { scrollState = Sub.init }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ScrollAnimate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | GotScrollMsg Sub.ScrollMsg
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotScrollMsg scrollMsg ->
            let
                ( newScrollState, _, scrollCmd ) =
                    Sub.update GotScrollMsg scrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ScrollAnimate ->
            let
                ( newScrollState, scrollCmd ) =
                    Sub.scroll GotScrollMsg model.scrollState scrollAnimation
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [start:stop]
        Stop ->
            let
                ( newScrollState, scrollCmd ) =
                    Sub.stop scrollContainer GotScrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            ( { model | scrollState = Sub.pause scrollContainer model.scrollState }
            , Cmd.none
            )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            ( { model | scrollState = Sub.resume scrollContainer model.scrollState }
            , Cmd.none
            )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            let
                ( newScrollState, scrollCmd ) =
                    Sub.reset scrollContainer GotScrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newScrollState, scrollCmd ) =
                    Sub.restart scrollContainer GotScrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )



---8<-- [end:restart]
-- ANIMATION


containerId : String
containerId =
    "scroll-container"


scrollContainer : Sub.Container
scrollContainer =
    Sub.Container containerId


targetId : String
targetId =
    "scroll-target"


scrollAnimation : ScrollBuilder -> ScrollBuilder
scrollAnimation =
    Scroll.forContainer containerId
        >> Scroll.toElement targetId
        >> Scroll.speed 200
        >> Scroll.easing BounceOut
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
            [ button [ onClick ScrollAnimate, class "ui-action-button primary" ] [ text "📜 Scroll" ]
            , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
            , button [ onClick Pause, class "ui-action-button success" ] [ text "⏸️ Pause" ]
            , button [ onClick Resume, class "ui-action-button success" ] [ text "▶️ Resume" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            , button [ onClick Restart, class "ui-action-button purple" ] [ text "🔄 Restart" ]
            ]
        , scrollableContainer
        ]


scrollableContainer : Html msg
scrollableContainer =
    div
        [ id containerId
        , style "width" "100%"
        , style "flex" "1 1 auto"
        , style "min-height" "0"
        , style "box-sizing" "border-box"
        , style "border" "2px solid #cbd5e1"
        , style "border-radius" "12px"
        , style "background" "white"
        , style "box-shadow" "0 4px 20px rgba(0, 0, 0, 0.1)"
        , style "overflow-y" "auto"
        ]
        [ contentSections ]


contentSections : Html msg
contentSections =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "20px"
        , style "padding" "20px"
        ]
        (List.concat
            [ [ contentSection "📍 Start" "This is the beginning of the scrollable content." "#3b82f6" ]
            , List.indexedMap
                (\i _ ->
                    contentSection
                        ("Section " ++ String.fromInt (i + 1))
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                        "#475569"
                )
                (List.repeat 5 ())
            , [ targetSection ]
            , List.indexedMap
                (\i _ ->
                    contentSection
                        ("Section " ++ String.fromInt (i + 7))
                        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
                        "#475569"
                )
                (List.repeat 3 ())
            , [ contentSection "📍 End" "This is the end of the scrollable content." "#3b82f6" ]
            ]
        )


contentSection : String -> String -> String -> Html msg
contentSection title description color =
    div
        [ style "padding" "12px 16px"
        , style "background" "#f8fafc"
        , style "border-radius" "8px"
        ]
        [ div
            [ style "font-weight" "bold"
            , style "font-size" "16px"
            , style "color" color
            , style "margin-bottom" "8px"
            ]
            [ text title ]
        , p
            [ style "font-size" "14px"
            , style "color" "#475569"
            , style "margin" "0"
            ]
            [ text description ]
        ]


targetSection : Html msg
targetSection =
    div
        [ id targetId
        , style "padding" "12px 16px"
        , style "background" "#fff3e0"
        , style "border-radius" "8px"
        , style "border" "2px solid #ff9800"
        ]
        [ div
            [ style "font-weight" "bold"
            , style "font-size" "18px"
            , style "color" "#e65100"
            , style "margin-bottom" "8px"
            ]
            [ text "🎯 Target Section" ]
        , p
            [ style "font-size" "14px"
            , style "color" "#475569"
            , style "margin" "0"
            ]
            [ text "This is the scroll target. The scroll animation will bring this section into view." ]
        ]
