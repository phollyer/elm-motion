module Specs.InitSpec.Suite exposing (suite)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Transition as Transition
import Factories.Properties.All as AllFactory
import Factories.Properties.CustomColor as CustomColorFactory
import Factories.Properties.CustomProperty as CustomPropertyFactory
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory
import Specs.InitSpec.Runner as Runner
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
            Runner.run Keyframe.init Keyframe.attributes testData
        , describe "Transition engine" <|
            Runner.run Transition.init Transition.attributes testData
        ]


testData : List (Runner.TestData (AnimBuilder eng -> AnimBuilder eng))
testData =
    [ CustomColor.testData CustomColorFactory.initFactory
    , CustomProperty.testData CustomPropertyFactory.initFactory
    , Opacity.testData OpacityFactory.initFactory
    , PerspectiveOrigin.testData PerspectiveOriginFactory.initFactory
    , Rotate.testData RotateFactory.initFactory
    , Scale.testData ScaleFactory.initFactory
    , Size.testData SizeFactory.initFactory
    , Skew.testData SkewFactory.initFactory
    , Translate.testData TranslateFactory.initFactory
    , MultipleProperties.testData AllFactory.initFactory
    , MultipleGroups.testData AllFactory.initFactory
    ]
