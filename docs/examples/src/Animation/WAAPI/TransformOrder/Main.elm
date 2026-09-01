port module Animation.WAAPI.TransformOrder.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Skew as Skew
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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
    { animState : WAAPI.AnimState Msg
    , animatedBoxes : List Permutation
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                List.concatMap
                    (\perm ->
                        [ Translate.initXY (permutationKey perm) 0 0
                            >> Translate.initCssUnitX Cqw
                            >> Translate.initCssUnitY Cqh
                        , Skew.initXY (permutationKey perm) 0 0
                        ]
                    )
                    allPermutations
      , animatedBoxes = []
      }
    , Cmd.none
    )


boxSize : Float
boxSize =
    16


boxSizeCss : String
boxSizeCss =
    String.fromFloat boxSize ++ "cqmin"


type Permutation
    = TRSkS
    | TSkRS
    | RTSkS
    | SkTRS
    | STRSk
    | RSkTS


allPermutations : List Permutation
allPermutations =
    [ TRSkS, TSkRS, RTSkS, SkTRS, STRSk, RSkTS ]


permutationKey : Permutation -> String
permutationKey perm =
    case perm of
        TRSkS ->
            "t-r-sk-s"

        TSkRS ->
            "t-sk-r-s"

        RTSkS ->
            "r-t-sk-s"

        SkTRS ->
            "sk-t-r-s"

        STRSk ->
            "s-t-r-sk"

        RSkTS ->
            "r-sk-t-s"


permutationLabel : Permutation -> String
permutationLabel perm =
    case perm of
        TRSkS ->
            "T → R → Sk → S"

        TSkRS ->
            "T → Sk → R → S"

        RTSkS ->
            "R → T → Sk → S"

        SkTRS ->
            "Sk → T → R → S"

        STRSk ->
            "S → T → R → Sk"

        RSkTS ->
            "R → Sk → T → S"


permutationOrder : Permutation -> List TransformProperty
permutationOrder perm =
    case perm of
        TRSkS ->
            [ Translate, Rotate, Skew, Scale ]

        TSkRS ->
            [ Translate, Skew, Rotate, Scale ]

        RTSkS ->
            [ Rotate, Translate, Skew, Scale ]

        SkTRS ->
            [ Skew, Translate, Rotate, Scale ]

        STRSk ->
            [ Scale, Translate, Rotate, Skew ]

        RSkTS ->
            [ Rotate, Skew, Translate, Scale ]


permutationColor : Permutation -> String
permutationColor perm =
    case perm of
        TRSkS ->
            "59, 130, 246"

        TSkRS ->
            "16, 185, 129"

        RTSkS ->
            "245, 158, 11"

        SkTRS ->
            "239, 68, 68"

        STRSk ->
            "139, 92, 246"

        RSkTS ->
            "236, 72, 153"



-- ANIMATION


moveOut : AnimBuilder eng -> AnimBuilder eng
moveOut =
    Translate.begin
        >> Translate.toXY 24 10
        >> Translate.end
        >> Rotate.begin
        >> Rotate.toZ 45
        >> Rotate.end
        >> Skew.begin
        >> Skew.toXY 15 9
        >> Skew.end
        >> Scale.begin
        >> Scale.toXY 1.5 0.8
        >> Scale.end


reset : AnimBuilder eng -> AnimBuilder eng
reset =
    Translate.begin
        >> Translate.toXY 0 0
        >> Translate.end
        >> Rotate.begin
        >> Rotate.toZ 0
        >> Rotate.end
        >> Skew.begin
        >> Skew.toXY 0 0
        >> Skew.end
        >> Scale.begin
        >> Scale.toXY 1 1
        >> Scale.end


engineDefaults : Permutation -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
engineDefaults perm =
    WAAPI.for (permutationKey perm)
        >> WAAPI.transformOrder (permutationOrder perm)
        >> WAAPI.duration 2000
        >> WAAPI.easing EaseInOut
        >> WAAPI.cssUnitX Cqw
        >> WAAPI.cssUnitY Cqh



-- UPDATE


type Msg
    = Animate Permutation
    | Reset Permutation
    | AnimateAll
    | ResetAll
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate perm ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState <|
                        engineDefaults perm
                            >> moveOut
            in
            ( { model
                | animState = newAnimState
                , animatedBoxes =
                    if List.member perm model.animatedBoxes then
                        model.animatedBoxes

                    else
                        perm :: model.animatedBoxes
              }
            , animCmd
            )

        Reset perm ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState <|
                        engineDefaults perm
                            >> reset
            in
            ( { model
                | animState = newAnimState
                , animatedBoxes =
                    List.filter ((/=) perm) model.animatedBoxes
              }
            , animCmd
            )

        AnimateAll ->
            let
                ( finalState, cmd ) =
                    WAAPI.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                engineDefaults perm
                                    >> moveOut
                                    >> acc
                            )
                            identity
                            allPermutations
            in
            ( { model | animState = finalState, animatedBoxes = allPermutations }
            , cmd
            )

        ResetAll ->
            let
                ( finalState, cmd ) =
                    WAAPI.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                engineDefaults perm
                                    >> reset
                                    >> acc
                            )
                            identity
                            model.animatedBoxes
            in
            ( { model | animState = finalState, animatedBoxes = [] }
            , cmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "container-type" "size"
        ]
        [ div [ class "example-controls" ]
            (List.map permButton allPermutations)
        , div [ class "example-controls" ]
            [ actionButton "▶️ All" AnimateAll "#16a34a"
            , actionButton "⏮️ Reset All" ResetAll "#d97706"
            ]
        , animationArea model.animState
        ]


permButton : Permutation -> Html Msg
permButton perm =
    button
        [ onClick (Animate perm)
        , style "padding" "6px 14px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" ("rgb(" ++ permutationColor perm ++ ")")
        , style "color" "white"
        , style "font-size" "13px"
        , style "font-weight" "600"
        , style "cursor" "pointer"
        ]
        [ text (permutationLabel perm) ]


actionButton : String -> Msg -> String -> Html Msg
actionButton label msg color =
    button
        [ onClick msg
        , style "padding" "6px 14px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" color
        , style "color" "white"
        , style "font-size" "13px"
        , style "font-weight" "600"
        , style "cursor" "pointer"
        ]
        [ text label ]


animationArea : WAAPI.AnimState Msg -> Html Msg
animationArea animState =
    div
        [ class "example-canvas"
        , style "position" "relative"
        , style "background-color" "#ffffff"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        , style "overflow" "hidden"
        ]
        (List.map (animatedBox animState) allPermutations)


animatedBox : WAAPI.AnimState Msg -> Permutation -> Html Msg
animatedBox animState perm =
    let
        rgb =
            permutationColor perm
    in
    div
        [ style "position" "absolute"
        , style "top" "clamp(10px, 2vmin, 16px)"
        , style "left" "50%"
        , style "transform" "translateX(-50%)"
        ]
        [ div
            (WAAPI.attributes (permutationKey perm) animState
                ++ [ style "width" boxSizeCss
                   , style "height" boxSizeCss
                   , style "background-color" ("rgba(" ++ rgb ++ ", 0.25)")
                   , style "border-radius" "1.6cqmin"
                   , style "border" ("0.4cqmin solid rgb(" ++ rgb ++ ")")
                   , style "font-size" "2.2cqmin"
                   , style "font-weight" "bold"
                   , style "color" ("rgb(" ++ rgb ++ ")")
                   , style "padding" "0.8cqmin"
                   , style "box-sizing" "border-box"
                   ]
            )
            [ text (permutationLabel perm) ]
        ]
