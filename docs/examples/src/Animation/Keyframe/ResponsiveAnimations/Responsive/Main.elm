module Animation.Keyframe.ResponsiveAnimations.Responsive.Main exposing (main)

import Anim.Engine.Keyframe as Keyframe exposing (AnimGroupName)
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Dict exposing (Dict)
import Html exposing (Html, div, input, text)
import Html.Attributes as Attributes exposing (class, id, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Motion.Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState
    , widthPct : Float
    , rowStates : Dict AnimGroupName AnimPlayState
    }


type AnimPlayState
    = NotStarted
    | Playing
    | Paused


clampWidthPct : Float -> Float
clampWidthPct pct =
    max 50 (min 100 pct)


boxAnim : String
boxAnim =
    "boxAnim"


allGroups : List AnimGroupName
allGroups =
    [ boxAnim ]


rowState : AnimGroupName -> Model -> AnimPlayState
rowState group model =
    Dict.get group model.rowStates
        |> Maybe.withDefault NotStarted


setRowState : AnimGroupName -> AnimPlayState -> Model -> Model
setRowState group state model =
    { model | rowStates = Dict.insert group state model.rowStates }


trackId : String
trackId =
    "proportional-track"


boxSizeCqw : Float
boxSizeCqw =
    12


boxHeightPx : Float
boxHeightPx =
    60


boxWidthPx : Float
boxWidthPx =
    60


speedUnitsPerSecond : Float
speedUnitsPerSecond =
    40


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Keyframe.init
                [ Translate.initX boxAnim 0
                ]
      , widthPct = 75
      , rowStates = Dict.empty
      }
    , Cmd.none
    )


animate : AnimGroupName -> Float -> Keyframe.AnimBuilder mode -> Keyframe.AnimBuilder mode
animate animGroupName endTarget =
    Keyframe.loopForever
        >> Keyframe.alternate
        >> Keyframe.cssUnitX Cqw
        >> Translate.for animGroupName
        >> Translate.clampX 0 endTarget
        >> Translate.toX endTarget
        >> Translate.easing Linear
        >> Translate.speed speedUnitsPerSecond
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimUpdate Keyframe.AnimMsg
    | Start
    | Stop
    | StartRow AnimGroupName
    | StopRow AnimGroupName
    | SetWidth String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimUpdate animMsg ->
            let
                ( newState, _ ) =
                    Keyframe.update animMsg model.animState
            in
            ( { model | animState = newState }, Cmd.none )

        Start ->
            foldGroups startRow model

        Stop ->
            foldGroups stopRow model

        StartRow group ->
            startRow group ( model, Cmd.none )

        StopRow group ->
            stopRow group ( model, Cmd.none )

        SetWidth raw ->
            case String.toFloat raw of
                Just pct ->
                    ( { model | widthPct = clampWidthPct pct }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


foldGroups : (AnimGroupName -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
foldGroups f model =
    let
        ( finalModel, cmds ) =
            List.foldl
                (\g ( m, acc ) ->
                    let
                        ( m2, c ) =
                            f g ( m, Cmd.none )
                    in
                    ( m2, c :: acc )
                )
                ( model, [] )
                allGroups
    in
    ( finalModel, Cmd.batch cmds )


startRow : AnimGroupName -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
startRow group ( model, prevCmd ) =
    let
        target =
            100 - boxSizeCqw
    in
    case rowState group model of
        Playing ->
            ( model, prevCmd )

        Paused ->
            let
                ( newState, cmd ) =
                    Keyframe.resume group GotAnimUpdate model.animState
            in
            ( setRowState group Playing { model | animState = newState }
            , Cmd.batch [ prevCmd, cmd ]
            )

        NotStarted ->
            ( setRowState group
                Playing
                { model
                    | animState =
                        Keyframe.animate model.animState (animate group target)
                }
            , prevCmd
            )


stopRow : AnimGroupName -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
stopRow group ( model, prevCmd ) =
    case rowState group model of
        Playing ->
            let
                ( newState, cmd ) =
                    Keyframe.pause group GotAnimUpdate model.animState
            in
            ( setRowState group Paused { model | animState = newState }
            , Cmd.batch [ prevCmd, cmd ]
            )

        _ ->
            ( model, prevCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    let
        ctrlBtn label cls msg =
            Html.button
                [ onClick msg
                , class ("ui-action-button " ++ cls)
                , style "background-color" "blue"
                , style "color" "white"
                ]
                [ text label ]
    in
    div
        [ class "example-stage"
        , style "justify-content" "flex-start"
        ]
        [ Keyframe.styleNodeFor boxAnim model.animState
        , div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Start" "success" Start
            , ctrlBtn "Stop" "warning" Stop
            ]
        , div
            [ class "example-controls"
            , style "margin-top" "8px"
            , style "display" "flex"
            , style "align-items" "center"
            , style "gap" "10px"
            ]
            [ div
                [ style "font-size" "12px"
                , style "font-weight" "600"
                ]
                [ text "Track Width" ]
            , input
                [ type_ "range"
                , Attributes.min "50"
                , Attributes.max "100"
                , Attributes.step "1"
                , value (String.fromFloat model.widthPct)
                , onInput SetWidth
                , style "width" "240px"
                ]
                []
            , div
                [ style "font-size" "12px"
                , style "min-width" "48px"
                ]
                [ text (String.fromInt (round model.widthPct) ++ "%") ]
            ]
        , div
            [ class "example-canvas"
            , style "align-self" "flex-start"
            , style "flex" "0 0 auto"
            , style "border" "1px solid #0c0c0d"
            , style "padding" "8px"
            , style "background-color" "#d6d9dd"
            ]
            [ div
                [ style "width" (String.fromFloat model.widthPct ++ "%")
                , style "align-self" "flex-start"
                ]
                [ trackRow "Proportional" trackId boxAnim proportionalColor model
                ]
            ]
        ]


trackRow : String -> String -> String -> String -> Model -> Html Msg
trackRow label rowId group color model =
    let
        state =
            rowState group model

        rowBtn btnLabel cls msg =
            Html.button
                [ onClick msg
                , class ("ui-action-button " ++ cls)
                , style "background-color" "blue"
                , style "color" "white"
                , style "padding" "2px 8px"
                , style "font-size" "12px"
                ]
                [ text btnLabel ]
    in
    div
        [ class "responsive-row" ]
        [ div [ class "responsive-row__label" ] [ text label ]
        , div
            ([ class "responsive-row__track"
             , style "background-color" "#f9de10"
             , style "border" "1px solid #0c0c0d"
             , style "border-radius" "9px"
             , style "container-type" "size"
             ]
                ++ (if String.isEmpty rowId then
                        []

                    else
                        [ id rowId ]
                   )
            )
            [ div
                (Keyframe.attributes group model.animState
                    ++ [ style "width" (String.fromFloat boxWidthPx ++ "px")
                       , style "height" (String.fromFloat boxHeightPx ++ "px")
                       , style "background-color" color
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
                       , style "border-radius" "1.2cqw"
                       ]
                )
                []
            ]
        , div
            [ style "display" "flex"
            , style "gap" "4px"
            , style "margin-left" "8px"
            ]
            [ rowBtn "Start" "success" (StartRow group)
            , rowBtn "Stop" "warning" (StopRow group)
            , div
                [ style "font-size" "11px"
                , style "align-self" "center"
                , style "color" "#555"
                , style "min-width" "60px"
                ]
                [ text (rowStateLabel state) ]
            ]
        ]


rowStateLabel : AnimPlayState -> String
rowStateLabel state =
    case state of
        NotStarted ->
            "idle"

        Playing ->
            "playing"

        Paused ->
            "paused"


proportionalColor : String
proportionalColor =
    "#28a745"
