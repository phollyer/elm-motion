module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing
    ( ExitConfig
    , ExitTestConfig
    , TestCase(..)
    , TestData
    , buildAnimate2Tests
    , buildAnimateCompleteAnimateTests
    , buildAnimateCompleteTests
    , buildAnimateTests
    , buildInitTests
    )

import Specs.Shared.TimingProfile exposing (TimingProfile)


type alias TestData =
    { description : String
    , testCases : List TestCase
    }


type TestCase
    = InitTest ExitTestConfig
    | AnimateTest ExitTestConfig
    | AnimateCompleteTest ExitTestConfig
    | Animate2Test ExitTestConfig
    | AnimateCompleteAnimateTest ExitTestConfig


type alias ExitTestConfig =
    { description : String
    , timing : TimingProfile
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


type alias ExitConfig =
    { description : String
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


buildInitTests : TimingProfile -> List ExitConfig -> List TestCase
buildInitTests timing =
    buildTests timing InitTest


buildAnimateTests : TimingProfile -> List ExitConfig -> List TestCase
buildAnimateTests timing =
    buildTests timing AnimateTest


buildAnimateCompleteTests : TimingProfile -> List ExitConfig -> List TestCase
buildAnimateCompleteTests timing =
    buildTests timing AnimateCompleteTest


buildAnimate2Tests : TimingProfile -> List ExitConfig -> List TestCase
buildAnimate2Tests timing =
    buildTests timing Animate2Test


buildAnimateCompleteAnimateTests : TimingProfile -> List ExitConfig -> List TestCase
buildAnimateCompleteAnimateTests timing =
    buildTests timing AnimateCompleteAnimateTest


buildTests : TimingProfile -> (ExitTestConfig -> TestCase) -> List ExitConfig -> List TestCase
buildTests timing toTestCase =
    List.map
        (\c ->
            toTestCase
                { description = c.description
                , timing = timing
                , discreteProperty = c.discreteProperty
                , fromValue = c.fromValue
                , toValue = c.toValue
                }
        )
