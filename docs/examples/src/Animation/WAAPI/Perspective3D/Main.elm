port module Animation.WAAPI.Perspective3D.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
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
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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


type alias Model =
    { animState : WAAPI.AnimState Msg
    , perspectiveStep : PerspectiveStep
    , currentAnimAreaSize : { width : Float, height : Float }
    , cube : CubeConfig
    }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        initialAreaSize =
            { width = toFloat flags.window.width * 0.8, height = toFloat flags.window.height * 0.8 }

        cubeSize =
            min initialAreaSize.width initialAreaSize.height / 4

        depth =
            cubeSize / 2

        initialAnimState =
            WAAPI.init motionCmd motionMsg <|
                [ -- Initialize the perspective origin at the top-left corner (0%, 0%)
                  -- It will travel around the corners in sync with the dot animation:
                  -- (0,0) -> (100,0) -> (100,100) -> (0,100) -> (0,0)
                  PerspectiveOrigin.initUnit Px
                    >> PerspectiveOrigin.initXY perspectiveContainer.groupName 0 0
                , Translate.initXY vanishingPointDot.groupName 0 0

                -- Bring the cube forward on the Z axis
                -- so that it doesn't get clipped by the
                -- z=0 clipping plane.
                , Translate.initZ cubeGroupName 300
                    >> Scale.init cubeGroupName 1
                    -- Seed the dot at the top-left corner (0, 0) so that
                    -- `Translate.bounds` has runtime state to remap
                    -- when the container resizes.
                    >> Translate.initXY vanishingPointDot.groupName 0 0

                -- Position each face in 3D space along the axis it faces
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initZ frontFace.groupName depth
                , Translate.initZ backFace.groupName (depth * -1)
                    -- Rotate each face into position to build the cube
                    -- Front face is not rotated due to facing forward by default
                    >> Rotate.initY backFace.groupName 180
                , Translate.initX rightFace.groupName depth
                    >> Rotate.initY rightFace.groupName 90
                , Translate.initX leftFace.groupName (-1 * depth)
                    >> Rotate.initY leftFace.groupName -90
                , Translate.initY topFace.groupName (-1 * depth)
                    >> Rotate.initX topFace.groupName 90
                , Translate.initY bottomFace.groupName depth
                    >> Rotate.initX bottomFace.groupName -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting position for elements, so we don't need
                -- to initialize them
                ]
    in
    ( { animState = initialAnimState
      , perspectiveStep = MoveToTopRight
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


type PerspectiveStep
    = MoveToTopRight
    | MoveToBottomRight
    | MoveToBottomLeft
    | MoveToTopLeft



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
        , label = "BOTTOM"
        , color = "rgb(0,0 ,0   )"
        }
    }


perspectiveStepSpeed : Float
perspectiveStepSpeed =
    150


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


{-| Which axis is moving for the leg currently in flight. Mirrors the
helper of the same name in the `Sub` Perspective3D example - the
in-flight leg drives both `Translate.bounds` (moving axis only) and
`Translate.position` (static axis snap).
-}
type LegAxis
    = XAxisLeg
    | YAxisLeg


inFlightPerspectiveStep : PerspectiveStep -> LegAxis
inFlightPerspectiveStep step =
    case step of
        -- in-flight = MoveToTopRight: (0,0) -> (W,0)
        MoveToTopRight ->
            XAxisLeg

        -- in-flight = MoveToBottomRight: (W,0) -> (W,H)
        MoveToBottomRight ->
            YAxisLeg

        -- in-flight = MoveToBottomLeft: (W,H) -> (0,H)
        MoveToBottomLeft ->
            XAxisLeg

        -- in-flight = MoveToTopLeft: (0,H) -> (0,0)
        MoveToTopLeft ->
            YAxisLeg


{-| Snap-target for the static axis of the in-flight leg.

The dot's track is the perimeter of the inner area, so for each leg one
axis animates and the other sits pinned to an edge. `Translate.bounds`
remaps the moving axis; this helper provides the matching pixel target
for the static axis, fed to `Translate.position` so the engine can
relocate `start = end = current` together (a current-only nudge would
be overwritten by the next interpolation frame).

-}
staticAxisSnap : PerspectiveStep -> { width : Float, height : Float } -> { x : Maybe Float, y : Maybe Float, z : Maybe Float }
staticAxisSnap step area =
    case step of
        -- in-flight = MoveToTopRight (X-leg): y pinned to 0
        MoveToTopRight ->
            { x = Nothing, y = Just 0, z = Nothing }

        -- in-flight = MoveToBottomRight (Y-leg): x pinned to W
        MoveToBottomRight ->
            { x = Just area.width, y = Nothing, z = Nothing }

        -- in-flight = MoveToBottomLeft (X-leg): y pinned to H
        MoveToBottomLeft ->
            { x = Nothing, y = Just area.height, z = Nothing }

        -- in-flight = MoveToTopLeft (Y-leg): x pinned to 0
        MoveToTopLeft ->
            { x = Just 0, y = Nothing, z = Nothing }


perspectiveAnimation : { width : Float, height : Float } -> PerspectiveStep -> AnimBuilder mode -> AnimBuilder mode
perspectiveAnimation areaSize step =
    case step of
        MoveToTopRight ->
            movePerspectiveRight perspectiveStepSpeed areaSize
                >> movePerspectiveTargetRight perspectiveStepSpeed areaSize

        MoveToBottomRight ->
            movePerspectiveDown perspectiveStepSpeed areaSize
                >> movePerspectiveTargetDown perspectiveStepSpeed areaSize

        MoveToBottomLeft ->
            movePerspectiveLeft perspectiveStepSpeed areaSize
                >> movePerspectiveTargetLeft perspectiveStepSpeed areaSize

        MoveToTopLeft ->
            movePerspectiveUp perspectiveStepSpeed areaSize
                >> movePerspectiveTargetUp perspectiveStepSpeed areaSize



-- ANIMATIONS
--
-- PERSPECTIVE ORIGIN - animates the vanishing point around the corners of the
-- container in sync with the cube animation


movePerspectiveOrigin : Float -> (PerspectiveOrigin.Builder mode -> PerspectiveOrigin.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveOrigin speed moveTo =
    PerspectiveOrigin.for perspectiveContainer.groupName
        >> PerspectiveOrigin.cssUnit Px
        >> moveTo
        >> PerspectiveOrigin.speed speed
        >> PerspectiveOrigin.easing Linear
        >> PerspectiveOrigin.build


movePerspectiveRight : Float -> { a | width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveRight speed { width } =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toX width
            >> PerspectiveOrigin.clampY 0 0
            >> PerspectiveOrigin.clampX 0 width


movePerspectiveLeft : Float -> { a | height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveLeft speed { height, width } =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toX 0
            >> PerspectiveOrigin.clampY height height
            >> PerspectiveOrigin.clampX 0 width


movePerspectiveDown : Float -> { a | height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveDown speed { height, width } =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toY height
            >> PerspectiveOrigin.clampX width width
            >> PerspectiveOrigin.clampY 0 height


movePerspectiveUp : Float -> { a | height : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveUp speed { height } =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toY 0
            >> PerspectiveOrigin.clampX 0 0
            >> PerspectiveOrigin.clampY 0 height


movePerspectiveTarget : Float -> (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTarget speed moveTo =
    Translate.for vanishingPointDot.groupName
        >> moveTo
        >> Translate.speed speed
        >> Translate.easing Linear
        >> Translate.build


movePerspectiveTargetRight : Float -> { a | width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetRight speed { width } =
    movePerspectiveTarget speed <|
        Translate.toX width
            >> Translate.clampY 0 0
            >> Translate.clampX 0 width


movePerspectiveTargetLeft : Float -> { a | height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetLeft speed { height, width } =
    movePerspectiveTarget speed <|
        Translate.toX 0
            >> Translate.clampY height height
            >> Translate.clampX 0 width


movePerspectiveTargetDown : Float -> { a | height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetDown speed { height, width } =
    movePerspectiveTarget speed <|
        Translate.toY height
            >> Translate.clampX width width
            >> Translate.clampY 0 height


movePerspectiveTargetUp : Float -> { a | height : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetUp speed { height } =
    movePerspectiveTarget speed <|
        Translate.toY 0
            >> Translate.clampX 0 0
            >> Translate.clampY 0 height


resizeEpsilon : Float
resizeEpsilon =
    0.01


isSameArea : { width : Float, height : Float } -> { width : Float, height : Float } -> Bool
isSameArea a b =
    abs (a.width - b.width)
        < resizeEpsilon
        && abs (a.height - b.height)
        < resizeEpsilon



-- UPDATE


type Msg
    = NoOp
    | TriggerAnimation
    | GotWaapiMsg WAAPI.AnimMsg
    | InitStageElement (Result Dom.Error Dom.Element)
    | GotStageElement (Result Dom.Error Dom.Element)
    | OnWindowResize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState <|
                        perspectiveAnimation model.currentAnimAreaSize model.perspectiveStep
            in
            ( { model
                | animState = animState
              }
            , cmd
            )

        GotWaapiMsg animMsg ->
            let
                ( animState, maybeAnimEvent ) =
                    WAAPI.update animMsg model.animState
            in
            case maybeAnimEvent of
                Just animEvent ->
                    handleMotionEvent animEvent { model | animState = animState }

                Nothing ->
                    ( { model | animState = animState }, Cmd.none )

        InitStageElement (Ok { element }) ->
            let
                measured =
                    toInnerArea
                        { height = element.height, width = element.width }
            in
            ( { model | currentAnimAreaSize = measured }
            , Process.sleep 0
                |> Task.perform (always TriggerAnimation)
            )

        InitStageElement (Err _) ->
            ( model, Cmd.none )

        GotStageElement (Ok { element }) ->
            let
                newAreaSize =
                    toInnerArea
                        { height = element.height, width = element.width }
            in
            if isSameArea newAreaSize model.currentAnimAreaSize then
                ( model, Cmd.none )

            else
                let
                    scale =
                        min newAreaSize.width newAreaSize.height
                            / min model.currentAnimAreaSize.width model.currentAnimAreaSize.height

                    scaleBounds =
                        { x = Just { min = scale, max = scale }
                        , y = Just { min = scale, max = scale }
                        , z = Just { min = scale, max = scale }
                        }

                    legBounds =
                        -- Only constrain the axis that is actually moving for
                        -- the in-flight leg. The dot (translate) and the
                        -- camera (perspective-origin) share the same perimeter
                        -- path, so the same bounds value drives both.
                        --
                        -- Bounding the static axis would re-clamp its
                        -- endpoint into the new bounds and pull the dot off
                        -- the corner it currently sits on - and (more
                        -- importantly during a drag) each resize event would
                        -- mutate the static axis bounds and force another
                        -- cancel+recreate of the running animation, drifting
                        -- the perspective-origin compositor clock behind the
                        -- dot's. The static-axis pin is delivered separately
                        -- via `Translate.position` / `PerspectiveOrigin.position`
                        -- below.
                        case inFlightPerspectiveStep model.perspectiveStep of
                            XAxisLeg ->
                                { x = Just { min = 0, max = newAreaSize.width }
                                , y = Nothing
                                , z = Nothing
                                }

                            YAxisLeg ->
                                { x = Nothing
                                , y = Just { min = 0, max = newAreaSize.height }
                                , z = Nothing
                                }

                    legSnap =
                        -- Static-axis pin shared by translate and
                        -- perspective-origin: both ride the same perimeter
                        -- track, so they snap to the same edge.
                        staticAxisSnap model.perspectiveStep newAreaSize

                    ( animState, cmd ) =
                        -- `Scale.bounds` remaps the cube scale snapshot
                        -- proportionally to the new container (policy set at init).
                        -- `Translate.bounds` remaps the moving axis only -
                        -- `Translate.position` snaps the static axis to its
                        -- new pixel edge without a cancel+recreate cycle.
                        -- `PerspectiveOrigin.bounds` + `PerspectiveOrigin.position`
                        -- mirror that split for the camera, keeping its live
                        -- compositor clock in lockstep with the dot.
                        -- Group-wide `Resize.bounds` is avoided here because
                        -- it would also clamp `Translate.initZ 200` into the
                        -- scale-ratio bounds and collapse the cube's z-depth.
                        WAAPI.onResize model.animState <|
                            Scale.bounds cubeGroupName scaleBounds
                                >> Translate.bounds vanishingPointDot.groupName legBounds
                                >> Translate.position vanishingPointDot.groupName legSnap
                                >> PerspectiveOrigin.bounds perspectiveContainer.groupName legBounds
                                >> PerspectiveOrigin.position perspectiveContainer.groupName { x = legSnap.x, y = legSnap.y }
                in
                ( { model
                    | animState = animState
                    , currentAnimAreaSize = newAreaSize
                  }
                , cmd
                )

        GotStageElement (Err _) ->
            ( model, Cmd.none )

        OnWindowResize _ _ ->
            ( model
            , Task.attempt GotStageElement <|
                Dom.getElement perspectiveContainer.id
            )


handleMotionEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
handleMotionEvent animEvent model =
    case animEvent of
        WAAPI.Ended "perspectiveContainerAnim" ->
            perspectiveStepEnded model

        _ ->
            ( model, Cmd.none )


perspectiveStepEnded : Model -> ( Model, Cmd Msg )
perspectiveStepEnded model =
    let
        nextStep =
            nextPerspectiveStep model.perspectiveStep

        ( animState, cmd ) =
            WAAPI.animate model.animState <|
                perspectiveAnimation model.currentAnimAreaSize nextStep
    in
    ( { model
        | animState = animState
        , perspectiveStep = nextStep
      }
    , cmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WAAPI.subscriptions GotWaapiMsg model.animState
        , Browser.Events.onResize OnWindowResize
        ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "WAAPI Engine - 3D Perspective Origin Example"
    , body =
        [ div [ class "example-stage" ]
            [ div [ class "example-badge example-badge--responsive" ] [ text "RESPONSIVE" ]
            , viewAnimationArea model
            ]
        ]
    }


viewAnimationArea : Model -> Html Msg
viewAnimationArea model =
    div
        (WAAPI.attributes perspectiveContainer.groupName model.animState
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


viewVanishingPoint : WAAPI.AnimState Msg -> Html Msg
viewVanishingPoint animState =
    div
        (WAAPI.attributes vanishingPointDot.groupName animState
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
            , style "background" "rgba(40, 40, 40, 0.3)"
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
            WAAPI.attributes cubeGroupName model.animState

        cubeSize =
            toFloat model.cube.size
    in
    div
        (cubeAttrs
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


viewFace : Float -> WAAPI.AnimState Msg -> FaceConfig -> Html Msg
viewFace cubeSize animState config =
    let
        faceAnimAttributes =
            WAAPI.attributes config.groupName animState
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
            [ id config.text.id
            , style "color" config.text.color
            , style "position" "absolute"
            ]
            [ text config.text.label ]
        ]
