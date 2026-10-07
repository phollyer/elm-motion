module Specs.DelaySpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Factories.Capabilities exposing (WithTiming)
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.DelaySpec.Runner as Runner
import Specs.DelaySpec.TestData exposing (TestData)
import Specs.DelaySpec.TestData.CustomColor as CustomColor
import Specs.DelaySpec.TestData.CustomProperty as CustomProperty
import Specs.DelaySpec.TestData.MultipleProperties as Scale
import Specs.DelaySpec.TestData.Opacity as Opacity
import Specs.DelaySpec.TestData.PerspectiveOrigin as PerspectiveOrigin
import Specs.DelaySpec.TestData.Rotate as Rotate
import Specs.DelaySpec.TestData.Size as Size
import Specs.DelaySpec.TestData.Skew as Skew
import Specs.DelaySpec.TestData.Translate as Translate
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "delay functions write the correct delay"
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
    ]
