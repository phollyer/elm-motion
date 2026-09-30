module Specs.DelaySpec.Suite exposing (..)

{-
   import Specs.InitSpec.TestData.CustomColor as CustomColor
   import Specs.InitSpec.TestData.CustomProperty as CustomProperty
   import Specs.InitSpec.TestData.MultipleGroups as MultipleGroups
   import Specs.InitSpec.TestData.MultipleProperties as MultipleProperties

   import Specs.InitSpec.TestData.PerspectiveOrigin as PerspectiveOrigin
   import Specs.InitSpec.TestData.Rotate as Rotate
   import Specs.InitSpec.TestData.Scale as Scale
   import Specs.InitSpec.TestData.Size as Size
   import Specs.InitSpec.TestData.Skew as Skew
   import Specs.InitSpec.TestData.Translate as Translate
-}

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Transition as Transition
import Factories.Capabilities exposing (WithTiming)
import Factories.Engines.Factory as Factory
import Factories.Engines.Keyframe as KeyframeFactory
import Factories.Engines.Transition as TransitionFactory
import Specs.DelaySpec.Runner as Runner
import Specs.DelaySpec.TestData.Opacity as Opacity
import Specs.DelaySpec.TestData.Size as Size
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
            Runner.run (Factory.Keyframe KeyframeFactory.factory) Keyframe.attributes testData
        , describe "Transition engine" <|
            Runner.run (Factory.Transition TransitionFactory.factory) Transition.attributes testData
        ]


testData : List (Runner.TestData (AnimBuilder (WithTiming eng)))
testData =
    [ {- CustomColor.testData CustomColorFactory.factory
         , CustomProperty.testData CustomPropertyFactory.factory

         ,
      -}
      Opacity.testData
    , Size.testData
    , Translate.testData

    {-
       , PerspectiveOrigin.testData PerspectiveOriginFactory.factory
       , Rotate.testData RotateFactory.factory
       , Scale.testData ScaleFactory.factory
       , Size.testData SizeFactory.factory
       , Skew.testData SkewFactory.factory
       , Translate.testData TranslateFactory.factory
       , MultipleProperties.testData AllFactory.factory
       , MultipleGroups.testData AllFactory.factory
    -}
    ]
