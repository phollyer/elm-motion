module Specs.DiscretePropertiesSpec.DiscreteExitSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Factories.Capabilities exposing (WithTiming)
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.Runner as Runner
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing (TestData)
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.CustomColor as CustomColor
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.CustomProperty as CustomProperty
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.MultipleGroups as MultipleGroups
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.MultipleProperties as MultipleProperties
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Opacity as Opacity
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.PerspectiveOrigin as PerspectiveOrigin
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Rotate as Rotate
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Scale as Scale
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Size as Size
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Skew as Skew
import Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData.Translate as Translate
import Test exposing (Test, describe)


suite : Test
suite =
    describe "discreteExit preserves style output for configured properties"
        [ describe "Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) testData
        ]


testData : List (TestData (AnimBuilder (WithTiming eng)))
testData =
    [ CustomColor.testData
    , CustomProperty.testData
    , Opacity.testData
    , PerspectiveOrigin.testData
    , Rotate.testData
    , Scale.testData
    , Size.testData
    , Skew.testData
    , Translate.testData
    , MultipleProperties.testData
    , MultipleGroups.testData
    ]
