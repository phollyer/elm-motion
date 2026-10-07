module Specs.TransformOrderSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.TransformOrderSpec.Runner as Runner
import Specs.TransformOrderSpec.TestData exposing (TestData)
import Specs.TransformOrderSpec.TestData.Animate as Animate
import Specs.TransformOrderSpec.TestData.Init as Init
import Test exposing (Test, describe)



{-
   ==========================================================

   Transform Order in Transition

   ==========================================================
-}


suite : Test
suite =
    describe "transformOrder writes the correct transform order"
        [ describe "Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) testData
        ]


testData : List (TestData (AnimBuilder eng))
testData =
    [ Animate.testData
    , Init.testData
    ]
