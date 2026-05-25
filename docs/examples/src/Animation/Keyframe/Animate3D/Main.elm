module Animation.Keyframe.Animate3D.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Browser exposing (Document)
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState
    , state : State
    }



---8<-- [start:initializeAndTrigger]


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimState =
            Keyframe.init <|
                [ -- Bring the cube forward on the Z axis
                  -- so that it doesn't get clipped by the
                  -- z=0 clipping plane when we expand the
                  -- sides and rotate. This is a fixed 3D depth
                  -- offset, unrelated to layout, so it stays
                  -- in pixels.
                  Translate.initUnit Px >> Translate.initZ cubeGroupName 200

                -- Position each face in 3D space along the axis it faces.
                -- Face offsets use `Cqmin` so the cube scales proportionally
                -- with the stage's smaller dimension on resize.
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initUnit Cqmin >> Translate.initZ frontFace.groupName depth
                , Translate.initUnit Cqmin
                    >> Translate.initZ backFace.groupName (depth * -1)
                    -- Rotate each face into position to build the cube
                    -- Front face is not rotated due to facing forward by default
                    >> Rotate.initY backFace.groupName 180
                , Translate.initUnit Cqmin
                    >> Translate.initX rightFace.groupName depth
                    >> Rotate.initY rightFace.groupName 90
                , Translate.initUnit Cqmin
                    >> Translate.initX leftFace.groupName (-1 * depth)
                    >> Rotate.initY leftFace.groupName -90
                , Translate.initUnit Cqmin
                    >> Translate.initY topFace.groupName (-1 * depth)
                    >> Rotate.initX topFace.groupName 90
                , Translate.initUnit Cqmin
                    >> Translate.initY bottomFace.groupName depth
                    >> Rotate.initX bottomFace.groupName -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting position for elements, so we don't need
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



---8<-- [start:selectAnimation]


selectAnimation : Float -> State -> AnimBuilder mode -> AnimBuilder mode
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
-- ANIMATIONS
--
---8<-- [start:animationFunctions]
-- CUBE ROTATION
--
-- We only rotate the cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> AnimBuilder mode -> AnimBuilder mode
rotateCube to =
    Rotate.for cubeGroupName
        >> Rotate.toXYZ to to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.build


rotateCubeClockwise : AnimBuilder mode -> AnimBuilder mode
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : AnimBuilder mode -> AnimBuilder mode
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES


moveSidesOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveSidesOut targetAmount =
    moveFrontFaceOut targetAmount
        >> moveBackFaceOut targetAmount
        >> moveRightFaceOut targetAmount
        >> moveLeftFaceOut targetAmount
        >> moveTopFaceOut targetAmount
        >> moveBottomFaceOut targetAmount


moveSidesIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveSidesIn targetAmount =
    moveFrontFaceIn targetAmount
        >> moveBackFaceIn targetAmount
        >> moveRightFaceIn targetAmount
        >> moveLeftFaceIn targetAmount
        >> moveTopFaceIn targetAmount
        >> moveBottomFaceIn targetAmount


sharedTiming : AnimBuilder mode -> AnimBuilder mode
sharedTiming =
    Keyframe.duration 1000
        >> Keyframe.easing CircInOut


moveFace : FaceConfig -> (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveFace config moveToBuilder =
    sharedTiming
        >> Translate.for config.groupName
        >> Translate.cssUnit Cqmin
        >> moveToBuilder
        >> Translate.build



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


moveFrontFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveFrontFaceOut toZ =
    moveFace frontFace <|
        Translate.toZ (toZ + moveAmount)


moveFrontFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveFrontFaceIn toZ =
    moveFace frontFace <|
        Translate.toZ toZ


moveBackFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveBackFaceOut toZ =
    moveFace backFace <|
        Translate.toZ (-1 * toZ - moveAmount)


moveBackFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveBackFaceIn toZ =
    moveFace backFace <|
        Translate.toZ (-1 * toZ)


moveRightFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveRightFaceOut toX =
    moveFace rightFace <|
        Translate.toX (toX + moveAmount)


moveRightFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveRightFaceIn toX =
    moveFace rightFace <|
        Translate.toX toX


moveLeftFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveLeftFaceOut toX =
    moveFace leftFace <|
        Translate.toX (-1 * toX - moveAmount)


moveLeftFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveLeftFaceIn toX =
    moveFace leftFace <|
        Translate.toX (-1 * toX)


moveTopFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveTopFaceOut toY =
    moveFace topFace <|
        Translate.toY (-1 * toY - moveAmount)


moveTopFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveTopFaceIn toY =
    moveFace topFace <|
        Translate.toY (-1 * toY)


moveBottomFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveBottomFaceOut toY =
    moveFace bottomFace <|
        Translate.toY (toY + moveAmount)


moveBottomFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveBottomFaceIn toY =
    moveFace bottomFace <|
        Translate.toY toY



-- TEXT
--
-- Text moves forward (Z+20) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    4


moveText : TextConfig -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
moveText config toZ toRotate =
    sharedTiming
        >> Translate.for config.groupName
        >> Translate.cssUnit Cqmin
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for config.groupName
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : AnimBuilder mode -> AnimBuilder mode
moveTextsOut =
    moveText frontFace.text textMoveAmount 360
        >> moveText backFace.text textMoveAmount 360
        >> moveText rightFace.text textMoveAmount 360
        >> moveText leftFace.text textMoveAmount 360
        >> moveText topFace.text textMoveAmount 360
        >> moveText bottomFace.text textMoveAmount 360


moveTextsIn : AnimBuilder mode -> AnimBuilder mode
moveTextsIn =
    moveText frontFace.text 0 0
        >> moveText backFace.text 0 0
        >> moveText rightFace.text 0 0
        >> moveText leftFace.text 0 0
        >> moveText topFace.text 0 0
        >> moveText bottomFace.text 0 0



---8<-- [end:animationFunctions]
-- UPDATE


type Msg
    = NoOp
    | GotKeyframeMsg Keyframe.AnimMsg
    | TriggerAnimation



---8<-- [start:handleAnimationEvents]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            let
                animState =
                    Keyframe.animate model.animState <|
                        selectAnimation depth model.state
            in
            ( { model | animState = animState }
            , Cmd.none
            )

        GotKeyframeMsg animMsg ->
            let
                ( animState, animEvent ) =
                    Keyframe.update animMsg model.animState
            in
            ( handleEvent animEvent { model | animState = animState }
            , Cmd.none
            )


handleEvent : Keyframe.AnimEvent -> Model -> Model
handleEvent animEvent model =
    case animEvent of
        Keyframe.Ended _ _ "cubeAnim" ->
            cubeRotationEnded model

        Keyframe.Ended _ _ "frontFaceAnim" ->
            sidesMovementEnded model

        _ ->
            model


cubeRotationEnded : Model -> Model
cubeRotationEnded model =
    case model.state of
        RotatingOpen ->
            stateChanged Closing model

        RotatingClosed ->
            stateChanged Opening model

        _ ->
            model


sidesMovementEnded : Model -> Model
sidesMovementEnded model =
    case model.state of
        Opening ->
            stateChanged RotatingOpen model

        Closing ->
            stateChanged RotatingClosed model

        _ ->
            model


stateChanged : State -> Model -> Model
stateChanged state model =
    let
        animState =
            Keyframe.animate model.animState <|
                selectAnimation depth state
    in
    { model
        | state = state
        , animState = animState
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



---8<-- [end:handleAnimationEvents]
-- VIEW


view : Model -> Document Msg
view model =
    { title = "Keyframe 3D Example"
    , body =
        [ Keyframe.styleNode model.animState
        , div
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
        -- Harmless hack for Chrome on macOS GPU compositing issues with 3D transforms.
        -- Setting opacity: 0.99 forces a new compositing layer, which prevents
        -- colored rectangle artifacts that can appear during complex 3D animations.
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


cubeSizeCss : String
cubeSizeCss =
    String.fromFloat cubeSize ++ "cqmin"


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            Keyframe.attributes cubeGroupName model.animState

        cubeEvents =
            Keyframe.events GotKeyframeMsg
    in
    div
        (cubeAttrs
            ++ cubeEvents
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


viewFace : Keyframe.AnimState -> FaceConfig -> Html Msg
viewFace animState config =
    let
        faceAnimAttributes =
            Keyframe.attributes config.groupName animState

        textAnimAttributes =
            Keyframe.attributes config.text.groupName animState
    in
    div
        (faceAnimAttributes
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
            (textAnimAttributes
                ++ [ id config.text.id
                   , style "color" config.text.color
                   , style "position" "absolute"
                   ]
            )
            [ text config.text.label ]
        ]



---8<-- [end:render]
