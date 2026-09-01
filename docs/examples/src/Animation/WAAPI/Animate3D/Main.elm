port module Animation.WAAPI.Animate3D.Main exposing (main)

import Anim.Builder exposing (AnimBuilder, ForWAAPI)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser exposing (Document)
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg
    , state : State
    }



---8<-- [start:initializeAndTrigger]


init : ( Model, Cmd Msg )
init =
    let
        initialAnimState =
            WAAPI.init motionCmd motionMsg <|
                [ -- Bring the cube forward on the Z axis
                  -- so that it doesn't get clipped by the
                  -- z=0 clipping plane when we expand the
                  -- sides and rotate. This is a fixed 3D depth
                  -- offset, unrelated to layout, so it stays
                  -- in pixels.
                  Translate.initZ cubeGroupName 200
                    >> Translate.initCssUnit Px

                -- Position each face in 3D space along the axis it faces.
                -- Face offsets use `Cqmin` so the cube scales proportionally
                -- with the stage's new dimensions on resize.
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initZ frontFace.groupName depth
                    >> Translate.initCssUnit Cqmin
                , Translate.initZ backFace.groupName (depth * -1)
                    >> Translate.initCssUnit Cqmin
                    -- Rotate each face into position to build the cube
                    -- Front face is not rotated due to facing forward by default
                    >> Rotate.initY backFace.groupName 180
                , Translate.initX rightFace.groupName depth
                    >> Translate.initCssUnit Cqmin
                    >> Rotate.initY rightFace.groupName 90
                , Translate.initX leftFace.groupName (-1 * depth)
                    >> Translate.initCssUnit Cqmin
                    >> Rotate.initY leftFace.groupName -90
                , Translate.initY topFace.groupName (-1 * depth)
                    >> Translate.initCssUnit Cqmin
                    >> Rotate.initX topFace.groupName 90
                , Translate.initY bottomFace.groupName depth
                    >> Translate.initCssUnit Cqmin
                    >> Rotate.initX bottomFace.groupName -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting value, so we don't need
                -- to initialize them
                ]
    in
    ( { animState = initialAnimState
      , state = Opening
      }
    , Process.sleep 0
        |> Task.perform (always TriggerAnimation)
    )



---8<-- [end:initializeAndTrigger]


type State
    = Opening
    | Closing
    | RotatingOpen
    | RotatingClosed



-- Cube configuration


cubeGroupName : String
cubeGroupName =
    "cubeAnim"


{-| Cube edge length expressed in `Cqmin` (% of the stage's smaller
dimension). The stage applies `container-type: size`, so the cube
resizes automatically with the viewport without any Elm-side
measurement.
-}
cubeSize : Float
cubeSize =
    18


cubeSizeCss : String
cubeSizeCss =
    String.fromFloat cubeSize ++ "cqmin"


{-| Distance each face sits in front of / behind the cube centre.
Half the cube edge so adjacent faces meet at the cube corners.
-}
depth : Float
depth =
    cubeSize / 2



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
        , color = "rgb(0,0,0)"
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
        , color = "rgb(0,0,0)"
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
        , color = "rgb(0,0,0)"
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
        , color = "rgb(0,0,0)"
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
        , color = "rgb(0,0,0)"
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
        , color = "rgb(0,0,0)"
        }
    }



-- ANIMATIONS
--
---8<-- [start:animationFunctions]
-- CUBE
--
-- We only rotate the cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
rotateCube to =
    WAAPI.for cubeGroupName
        >> Rotate.begin
        >> Rotate.toXYZ to to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.end


rotateCubeClockwise : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES


moveSidesOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveSidesOut targetAmount =
    moveFrontFaceOut targetAmount
        >> moveBackFaceOut targetAmount
        >> moveRightFaceOut targetAmount
        >> moveLeftFaceOut targetAmount
        >> moveTopFaceOut targetAmount
        >> moveBottomFaceOut targetAmount


moveSidesIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveSidesIn targetAmount =
    moveFrontFaceIn targetAmount
        >> moveBackFaceIn targetAmount
        >> moveRightFaceIn targetAmount
        >> moveLeftFaceIn targetAmount
        >> moveTopFaceIn targetAmount
        >> moveBottomFaceIn targetAmount


sharedTiming : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
sharedTiming =
    WAAPI.duration 1000
        >> WAAPI.easing CircInOut


moveFace : FaceConfig -> (Translate.Builder ForWAAPI -> Translate.Builder ForWAAPI) -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveFace config moveToBuilder =
    sharedTiming
        >> WAAPI.for config.groupName
        >> Translate.begin
        >> moveToBuilder
        >> Translate.end



-- Each face moves along the axis it faces by a `moveAmount` (expressed in
-- `Cqmin`, so it scales with the stage) when the cube expands, and moves
-- back to its original position when the cube closes.
--
-- Front/Back faces move on Z (forward/backward)
-- Left/Right faces move on X (sideways)
-- Top/Bottom faces move on Y (up/down)


moveAmount : Float
moveAmount =
    10


moveFrontFaceOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveFrontFaceOut toZ =
    moveFace frontFace <|
        Translate.toZ (toZ + moveAmount)


moveFrontFaceIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveFrontFaceIn toZ =
    moveFace frontFace <|
        Translate.toZ toZ


moveBackFaceOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveBackFaceOut toZ =
    moveFace backFace <|
        Translate.toZ (-1 * toZ - moveAmount)


moveBackFaceIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveBackFaceIn toZ =
    moveFace backFace <|
        Translate.toZ (-1 * toZ)


moveRightFaceOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveRightFaceOut toX =
    moveFace rightFace <|
        Translate.toX (toX + moveAmount)


moveRightFaceIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveRightFaceIn toX =
    moveFace rightFace <|
        Translate.toX toX


moveLeftFaceOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveLeftFaceOut toX =
    moveFace leftFace <|
        Translate.toX (-1 * toX - moveAmount)


moveLeftFaceIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveLeftFaceIn toX =
    moveFace leftFace <|
        Translate.toX (-1 * toX)


moveTopFaceOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveTopFaceOut toY =
    moveFace topFace <|
        Translate.toY (-1 * toY - moveAmount)


moveTopFaceIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveTopFaceIn toY =
    moveFace topFace <|
        Translate.toY (-1 * toY)


moveBottomFaceOut : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveBottomFaceOut toY =
    moveFace bottomFace <|
        Translate.toY (toY + moveAmount)


moveBottomFaceIn : Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveBottomFaceIn toY =
    moveFace bottomFace <|
        Translate.toY toY



-- TEXT
--
-- Text moves forward (Z+4cqmin) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0cqmin) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    14


moveText : TextConfig -> Float -> Float -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveText config toZ toRotate =
    sharedTiming
        >> WAAPI.for config.groupName
        >> Translate.begin
        >> Translate.toZ toZ
        >> Translate.end
        >> Rotate.begin
        >> Rotate.toZ toRotate
        >> Rotate.end


moveTextsOut : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveTextsOut =
    moveText frontFace.text textMoveAmount 360
        >> moveText backFace.text textMoveAmount 360
        >> moveText rightFace.text textMoveAmount 360
        >> moveText leftFace.text textMoveAmount 360
        >> moveText topFace.text textMoveAmount 360
        >> moveText bottomFace.text textMoveAmount 360


moveTextsIn : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
moveTextsIn =
    moveText frontFace.text 0 0
        >> moveText backFace.text 0 0
        >> moveText rightFace.text 0 0
        >> moveText leftFace.text 0 0
        >> moveText topFace.text 0 0
        >> moveText bottomFace.text 0 0



---8<-- [end:animationFunctions]
---8<-- [start:selectAnimation]


selectAnimation : Float -> State -> WAAPI.EngineBuilder -> WAAPI.EngineBuilder
selectAnimation targetAmount state =
    case state of
        Opening ->
            moveSidesOut targetAmount
                >> moveTextsOut

        Closing ->
            moveSidesIn targetAmount
                >> moveTextsIn

        RotatingOpen ->
            rotateCubeClockwise

        RotatingClosed ->
            rotateCubeAntiClockwise



---8<-- [end:selectAnimation]
-- UPDATE


type Msg
    = NoOp
    | GotWaapiMsg WAAPI.AnimMsg
    | TriggerAnimation



---8<-- [start:handleAnimationEvents]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState <|
                        selectAnimation depth model.state
            in
            ( { model | animState = animState }
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


handleMotionEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
handleMotionEvent animEvent model =
    case animEvent of
        WAAPI.Ended "cubeAnim" ->
            cubeRotationEnded model

        WAAPI.Ended "frontFaceAnim" ->
            sidesMovementEnded model

        _ ->
            ( model, Cmd.none )


cubeRotationEnded : Model -> ( Model, Cmd Msg )
cubeRotationEnded model =
    case model.state of
        RotatingOpen ->
            stateChanged Closing model

        RotatingClosed ->
            stateChanged Opening model

        _ ->
            ( model, Cmd.none )


sidesMovementEnded : Model -> ( Model, Cmd Msg )
sidesMovementEnded model =
    case model.state of
        Opening ->
            stateChanged RotatingOpen model

        Closing ->
            stateChanged RotatingClosed model

        _ ->
            ( model, Cmd.none )


stateChanged : State -> Model -> ( Model, Cmd Msg )
stateChanged state model =
    let
        ( animState, cmd ) =
            WAAPI.animate model.animState <|
                selectAnimation depth state
    in
    ( { model
        | state = state
        , animState = animState
      }
    , cmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



---8<-- [end:handleAnimationEvents]
-- VIEW


view : Model -> Document Msg
view model =
    { title = "WAAPI 3D Example"
    , body =
        [ div
            [ Html.Attributes.class "example-stage"
            , id "example-stage"
            , style "width" "min(90vw, 90vh)"
            , style "height" "min(90vw, 90vh)"
            , style "container-type" "size"
            ]
            [ viewAnimationArea model
            ]
        ]
    }


viewAnimationArea : Model -> Html Msg
viewAnimationArea model =
    div
        [ -- Perspective container
          View3D.perspective 1000
        , View3D.perspectiveOrigin View3D.Center

        --
        -- Hack for Chrome on macOS GPU compositing issues with 3D transforms.
        -- Setting opacity: 0.99 forces a new compositing layer, which prevents
        -- the colored rectangle artifacts that can appear during complex 3D animations.
        -- It's not perfect, some flickering can still occur.
        , View3D.opacityHack
        , id "animation-area"
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        , style "width" "100%"
        , style "height" "100%"
        , style "flex" "0 0 auto"
        ]
        [ viewCube model ]



---8<-- [start:render]


viewCube : Model -> Html Msg
viewCube model =
    div
        (WAAPI.attributes cubeGroupName model.animState
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id "cube"
               , style "width" cubeSizeCss
               , style "height" cubeSizeCss
               , style "position" "relative"
               ]
        )
        [ viewFace model.animState frontFace
        , viewFace model.animState backFace
        , viewFace model.animState rightFace
        , viewFace model.animState leftFace
        , viewFace model.animState topFace
        , viewFace model.animState bottomFace
        ]


viewFace : WAAPI.AnimState Msg -> FaceConfig -> Html Msg
viewFace animState config =
    div
        (WAAPI.attributes config.groupName animState
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id config.id
               , style "position" "absolute"
               , style "width" cubeSizeCss
               , style "height" cubeSizeCss
               , style "background-color" config.background
               , style "border" ("2px solid " ++ config.borderColor)
               , style "box-sizing" "border-box"
               , style "display" "flex"
               , style "justify-content" "center"
               , style "align-items" "center"
               , style "font-weight" "bold"
               , style "font-size" ("calc(" ++ cubeSizeCss ++ " * 0.13)")
               ]
        )
        [ div
            [ style "color" "#ffffff"
            , style "position" "absolute"
            ]
            [ text config.label ]
        , div
            (WAAPI.attributes config.text.groupName animState
                ++ [ id config.text.id
                   , style "color" config.text.color
                   , style "position" "absolute"
                   ]
            )
            [ text config.text.label ]
        ]



---8<-- [end:render]
