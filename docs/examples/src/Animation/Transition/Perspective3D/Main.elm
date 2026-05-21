module Animation.Transition.Perspective3D.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Extra.View3D as View3D
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- MAIN


main : Program { window : { width : Int, height : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL
-- Perspective container configuration


type alias PerspectiveContainerConfig =
    { id : String
    , groupName : String
    }


perspectiveContainer : PerspectiveContainerConfig
perspectiveContainer =
    { id = "perspective-container"
    , groupName = "perspectiveContainerAnim"
    }


vanishingPointDot : { id : String, groupName : String }
vanishingPointDot =
    { id = "vanishing-point-dot"
    , groupName = "vanishingPointDotAnim"
    }



-- Cube configuration


cubeGroupName : String
cubeGroupName =
    "cubeAnim"


type alias CubeConfig =
    { id : String
    , groupName : String
    , size : Int
    }



-- Face configuration


type alias TextConfig =
    { id : String
    , groupName : String
    , label : String
    , color : String
    }


type alias FaceConfig =
    { id : String
    , groupName : String
    , label : String
    , background : String
    , borderColor : String
    , text : TextConfig
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , groupName = "frontFaceAnim"
    , label = "FRONT"
    , background = "rgb(52, 152, 219)"
    , borderColor = "rgb(41, 128, 185)"
    , text =
        { id = "front-face-text"
        , groupName = "frontFaceTextAnim"
        , label = "FRONT"
        , color = "rgb(0,0 ,0   )"
        }
    }


backFace : FaceConfig
backFace =
    { id = "back-face"
    , groupName = "backFaceAnim"
    , label = "BACK"
    , background = "rgb(41, 128, 185)"
    , borderColor = "rgb(33, 97, 140)"
    , text =
        { id = "back-face-text"
        , groupName = "backFaceTextAnim"
        , label = "BACK"
        , color = "rgb(0,0 ,0   )"
        }
    }


rightFace : FaceConfig
rightFace =
    { id = "right-face"
    , groupName = "rightFaceAnim"
    , label = "RIGHT"
    , background = "rgb(231, 76, 60)"
    , borderColor = "rgb(192, 57, 43)"
    , text =
        { id = "right-face-text"
        , groupName = "rightFaceTextAnim"
        , label = "RIGHT"
        , color = "rgb(0,0 ,0   )"
        }
    }


leftFace : FaceConfig
leftFace =
    { id = "left-face"
    , groupName = "leftFaceAnim"
    , label = "LEFT"
    , background = "rgb(230, 126, 34)"
    , borderColor = "rgb(211, 84, 0)"
    , text =
        { id = "left-face-text"
        , groupName = "leftFaceTextAnim"
        , label = "LEFT"
        , color = "rgb(0,0 ,0   )"
        }
    }


topFace : FaceConfig
topFace =
    { id = "top-face"
    , groupName = "topFaceAnim"
    , label = "TOP"
    , background = "rgb(46, 204, 113)"
    , borderColor = "rgb(39, 174, 96)"
    , text =
        { id = "top-face-text"
        , groupName = "topFaceTextAnim"
        , label = "TOP"
        , color = "rgb(0,0 ,0   )"
        }
    }


bottomFace : FaceConfig
bottomFace =
    { id = "bottom-face"
    , groupName = "bottomFaceAnim"
    , label = "BOTTOM"
    , background = "rgb(155, 89, 182)"
    , borderColor = "rgb(142, 68, 173)"
    , text =
        { id = "bottom-face-text"
        , groupName = "bottomFaceTextAnim"
        , label = "BOTTOM"
        , color = "rgb(0,0 ,0   )"
        }
    }


type PerspectiveStep
    = MoveToTopRight
    | MoveToBottomRight
    | MoveToBottomLeft
    | MoveToTopLeft


type alias Model =
    { animState : Transition.AnimState
    , perspectiveStep : PerspectiveStep
    , initialAnimAreaSize : { width : Float, height : Float }
    , currentAnimAreaSize : { width : Float, height : Float }
    , cube : CubeConfig
    }


{-| Square animation area sized off the smaller viewport axis so it
always fits the page in either orientation. Mirrors the responsive
strategy used by `Animation.WAAPI.Animate3D.Main`.
-}
animAreaSize : Float -> Float -> { width : Float, height : Float }
animAreaSize windowWidth windowHeight =
    if windowWidth < windowHeight then
        { width = windowWidth, height = windowWidth }

    else
        { width = windowHeight, height = windowHeight }


{-| Width of the perspective container's border (must match the inline
`border` style applied to `viewAnimationArea`). The dot is absolutely
positioned relative to the padding box, so animating its anchor all the
way to `element.width` / `element.height` would place it `2 * borderWidth`
past the inner edge of the border. Subtracting `2 * borderWidth` from the
measured area keeps the dot tracing the visible border on all four sides.
-}
containerBorderWidth : Float
containerBorderWidth =
    1


toInnerArea : { width : Float, height : Float } -> { width : Float, height : Float }
toInnerArea { width, height } =
    { width = max 0 (width - 2 * containerBorderWidth)
    , height = max 0 (height - 2 * containerBorderWidth)
    }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        initialAreaSize =
            animAreaSize
                (toFloat flags.window.width)
                (toFloat flags.window.height)

        cubeSize =
            min (toFloat flags.window.width) (toFloat flags.window.height) * 0.8 / 4

        depth =
            cubeSize / 2

        initialAnimState =
            Transition.init
                [ -- Initialize the perspective origin at the top-left corner (0%, 0%)
                  -- It will travel around the corners in sync with the cube animation:
                  -- (0,0) -> (100,0) -> (100,100) -> (0,100) -> (0,0)
                  PerspectiveOrigin.initPercent perspectiveContainer.groupName 0 0

                -- Bring the cube forward on the Z axis
                -- so that it doesn't get clipped by the
                -- z=0 clipping plane when we expand the
                -- sides and rotate
                , Translate.initZ cubeGroupName 300
                    -- Static no-op scale so subsequent `Scale.to*` calls
                    -- on resize have a baseline to transition from.
                    >> Scale.init cubeGroupName 1

                -- Position each face in 3D space along the axis it faces
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initZ frontFace.groupName depth
                , Translate.initZ backFace.groupName (depth * -1)
                , Translate.initX rightFace.groupName depth
                , Translate.initX leftFace.groupName (-1 * depth)
                , Translate.initY topFace.groupName (-1 * depth)
                , Translate.initY bottomFace.groupName depth

                -- Rotate each face into position to build the cube
                -- Front face is not rotated due to facing forward by default
                , Rotate.initY backFace.groupName 180
                , Rotate.initY rightFace.groupName 90
                , Rotate.initY leftFace.groupName -90
                , Rotate.initX topFace.groupName 90
                , Rotate.initX bottomFace.groupName -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting position for elements, so we don't need
                -- to initialize them
                ]
    in
    ( { animState = initialAnimState
      , perspectiveStep = MoveToTopRight
      , initialAnimAreaSize = initialAreaSize
      , currentAnimAreaSize = initialAreaSize
      , cube =
            { id = "cube"
            , groupName = cubeGroupName
            , size = round cubeSize
            }
      }
    , Process.sleep 100
        |> Task.andThen (\_ -> Dom.getElement perspectiveContainer.id)
        |> Task.attempt InitStageElement
    )


perspectiveStepDuration : Int
perspectiveStepDuration =
    3000


nextPerspectiveStep : PerspectiveStep -> PerspectiveStep
nextPerspectiveStep step =
    case step of
        MoveToTopRight ->
            MoveToBottomRight

        MoveToBottomRight ->
            MoveToBottomLeft

        MoveToBottomLeft ->
            MoveToTopLeft

        MoveToTopLeft ->
            MoveToTopRight


perspectiveAnimation : { width : Float, height : Float } -> PerspectiveStep -> AnimBuilder mode -> AnimBuilder mode
perspectiveAnimation areaSize step =
    case step of
        MoveToTopRight ->
            movePerspectiveOrigin 100 0 perspectiveStepDuration areaSize

        MoveToBottomRight ->
            movePerspectiveOrigin 100 100 perspectiveStepDuration areaSize

        MoveToBottomLeft ->
            movePerspectiveOrigin 0 100 perspectiveStepDuration areaSize

        MoveToTopLeft ->
            movePerspectiveOrigin 0 0 perspectiveStepDuration areaSize



-- ANIMATIONS
--
-- PERSPECTIVE ORIGIN - animates the vanishing point around the corners of the
-- container in sync with the cube animation


movePerspectiveOrigin : Float -> Float -> Int -> { width : Float, height : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveOrigin x y ms areaSize =
    PerspectiveOrigin.for perspectiveContainer.groupName
        >> PerspectiveOrigin.cssUnit Percent
        >> PerspectiveOrigin.toXY x y
        >> PerspectiveOrigin.duration ms
        >> PerspectiveOrigin.easing Linear
        >> PerspectiveOrigin.build
        >> Translate.for vanishingPointDot.groupName
        >> Translate.toX (x / 100 * areaSize.width)
        >> Translate.toY (y / 100 * areaSize.height)
        >> Translate.duration ms
        >> Translate.easing Linear
        >> Translate.build


{-| Scale a group uniformly on x/y/z to the given ratio.
Used on resize to make the cube and dot grow/shrink with the
container, mirroring the responsive strategy of `WAAPI.Animate3D`.
-}
scaleGroupTo : String -> Float -> AnimBuilder mode -> AnimBuilder mode
scaleGroupTo groupName ratio =
    Scale.for groupName
        >> Scale.toX ratio
        >> Scale.toY ratio
        >> Scale.toZ ratio
        >> Scale.duration 200
        >> Scale.easing Linear
        >> Scale.build



-- UPDATE


type Msg
    = NoOp
    | TriggerAnimation
    | GotTransitionsMsg Transition.AnimMsg
    | InitStageElement (Result Dom.Error Dom.Element)
    | GotStageElement (Result Dom.Error Dom.Element)
    | OnWindowResize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        perspectiveAnimation model.currentAnimAreaSize model.perspectiveStep
                , perspectiveStep =
                    nextPerspectiveStep model.perspectiveStep
              }
            , Cmd.none
            )

        GotTransitionsMsg animMsg ->
            let
                ( animState, animEvent ) =
                    Transition.update animMsg model.animState
            in
            ( handleEvent animEvent { model | animState = animState }
            , Cmd.none
            )

        InitStageElement (Ok { element }) ->
            let
                measured =
                    toInnerArea
                        { width = element.width, height = element.height }
            in
            ( { model
                | initialAnimAreaSize = measured
                , currentAnimAreaSize = measured
              }
            , Process.sleep 0
                |> Task.perform (always TriggerAnimation)
            )

        InitStageElement (Err _) ->
            ( model, Cmd.none )

        GotStageElement (Ok { element }) ->
            -- Transition engine cannot remap in-flight CSS transitions on
            -- resize, but we can fire a fresh `Transition.animate` that
            -- scales the cube and dot to the new container ratio. CSS
            -- transitions smoothly interpolate to the new scale.
            let
                newAreaSize =
                    toInnerArea
                        { width = element.width, height = element.height }

                scale =
                    newAreaSize.width
                        / model.initialAnimAreaSize.width
            in
            ( { model
                | currentAnimAreaSize = newAreaSize
                , animState =
                    Transition.animate model.animState <|
                        scaleGroupTo cubeGroupName scale
                            >> scaleGroupTo vanishingPointDot.groupName scale
              }
            , Cmd.none
            )

        GotStageElement (Err _) ->
            ( model, Cmd.none )

        OnWindowResize _ _ ->
            ( model
            , Task.attempt GotStageElement <|
                Dom.getElement perspectiveContainer.id
            )


handleEvent : Transition.AnimEvent -> Model -> Model
handleEvent animEvent model =
    case animEvent of
        Transition.Ended _ _ "vanishingPointDotAnim" ->
            perspectiveStepEnded model

        _ ->
            model


perspectiveStepEnded : Model -> Model
perspectiveStepEnded model =
    { model
        | animState =
            Transition.animate model.animState <|
                perspectiveAnimation model.currentAnimAreaSize model.perspectiveStep
        , perspectiveStep =
            nextPerspectiveStep model.perspectiveStep
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize OnWindowResize



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Transition Engine - 3D Perspective Origin Example"
    , body =
        [ div [ class "example-stage" ]
            [ div [ class "example-badge example-badge--static" ] [ text "Static" ]
            , viewAnimationArea model
            ]
        ]
    }


viewAnimationArea : Model -> Html Msg
viewAnimationArea model =
    div
        (Transition.attributes perspectiveContainer.groupName model.animState
            ++ Transition.events GotTransitionsMsg
            ++ [ id perspectiveContainer.id

               -- Perspective container - perspective-origin is animated by the engine
               , View3D.perspective 1200

               --
               -- Workaround for Chrome on macOS GPU compositing issues with 3D transforms.
               -- Setting opacity: 0.99 forces a new compositing layer, which prevents
               -- the colored rectangle artifacts that can appear during complex 3D animations.
               -- It's not perfect, some flickering can still occur.
               , View3D.opacityHack
               , style "position" "relative"
               , style "display" "flex"
               , style "justify-content" "center"
               , style "align-items" "center"
               , style "flex" "1 1 auto"
               , style "width" "100%"
               , style "min-height" "0"
               , style "aspect-ratio" "1 / 1"
               , style "background-color" "#ececf688"
               , style "border" "1px solid #4f4f7f18"
               ]
        )
        [ viewVanishingPoint model.animState
        , div
            [ View3D.transformStyle View3D.Preserve3D
            , style "position" "absolute"
            , style "left" "50%"
            , style "top" "50%"
            , style "transform" "translate(-50%, -50%)"
            ]
            [ viewCube model ]
        ]


viewVanishingPoint : Transition.AnimState -> Html Msg
viewVanishingPoint animState =
    div
        (Transition.attributes vanishingPointDot.groupName animState
            ++ [ style "position" "absolute"
               , style "top" "0"
               , style "left" "0"
               , style "width" "0"
               , style "height" "0"
               , style "overflow" "visible"
               , style "pointer-events" "none"
               ]
        )
        [ div
            [ style "position" "absolute"
            , style "width" "1px"
            , style "height" "40px"
            , style "top" "-20px"
            , style "left" "-0.5px"
            , style "background" "rgba(80, 80, 80, 0.4)"
            ]
            []
        , div
            [ style "position" "absolute"
            , style "height" "1px"
            , style "width" "40px"
            , style "left" "-20px"
            , style "top" "-0.5px"
            , style "background" "rgba(80, 80, 80, 0.4)"
            ]
            []
        , div
            [ style "position" "absolute"
            , style "width" "10px"
            , style "height" "10px"
            , style "border-radius" "50%"
            , style "background" "rgba(40, 40, 40, 0.8)"
            , style "border" "2px solid rgba(255, 255, 255, 0.9)"
            , style "box-shadow" "0 0 6px rgba(0, 0, 0, 0.4)"
            , style "transform" "translate(-50%, -50%)"
            ]
            []
        ]


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            Transition.attributes cubeGroupName model.animState

        cubeEvents =
            Transition.events GotTransitionsMsg

        cubeSize =
            toFloat model.cube.size
    in
    div
        (cubeAttrs
            ++ cubeEvents
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id model.cube.id
               , style "width" (String.fromFloat cubeSize ++ "px")
               , style "height" (String.fromFloat cubeSize ++ "px")
               , style "position" "relative"
               ]
        )
        [ viewFace cubeSize model.animState frontFace
        , viewFace cubeSize model.animState backFace
        , viewFace cubeSize model.animState rightFace
        , viewFace cubeSize model.animState leftFace
        , viewFace cubeSize model.animState topFace
        , viewFace cubeSize model.animState bottomFace
        ]


viewFace : Float -> Transition.AnimState -> FaceConfig -> Html Msg
viewFace cubeSize animState config =
    let
        faceAnimAttributes =
            Transition.attributes config.groupName animState

        textAnimAttributes =
            Transition.attributes config.text.groupName animState
    in
    div
        (faceAnimAttributes
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id config.id
               , style "position" "absolute"
               , style "width" (String.fromFloat cubeSize ++ "px")
               , style "height" (String.fromFloat cubeSize ++ "px")
               , style "background-color" config.background
               , style "border" ("2px solid " ++ config.borderColor)
               , style "box-sizing" "border-box"
               , style "display" "flex"
               , style "justify-content" "center"
               , style "align-items" "center"
               , style "font-weight" "bold"
               , style "font-size" "14px"
               ]
        )
        [ div
            [ style "color" "#ffffff"
            , style "position" "absolute"
            ]
            [ text config.label ]
        , div
            (textAnimAttributes
                ++ [ id config.text.id
                   , style "color" config.text.color
                   , style "position" "absolute"
                   ]
            )
            [ text config.text.label ]
        ]
