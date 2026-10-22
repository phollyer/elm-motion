module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing
    ( AnimateCase
    , AnimateCompleteCase
    , AnimateCompleteTestCase
    , AnimateTestCase
    , InitCase
    , InitTestCase
    , TestCase(..)
    , TestData
    , buildAnimateCompleteTest
    , buildAnimateCompleteTests
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
    | AnimateCompleteTest AnimateCompleteTestCase


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


type alias AnimateCompleteTestCase =
    { description : String
    , timing : TimingProfile
    , discreteProperty : String
    , fromValue : String
    , toValue : String
    }


type alias AnimateCompleteCase =
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


buildAnimateCompleteTests : TimingProfile -> List AnimateCompleteCase -> List TestCase
buildAnimateCompleteTests timing =
    List.map (buildAnimateCompleteTest timing)


buildAnimateCompleteTest : TimingProfile -> AnimateCompleteCase -> TestCase
buildAnimateCompleteTest timing c =
    AnimateCompleteTest
        { description = c.description
        , timing = timing
        , discreteProperty = c.discreteProperty
        , fromValue = c.fromValue
        , toValue = c.toValue
        }
