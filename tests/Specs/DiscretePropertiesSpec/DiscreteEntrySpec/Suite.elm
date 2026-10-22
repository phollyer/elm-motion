module Specs.DiscretePropertiesSpec.DiscreteEntrySpec.Suite exposing (suite)

import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.Runner as Runner
import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData exposing (TestData)
import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData.Animate as Animate
import Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData.Init as Init
import Test exposing (Test, describe)


suite : Test
suite =
    describe "discreteEntry preserves style output for configured properties"
        [ describe "Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) testData
        ]


testData : List TestData
testData =
    [ Init.testData
    , Animate.testData
    ]
