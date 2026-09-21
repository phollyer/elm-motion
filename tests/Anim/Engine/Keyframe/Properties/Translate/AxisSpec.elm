module Anim.Engine.Keyframe.Properties.Translate.AxisSpec exposing (suite)

import Anim.Engine.Keyframe.Properties.Translate.AxisSpec.AnimateTests as Animate
import Anim.Engine.Keyframe.Properties.Translate.AxisSpec.RetargetTests as Retarget
import Test exposing (Test, describe)


{-| Axis Tests

Ensures that keyframe rules are correctly generated for each axis and
that inline styles reflect the expected transform values.

Ensures that untouched axes do not get written to the inline styles or
keyframe rules and thereby do not overwrite a user's existing CSS.

Scenarios under test:

  - the animate pipeline

-}
suite : Test
suite =
    describe "testing: initialized axes are respected, subsequent updates behave correctly and untouched axes do not get written" <|
        [ describe "when using the animate pipeline" Animate.suite
        , describe "when using the retarget pipeline" Retarget.suite
        ]
