module Anim.Engine.Transition.Api.TransformOrderSpec exposing (suite)

import Anim.Engine.Transition as Transition
import Factories.Engines.TransformOrder exposing (transformOrderFactory)
import Helpers.Engine.Api.TransformOrderSpec.Runner as Runner
import Helpers.Engine.Api.TransformOrderSpec.TestData exposing (..)
import Test exposing (Test, describe)



{-
   ==========================================================

   Transform Order in Transition

   ==========================================================
-}


suite : Test
suite =
    describe "Transition.transformOrder, writes the correct transform order" <|
        Runner.run Transition.init Transition.attributes <|
            [ transformOrderTestData <|
                transformOrderFactory Transition.transformOrder
            ]
