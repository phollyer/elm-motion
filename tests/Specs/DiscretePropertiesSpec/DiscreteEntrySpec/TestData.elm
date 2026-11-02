module Specs.DiscretePropertiesSpec.DiscreteEntrySpec.TestData exposing
    ( EntryConfig
    , EntryTestConfig
    , TestCase(..)
    , TestData
    , buildTests
    )

import Specs.Shared.TimingProfile exposing (TimingProfile)


type alias TestData =
    { description : String
    , testCases : List TestCase
    }


type TestCase
    = InitTest EntryTestConfig
    | AnimateTest EntryTestConfig


type alias EntryTestConfig =
    { description : String
    , timing : TimingProfile
    , discreteProperty : String
    , discreteValue : String
    }


type alias EntryConfig =
    { description : String
    , discreteProperty : String
    , discreteValue : String
    }


buildTests : TimingProfile -> List EntryConfig -> List TestCase
buildTests timing =
    List.map (buildTest timing)


buildTest : TimingProfile -> EntryConfig -> TestCase
buildTest timing c =
    InitTest
        { description = c.description
        , timing = timing
        , discreteProperty = c.discreteProperty
        , discreteValue = c.discreteValue
        }
