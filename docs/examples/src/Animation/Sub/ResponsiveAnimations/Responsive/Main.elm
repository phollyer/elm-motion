module Animation.Sub.ResponsiveAnimations.Responsive.Main exposing (..)

import Anim.Engine.Sub as Sub exposing (AnimGroupName)
import Anim.Property.Translate as Translate
import Browser
import Browser.Dom as Dom
import Browser.Events
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing exposing (Easing(..))
import Process
import Task



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
    { animState : Sub.AnimState
    , widthPct : WidthPct
    , trackPx : Float
    , rowStates : Dict AnimGroupName AnimPlayState
    }


type AnimPlayState
    = NotStarted
    | Playing
    | Paused


type WidthPct
    = Narrow
    | Normal
    | Widen


widthPctToFloat : WidthPct -> Float
widthPctToFloat pct =
    case pct of
        Narrow ->
            50

        Normal ->
            75

        Widen ->
            100


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


boxSize : Float
boxSize =
    60


speedPxPerSec : Float
speedPxPerSec =
    200


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Sub.init
                [ Translate.initX boxAnim 0
                ]
      , widthPct = Normal
      , trackPx = 0
      , rowStates = Dict.empty
      }
    , Process.sleep 100
        |> Task.perform (\_ -> OnResize)
    )


animate : AnimGroupName -> Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
animate animGroupName endTarget =
    Sub.loopForever
        >> Sub.alternate
        >> Translate.for animGroupName
        >> Translate.clampX 0 endTarget
        >> Translate.toX endTarget
        >> Translate.easing Linear
        >> Translate.speed speedPxPerSec
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimUpdate Sub.AnimMsg
    | Start
    | Stop
    | StartRow AnimGroupName
    | StopRow AnimGroupName
    | SetWidth WidthPct
    | OnResize
    | GotTrack (Result Dom.Error Dom.Element)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimUpdate animMsg ->
            let
                ( newState, _ ) =
                    Sub.update animMsg model.animState
            in
            ( { model | animState = newState }, Cmd.none )

        Start ->
            ( List.foldl startRow model allGroups, Cmd.none )

        Stop ->
            ( List.foldl stopRow model allGroups, Cmd.none )

        StartRow group ->
            ( startRow group model, Cmd.none )

        StopRow group ->
            ( stopRow group model, Cmd.none )

        SetWidth pct ->
            ( { model | widthPct = pct }
              -- mimic Browser.onResize event by setting the new width and then dispatching the OnResize msg after a short delay.
            , Process.sleep 100
                |> Task.perform (\_ -> OnResize)
            )

        ---8<-- [start:on-resize-update]
        OnResize ->
            ( model
            , Task.attempt GotTrack <|
                Dom.getElement trackId
            )

        GotTrack (Ok element) ->
            ( handleResize { model | trackPx = element.element.width }
            , Cmd.none
            )

        GotTrack (Err _) ->
            ( model, Cmd.none )



---8<-- [end:on-resize-update]
---8<-- [start:policy-init]


startRow : AnimGroupName -> Model -> Model
startRow group model =
    let
        target =
            model.trackPx - boxSize
    in
    case rowState group model of
        Playing ->
            model

        Paused ->
            { model | animState = Sub.resume group model.animState }
                |> setRowState group Playing

        NotStarted ->
            { model
                | animState =
                    Sub.animate model.animState (animate group target)
            }
                |> setRowState group Playing


stopRow : AnimGroupName -> Model -> Model
stopRow group model =
    case rowState group model of
        Playing ->
            { model | animState = Sub.pause group model.animState }
                |> setRowState group Paused

        _ ->
            model



---8<-- [end:policy-init]


{-| The row demonstrates `Sub.onResize` with proportional remapping:
the box's progress along the track is preserved, so the rhythm of the
animation continues to feel natural even as the track changes width.
-}



---8<-- [start:on-resize-handler]


handleResize : Model -> Model
handleResize model =
    let
        bounds =
            { x = Just { min = 0, max = model.trackPx - boxSize }
            , y = Nothing
            , z = Nothing
            }

        applyBoundsFor group builder =
            if rowState group model == NotStarted then
                builder

            else
                Translate.bounds group bounds builder
    in
    { model
        | animState =
            Sub.onResize model.animState <|
                List.foldl (\g acc -> acc >> applyBoundsFor g) identity allGroups
    }



---8<-- [end:on-resize-handler]
-- SUBSCRIPTIONS
---8<-- [start:subscriptions]


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.subscriptions GotAnimUpdate model.animState
        , Browser.Events.onResize (\_ _ -> OnResize)
        ]



---8<-- [end:subscriptions]
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
        [ div
            [ class "example-badge example-badge--responsive" ]
            [ text "RESPONSIVE" ]
        , div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Start" "success" Start
            , ctrlBtn "Stop" "warning" Stop
            ]
        , div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Narrow" "" (SetWidth Narrow)
            , ctrlBtn "Normal" "" (SetWidth Normal)
            , ctrlBtn "Widen" "" (SetWidth Widen)
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
                [ style "width" (String.fromFloat (widthPctToFloat model.widthPct) ++ "%")
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
             ]
                ++ (if String.isEmpty rowId then
                        []

                    else
                        [ id rowId ]
                   )
            )
            [ div
                (Sub.attributes group model.animState
                    ++ [ style "width" (String.fromFloat boxSize ++ "px")
                       , style "height" (String.fromFloat boxSize ++ "px")
                       , style "background-color" color
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
                       , style "border-radius" "8px"
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
