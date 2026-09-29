module Specs.TransformOrderSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Transition as Transition
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Factories.Properties.All exposing (factory)
import Specs.TransformOrderSpec.Runner as Runner
import Specs.TransformOrderSpec.TestData as TestData
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
            Runner.run (Factory.Keyframe KeyframeFactory.factory) Keyframe.attributes testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) Transition.attributes testData
        ]


testData : List (Runner.TestData (AnimBuilder eng))
testData =
    [ TestData.testData factory ]
