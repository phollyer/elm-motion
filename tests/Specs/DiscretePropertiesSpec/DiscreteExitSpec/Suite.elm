module Specs.DiscretePropertiesSpec.DiscreteExitSpec.Suite exposing (suite)

import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.Runner as Runner
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestData)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Animate as Animate
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Animate2 as Animate2
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.AnimateIsolation as AnimateIsolation
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.AnimateComplete as AnimateComplete
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.AnimateCompleteAnimate as AnimateCompleteAnimate
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Init as Init
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.NoOpAfterComplete as NoOpAfterComplete
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.RetargetIsolation as RetargetIsolation
import Test exposing (Test, describe)


suite : Test
suite =
    describe "discreteExit preserves style output for configured properties"
        [ describe "Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) testData
        ]


testData : List TestData
testData =
    [ Init.testData
    , Animate.testData
    , Animate2.testData
    , AnimateComplete.testData
    , AnimateCompleteAnimate.testData
    , AnimateIsolation.testData
    , RetargetIsolation.testData
    , NoOpAfterComplete.testData
    ]
