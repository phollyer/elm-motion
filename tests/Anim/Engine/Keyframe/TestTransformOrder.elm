module Anim.Engine.Keyframe.TestTransformOrder exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Position
import Expect
import Motion.Easing as Easing
import Test exposing (..)


suite : Test
suite =
    describe "Transform Order in Keyframe"
        [ test "should respect canonical CSS order: Position -> Rotate -> Scale" <|
            \_ ->
                let
                    animations =
                        Keyframe.animate (Keyframe.init []) <|
                            (Keyframe.duration 1000
                                >> Keyframe.easing Easing.Linear
                                >> Keyframe.for "test-element"
                                -- First: Position
                                >> Position.begin
                                >> Position.toXY 100 50
                                >> Position.end
                                -- Second: Rotate
                                >> Rotate.begin
                                >> Rotate.toZ 45
                                >> Rotate.end
                                -- Third: Scale
                                >> Scale.begin
                                >> Scale.fromXY 1.0 1.0
                                >> Scale.toXY 1.5 1.2
                                >> Scale.end
                            )
                in
                Keyframe.maybeString "test-element" animations
                    |> Maybe.withDefault ""
                    |> String.contains "translate3d(100px, 50px, 0px) rotateZ(45deg) scaleX(1.5) scaleY(1.2)"
                    |> Expect.equal True
        ]
