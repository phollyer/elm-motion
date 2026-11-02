module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing
    ( ExitConfig
    , ExitTestConfig
    , TestCase(..)
    , TestData
    , buildTest
    , buildTests
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


buildTests : TimingProfile -> List ExitConfig -> List TestCase
buildTests timing =
    List.map (buildTest timing)


buildTest : TimingProfile -> ExitConfig -> TestCase
buildTest timing c =
    InitTest
        { description = c.description
        , timing = timing
        , discreteProperty = c.discreteProperty
        , fromValue = c.fromValue
        , toValue = c.toValue
        }
