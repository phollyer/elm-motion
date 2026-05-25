module Animation.Transition.Animate3D.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Browser.Dom
import Browser.Events
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
    { animState : Transition.AnimState
    , state : State
    , scale : Float
    }



---8<-- [start:initializeAndTrigger]


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimState =
            Transition.init <|
                [ -- Uniform scale applied to a wrapper around the cube. The
                  -- whole 3D scene (cube + faces + offsets) is authored in
                  -- fixed pixels against `referenceStageSize`, and this
                  -- single scale factor resizes everything proportionally
                  -- when the viewport changes. Sidesteps the CSS-transition
                  -- + container-query-unit freeze that would otherwise lock
                  -- face depths to their starting pixel resolution.
                  Scale.initXYZ scaleGroupName 1 1 1

                -- Bring the cube forward on the Z axis so that it doesn't
                -- get clipped by the z=0 clipping plane when we expand the
                -- sides and rotate. Scales with the rest of the scene via
                -- the wrapper above.
                , Translate.initZ cubeGroupName 200

                -- Position each face in 3D space along the axis it faces.
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
      , state = Opening
      , scale = 1
      }
    , Browser.Dom.getViewport
        |> Task.perform GotInitialViewport
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


{-| Animation group for the wrapper element that carries the uniform
`Scale` used for responsive resizing. Kept separate from `cubeGroupName`
(which owns the cube's `Rotate`) so the two animations never share a
CSS `transition` declaration and can run independently.
-}
scaleGroupName : String
scaleGroupName =
    "cubeScaleAnim"


{-| Reference stage edge length the cube's pixel geometry is authored
against. Actual rendered scale is `currentStageSize / referenceStageSize`.
-}
referenceStageSize : Float
referenceStageSize =
    500


{-| Cube edge length in pixels at scale = 1. The wrapping `Scale`
animation resizes everything proportionally on viewport changes, so
this (and every other dimension below) stays a fixed pixel value.
-}
cubeSize : Float
cubeSize =
    90


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
-- CUBE - 1st level of 3D animation
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



-- SIDES - 2nd level of 3D animation
--
-- For the side movement animations, we build complex animations out of
-- smaller pieces.


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
    Transition.duration 1000
        >> Transition.easing CircInOut


moveFace : FaceConfig -> (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveFace config moveToBuilder =
    sharedTiming
        >> Translate.for config.groupName
        >> moveToBuilder
        >> Translate.build



-- Each face moves along the axis it faces by a `moveAmount` (in pixels,
-- against the reference stage size) when the cube expands, and moves back
-- to its original position when the cube closes. The wrapping `Scale`
-- group resizes all faces uniformly on viewport changes.
--
-- Front/Back faces move on Z (forward/backward)
-- Left/Right faces move on X (sideways)
-- Top/Bottom faces move on Y (up/down)


moveAmount : Float
moveAmount =
    50


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



-- TEXT - 3rd level of 3D animation
--
-- Text moves forward (Z+20) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : TextConfig -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
moveText config toZ toRotate =
    sharedTiming
        >> Translate.for config.groupName
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
    | GotTransitionsMsg Transition.AnimMsg
    | TriggerAnimation
    | GotInitialViewport Browser.Dom.Viewport
    | WindowResized Int Int



---8<-- [start:handleAnimationEvents]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            let
                animState =
                    Transition.animate model.animState <|
                        selectAnimation depth model.state
            in
            ( { model | animState = animState }
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

        GotInitialViewport viewport ->
            let
                newScale =
                    scaleForViewport viewport.viewport.width viewport.viewport.height
            in
            ( { model
                | scale = newScale
                , animState =
                    -- Snap the wrapper to the correct scale before the
                    -- opening animation runs, so the cube starts at the
                    -- right rendered size with no visible pop.
                    Transition.retarget model.animState (scaleTo newScale)
              }
            , Process.sleep 0
                |> Task.perform (always TriggerAnimation)
            )

        WindowResized width height ->
            let
                newScale =
                    scaleForViewport (toFloat width) (toFloat height)
            in
            ( { model
                | scale = newScale
                , animState =
                    -- Smoothly chase the new size. Short duration so a
                    -- continuous resize drag tracks the window. Runs on
                    -- the dedicated `scaleGroupName` element, so the
                    -- per-face open/close animations are not disturbed.
                    Transition.animate model.animState <|
                        (Scale.for scaleGroupName
                            >> Scale.toXYZ newScale newScale newScale
                            >> Scale.duration 150
                            >> Scale.easing Linear
                            >> Scale.build
                        )
              }
            , Cmd.none
            )


scaleTo : Float -> AnimBuilder mode -> AnimBuilder mode
scaleTo s =
    Scale.for scaleGroupName
        >> Scale.toXYZ s s s
        >> Scale.build


{-| Mirrors the stage's CSS `min(90vw, 90vh)` sizing, then divides by
the authoring reference to produce the scale factor for the wrapper.
-}
scaleForViewport : Float -> Float -> Float
scaleForViewport vw vh =
    Basics.min (vw * 0.9) (vh * 0.9) / referenceStageSize


handleEvent : Transition.AnimEvent -> Model -> Model
handleEvent animEvent model =
    case animEvent of
        Transition.Ended _ _ "cubeAnim" ->
            cubeRotationEnded model

        Transition.Ended _ _ "frontFaceAnim" ->
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
            Transition.animate model.animState <|
                selectAnimation depth state
    in
    { model
        | state = state
        , animState = animState
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize WindowResized



---8<-- [end:handleAnimationEvents]
-- VIEW


view : Model -> Document Msg
view model =
    { title = "Transition 3D Example"
    , body =
        [ div
            [ Html.Attributes.class "example-stage"
            , id "example-stage"
            , style "width" "min(90vw, 90vh)"
            , style "height" "min(90vw, 90vh)"
            ]
            [ text ""
            , viewAnimationArea model
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


cubeSizeCss : String
cubeSizeCss =
    String.fromFloat cubeSize ++ "px"


viewCube : Model -> Html Msg
viewCube model =
    let
        scaleAttrs =
            Transition.attributes scaleGroupName model.animState

        cubeAttrs =
            Transition.attributes cubeGroupName model.animState

        cubeEvents =
            Transition.events GotTransitionsMsg
    in
    -- Wrapper applies the responsive uniform `Scale`. Sits inside the
    -- perspective container so perspective stays fixed in px, but outside
    -- the cube so its rotation animation doesn't share a `transition`
    -- declaration with the scale animation.
    div
        (scaleAttrs
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id "cube-scale-wrapper"
               , style "width" cubeSizeCss
               , style "height" cubeSizeCss
               , style "position" "relative"
               ]
        )
        [ div
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
        ]


viewFace : Transition.AnimState -> FaceConfig -> Html Msg
viewFace animState config =
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
               , style "width" cubeSizeCss
               , style "height" cubeSizeCss
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



---8<-- [end:render]
