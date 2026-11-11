module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing
    ( ExitConfig
    , ExitIsolationConfig
    , ExitIsolationTestConfig
    , ExitTestConfig
    , TestCase(..)
    , TestData
    , buildAnimateIsolationTests
    , buildAnimate2Tests
    , buildAnimateCompleteAnimateTests
    , buildAnimateCompleteTests
    , buildAnimateTests
    , buildInitTests
    , buildNoOpAfterCompleteTests
    , buildRetargetIsolationTests
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
    | AnimateIsolationTest ExitIsolationTestConfig
    | RetargetIsolationTest ExitIsolationTestConfig
    | NoOpAfterCompleteTest ExitIsolationTestConfig


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


type alias ExitIsolationTestConfig =
    { description : String
    , timing : TimingProfile
    , subjectGroup : String
    , bystanderGroup : String
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


type alias ExitIsolationConfig =
    { description : String
    , subjectGroup : String
    , bystanderGroup : String
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


buildAnimateIsolationTests : TimingProfile -> List ExitIsolationConfig -> List TestCase
buildAnimateIsolationTests timing =
    buildIsolationTests timing AnimateIsolationTest


buildRetargetIsolationTests : TimingProfile -> List ExitIsolationConfig -> List TestCase
buildRetargetIsolationTests timing =
    buildIsolationTests timing RetargetIsolationTest


buildNoOpAfterCompleteTests : TimingProfile -> List ExitIsolationConfig -> List TestCase
buildNoOpAfterCompleteTests timing =
    buildIsolationTests timing NoOpAfterCompleteTest


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


buildIsolationTests : TimingProfile -> (ExitIsolationTestConfig -> TestCase) -> List ExitIsolationConfig -> List TestCase
buildIsolationTests timing toTestCase =
    List.map
        (\c ->
            toTestCase
                { description = c.description
                , timing = timing
                , subjectGroup = c.subjectGroup
                , bystanderGroup = c.bystanderGroup
                , discreteProperty = c.discreteProperty
                , fromValue = c.fromValue
                , toValue = c.toValue
                }
        )
