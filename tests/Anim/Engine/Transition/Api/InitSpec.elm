module Anim.Engine.Transition.Api.InitSpec exposing (suite)

import Anim.Engine.Transition as Transition
import Anim.Unit exposing (Unit(..))
import Factories.Properties.Init exposing (..)
import Helpers.Engine.Api.InitSpec.Runner as Runner exposing (..)
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
    describe "Transition.init, writes inline styles, and will-change" <|
        Runner.run Transition.init Transition.attributes <|
            [ customPropertyTestData customPropertyFactory
            , customColorTestData customColorFactory
            , opacityTestData opacityFactory
            , perspectiveOriginTestData perspectiveOriginFactory
            , rotateTestData rotateFactory
            , scaleTestData scaleFactory
            , skewTestData skewFactory
            , sizeTestData sizeFactory
            , translateTestData translateFactory
            , multiPropertyTestData multiPropertyFactory
            , multiGroupTestData multiGroupFactory
            ]
