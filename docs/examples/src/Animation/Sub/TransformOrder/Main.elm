module Animation.Sub.TransformOrder.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
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
import Motion.Easing as Easing exposing (Easing(..))



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
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init <|
                List.concatMap
                    (\perm ->
                        [ Translate.initUnitX Cqw
                            >> Translate.initUnitY Cqh
                            >> Translate.initXY (permutationKey perm) 0 0
                        , Skew.initXY (permutationKey perm) 0 0
                        ]
                    )
                    allPermutations
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


moveOut : Permutation -> AnimBuilder eng -> AnimBuilder eng
moveOut perm =
    let
        key =
            permutationKey perm
    in
    Translate.for key
        >> Translate.toXY 24 10
        >> Translate.build
        >> Rotate.for key
        >> Rotate.toZ 45
        >> Rotate.build
        >> Skew.for key
        >> Skew.toXY 15 9
        >> Skew.build
        >> Scale.for key
        >> Scale.toXY 1.5 0.8
        >> Scale.build


reset : Permutation -> AnimBuilder eng -> AnimBuilder eng
reset perm =
    let
        key =
            permutationKey perm
    in
    Translate.for key
        >> Translate.toXY 0 0
        >> Translate.build
        >> Rotate.for key
        >> Rotate.toZ 0
        >> Rotate.build
        >> Skew.for key
        >> Skew.toXY 0 0
        >> Skew.build
        >> Scale.for key
        >> Scale.toXY 1 1
        >> Scale.build


engineDefaults : Permutation -> Sub.EngineBuilder -> Sub.EngineBuilder
engineDefaults perm =
    Sub.transformOrder (permutationOrder perm)
        >> Sub.duration 2000
        >> Sub.easing EaseInOut
        >> Sub.cssUnitX Cqw
        >> Sub.cssUnitY Cqh



-- UPDATE


type Msg
    = Animate Permutation
    | Reset Permutation
    | AnimateAll
    | ResetAll
    | GotSubMsg Sub.AnimMsg


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

        Animate perm ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        engineDefaults perm
                            >> moveOut perm
              }
            , Cmd.none
            )

        Reset perm ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        engineDefaults perm
                            >> reset perm
              }
            , Cmd.none
            )

        AnimateAll ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                engineDefaults perm
                                    >> moveOut perm
                                    >> acc
                            )
                            identity
                            allPermutations
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        List.foldl
                            (\perm acc ->
                                engineDefaults perm
                                    >> reset perm
                                    >> acc
                            )
                            identity
                            allPermutations
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



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


animationArea : Sub.AnimState -> Html Msg
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


animatedBox : Sub.AnimState -> Permutation -> Html Msg
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
            (Sub.attributes (permutationKey perm) animState
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
