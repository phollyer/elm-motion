module Animation.Sub.Springs.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (class, step, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Motion.Spring as Spring exposing (Spring)



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
    { animState : Sub.AnimState
    , selected : String
    , atEnd : Bool
    , stiffness : String
    , damping : String
    , mass : String
    }


animGroup : String
animGroup =
    "springBox"


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
                [ Translate.initX animGroup 0 ]
      , selected = "gentle"
      , atEnd = False
      , stiffness = "120"
      , damping = "14"
      , mass = "1"
      }
    , Cmd.none
    )



-- ANIMATION


animateTo : Float -> Spring -> Sub.EngineBuilder -> Sub.EngineBuilder
animateTo x spring =
    Translate.for animGroup
        >> Translate.toX x
        >> Translate.spring spring
        >> Translate.build



-- UPDATE


type Msg
    = GotSubMsg Sub.AnimMsg
    | Play String Spring
    | PlayCustom
    | SetStiffness String
    | SetDamping String
    | SetMass String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Play label spring ->
            let
                target =
                    if model.atEnd then
                        0

                    else
                        420
            in
            ( { model
                | animState = Sub.animate model.animState (animateTo target spring)
                , selected = label
                , atEnd = not model.atEnd
              }
            , Cmd.none
            )

        PlayCustom ->
            let
                stiffness =
                    parseWithMin 1 model.stiffness

                damping =
                    parseWithMin 0 model.damping

                mass =
                    parseWithMin 0.1 model.mass

                spring =
                    Spring.custom
                        { stiffness = stiffness
                        , damping = damping
                        , mass = mass
                        }

                target =
                    if model.atEnd then
                        0

                    else
                        420
            in
            ( { model
                | animState = Sub.animate model.animState (animateTo target spring)
                , selected = "custom"
                , atEnd = not model.atEnd
                , stiffness = String.fromFloat stiffness
                , damping = String.fromFloat damping
                , mass = String.fromFloat mass
              }
            , Cmd.none
            )

        SetStiffness str ->
            ( { model | stiffness = str }, Cmd.none )

        SetDamping str ->
            ( { model | damping = str }, Cmd.none )

        SetMass str ->
            ( { model | mass = str }, Cmd.none )


parseWithMin : Float -> String -> Float
parseWithMin minValue str =
    String.toFloat str
        |> Maybe.withDefault minValue
        |> max minValue



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


presets : List ( String, Spring )
presets =
    [ ( "noWobble", Spring.noWobble )
    , ( "gentle", Spring.gentle )
    , ( "wobbly", Spring.wobbly )
    , ( "stiff", Spring.stiff )
    , ( "slow", Spring.slow )
    ]


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "height" "auto"
        , style "min-height" "260px"
        ]
        [ div [ class "example-controls" ]
            (List.map (presetButton model.selected) presets)
        , customControls model
        , div
            [ style "width" "100%"
            , style "max-width" "480px"
            , style "height" "70px"
            , style "display" "flex"
            , style "align-items" "center"
            ]
            [ div
                (Sub.attributes animGroup model.animState
                    ++ [ style "width" "60px"
                       , style "height" "60px"
                       , style "background-color" "#3498db"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]


customControls : Model -> Html Msg
customControls model =
    let
        playVariant =
            if model.selected == "custom" then
                "primary"

            else
                "purple"
    in
    div
        [ class "example-controls"
        , style "gap" "12px"
        ]
        [ numberInput "Stiffness" "1" model.stiffness SetStiffness
        , numberInput "Damping" "1" model.damping SetDamping
        , numberInput "Mass" "0.1" model.mass SetMass
        , button
            [ onClick PlayCustom
            , class ("ui-action-button " ++ playVariant)
            ]
            [ text "Play custom" ]
        ]


numberInput : String -> String -> String -> (String -> Msg) -> Html Msg
numberInput labelText stepSize current toMsg =
    label
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "font-size" "12px"
        , style "font-weight" "500"
        , style "color" "#4a5568"
        , style "gap" "4px"
        ]
        [ text labelText
        , input
            [ type_ "number"
            , step stepSize
            , value current
            , onInput toMsg
            , style "width" "80px"
            , style "padding" "6px 8px"
            , style "border" "1px solid #cbd5e0"
            , style "border-radius" "6px"
            , style "font-size" "14px"
            , style "font-family" "inherit"
            ]
            []
        ]


presetButton : String -> ( String, Spring ) -> Html Msg
presetButton selected ( label, spring ) =
    let
        variant =
            if label == selected then
                "primary"

            else
                "purple"
    in
    button
        [ onClick (Play label spring)
        , class ("ui-action-button " ++ variant)
        ]
        [ text label ]
