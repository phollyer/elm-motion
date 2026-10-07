module Specs.InitSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Transition as Transition
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.InitSpec.Runner as Runner
import Specs.InitSpec.TestData exposing (TestData)
import Specs.InitSpec.TestData.CustomColor as CustomColor
import Specs.InitSpec.TestData.CustomProperty as CustomProperty
import Specs.InitSpec.TestData.MultipleGroups as MultipleGroups
import Specs.InitSpec.TestData.MultipleProperties as MultipleProperties
import Specs.InitSpec.TestData.Opacity as Opacity
import Specs.InitSpec.TestData.PerspectiveOrigin as PerspectiveOrigin
import Specs.InitSpec.TestData.Rotate as Rotate
import Specs.InitSpec.TestData.Scale as Scale
import Specs.InitSpec.TestData.Size as Size
import Specs.InitSpec.TestData.Skew as Skew
import Specs.InitSpec.TestData.Translate as Translate
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "init* functions write inline styles and will-change"
        [ describe "Keyframe engine" <|
            Runner.run (Factory.Keyframe KeyframeFactory.factory) Keyframe.attributes testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) Transition.attributes testData
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
