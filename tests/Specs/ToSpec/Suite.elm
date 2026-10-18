module Specs.ToSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.ToSpec.Runner as Runner
import Specs.ToSpec.TestData exposing (TestData)
import Specs.ToSpec.TestData.CustomColor as CustomColor
import Specs.ToSpec.TestData.CustomProperty as CustomProperty
import Specs.ToSpec.TestData.MultipleGroups as MultipleGroups
import Specs.ToSpec.TestData.MultipleProperties as MultipleProperties
import Specs.ToSpec.TestData.Opacity as Opacity
import Specs.ToSpec.TestData.PerspectiveOrigin as PerspectiveOrigin
import Specs.ToSpec.TestData.Rotate as Rotate
import Specs.ToSpec.TestData.Scale as Scale
import Specs.ToSpec.TestData.Size as Size
import Specs.ToSpec.TestData.Skew as Skew
import Specs.ToSpec.TestData.Translate as Translate
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "when the animate function writes configured styles, including 'will-change'"
        [ describe "for the Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) testData
        , describe "for the Transition engine" <|
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
