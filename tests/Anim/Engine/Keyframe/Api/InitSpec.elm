module Anim.Engine.Keyframe.Api.InitSpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Factories.Properties.CustomColor as CustomColorFactory
import Factories.Properties.CustomProperty as CustomPropertyFactory
import Factories.Properties.Init exposing (..)
import Factories.Properties.Opacity as OpacityFactory
import Factories.Properties.PerspectiveOrigin as PerspectiveOriginFactory
import Factories.Properties.Rotate as RotateFactory
import Factories.Properties.Scale as ScaleFactory
import Factories.Properties.Size as SizeFactory
import Factories.Properties.Skew as SkewFactory
import Factories.Properties.Translate as TranslateFactory
import Helpers.Engine.Api.InitSpec.Runner as Runner
import Helpers.Engine.Api.InitSpec.TestData.CustomColor exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.CustomProperty exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.MultipleGroups exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.MultipleProperties exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Opacity exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.PerspectiveOrigin exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Rotate exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Scale exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Size exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Skew exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Translate exposing (..)
import Test exposing (Test, describe)



{-
   ==========================================================

   Initialised Axes Write Initial Inline Styles

   ==========================================================
-}


suite : Test
suite =
    describe "Keyframe.init, writes inline styles, and will-change" <|
        Runner.run Keyframe.init Keyframe.attributes <|
            [ customPropertyTestData CustomPropertyFactory.initFactory
            , customColorTestData CustomColorFactory.initFactory
            , opacityTestData OpacityFactory.initFactory
            , perspectiveOriginTestData PerspectiveOriginFactory.initFactory
            , rotateTestData RotateFactory.initFactory
            , scaleTestData ScaleFactory.initFactory
            , skewTestData SkewFactory.initFactory
            , sizeTestData SizeFactory.initFactory
            , translateTestData TranslateFactory.initFactory
            , multiPropertyTestData multiPropertyFactory
            , multiGroupTestData multiGroupFactory
            ]
