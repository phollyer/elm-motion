module Animation.Keyframe.HelloText.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)



-- MAIN


main : Program () Model msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- MODEL
---8<-- [start:model]


type alias Model =
    { animState : Keyframe.AnimState }



---8<-- [start:trigger]


init : ( Model, Cmd msg )
init =
    let
        animState =
            Keyframe.init
                [ Opacity.init textLineOne 0
                , Opacity.init dotOne 0
                , Opacity.init dotTwo 0
                , Opacity.init dotThree 0
                , Opacity.init textLineTwo 0
                ]
    in
    ( { animState =
            Keyframe.animate animState <|
                Keyframe.for textLineOne
                    >> fadeIn
                    >> Keyframe.for dotOne
                    >> Keyframe.delay duration
                    >> fadeIn
                    >> Keyframe.for dotTwo
                    >> Keyframe.delay (duration * 2)
                    >> fadeIn
                    >> Keyframe.for dotThree
                    >> Keyframe.delay (duration * 3)
                    >> fadeIn
                    >> Keyframe.for textLineTwo
                    >> Keyframe.delay (duration * 4)
                    >> fadeIn
      }
    , Cmd.none
    )



---8<-- [end:trigger]
---8<-- [end:model]
-- ANIMATION
---8<-- [start:build]
-- Avoid typos from hardcoding strings in multiple places


duration : Int
duration =
    500


textLineOne : String
textLineOne =
    "textLineOne"


dotOne : String
dotOne =
    "dotOne"


dotTwo : String
dotTwo =
    "dotTwo"


dotThree : String
dotThree =
    "dotThree"


textLineTwo : String
textLineTwo =
    "textLineTwo"


fadeIn : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
fadeIn =
    Opacity.begin
        >> Opacity.to 1
        >> Opacity.duration duration
        >> Opacity.end



---8<-- [end:build]
-- VIEW


view : Model -> Html msg
view model =
    div
        [ class "example-stage"
        , style "font-size" "clamp(28px, 10vw, 48px)"
        , style "font-weight" "bold"
        , style "text-align" "center"
        ]
        ---8<-- [start:render]
        [ Keyframe.styleNode model.animState
        , div
            [ style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "gap" "0.25em"
            ]
            [ div
                (Keyframe.attributes textLineOne model.animState ++ [])
                [ text "Elm Motion says" ]
            , div
                (Keyframe.attributes dotOne model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (Keyframe.attributes dotTwo model.animState
                    ++ []
                )
                [ text "." ]
            , div
                (Keyframe.attributes dotThree model.animState
                    ++ []
                )
                [ text "." ]
            ]
        , div
            (Keyframe.attributes textLineTwo model.animState
                ++ [ style "width" "100%" ]
            )
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
