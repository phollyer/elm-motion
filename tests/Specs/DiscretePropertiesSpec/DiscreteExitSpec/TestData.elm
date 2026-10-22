module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing
    ( AnimateCase
    , AnimateTestCase
    , InitCase
    , InitTestCase
    , TestCase(..)
    , TestData
    , buildAnimateTest
    , buildAnimateTests
    , buildInitTest
    , buildInitTests
    )

import Specs.Shared.TimingProfile exposing (TimingProfile)


type alias TestData =
    { description : String
    , testCases : List TestCase
    }


type TestCase
    = InitTest InitTestCase
    | AnimateTest AnimateTestCase


type alias InitTestCase =
    { description : String
    , timing : TimingProfile
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


type alias InitCase =
    { description : String
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


type alias AnimateTestCase =
    { description : String
    , timing : TimingProfile
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


type alias AnimateCase =
    { description : String
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


buildInitTests : TimingProfile -> List InitCase -> List TestCase
buildInitTests timing =
    List.map (buildInitTest timing)


buildInitTest : TimingProfile -> InitCase -> TestCase
buildInitTest timing c =
    InitTest
        { description = c.description
        , timing = timing
        , discreteProperty = c.discreteProperty
        , fromValue = c.fromValue
        , toValue = c.toValue
        }


buildAnimateTests : TimingProfile -> List AnimateCase -> List TestCase
buildAnimateTests timing =
    List.map (buildAnimateTest timing)


buildAnimateTest : TimingProfile -> AnimateCase -> TestCase
buildAnimateTest timing c =
    AnimateTest
        { description = c.description
        , timing = timing
        , discreteProperty = c.discreteProperty
        , fromValue = c.fromValue
        , toValue = c.toValue
        }
