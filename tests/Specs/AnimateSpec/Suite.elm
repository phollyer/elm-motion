module Specs.AnimateSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.AnimateSpec.Runner as Runner
import Specs.AnimateSpec.TestData exposing (TestData)
import Specs.AnimateSpec.TestData.CustomColor as CustomColor
import Specs.AnimateSpec.TestData.CustomProperty as CustomProperty
import Specs.AnimateSpec.TestData.MultipleGroups as MultipleGroups
import Specs.AnimateSpec.TestData.MultipleProperties as MultipleProperties
import Specs.AnimateSpec.TestData.Opacity as Opacity
import Specs.AnimateSpec.TestData.PerspectiveOrigin as PerspectiveOrigin
import Specs.AnimateSpec.TestData.Rotate as Rotate
import Specs.AnimateSpec.TestData.Scale as Scale
import Specs.AnimateSpec.TestData.Size as Size
import Specs.AnimateSpec.TestData.Skew as Skew
import Specs.AnimateSpec.TestData.Translate as Translate
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "animate function"
        [ describe "Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) testData
        ]


testData : List (TestData (AnimBuilder eng))
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
