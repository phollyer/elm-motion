module Anim.Engine.Keyframe.Api.TransformOrderSpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Factories.Engines.TransformOrder exposing (transformOrderFactory)
import Helpers.Engine.Api.TransformOrderSpec.Runner as Runner
import Helpers.Engine.Api.TransformOrderSpec.TestData exposing (..)
import Test exposing (Test, describe)



{-
   ==========================================================

   Transform Order in Keyframe

   ==========================================================
-}


suite : Test
suite =
    describe "Keyframe.transformOrder, writes the correct transform order" <|
        Runner.run Keyframe.init Keyframe.attributes <|
            [ transformOrderTestData <|
                transformOrderFactory Keyframe.transformOrder
            ]
