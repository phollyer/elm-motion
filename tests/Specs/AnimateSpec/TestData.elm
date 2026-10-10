module Specs.AnimateSpec.TestData exposing
    ( Animate2TestCase
    , MultiGroupTestCase
    , MultiPropertyTestCase
    , PropertyCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    , TimingProfile(..)
    , buildPropertyCase
    , buildPropertyCases
    )

import Specs.Shared exposing (NameValuePair)


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TimingProfile
    = NoTiming
    | DelayMs Int
    | DurationMs Int


type TestCase animBuilder
    = PropertyTest (PropertyTestCase animBuilder)
    | MultiPropertyTest (MultiPropertyTestCase animBuilder)
    | MultiGroupTest (MultiGroupTestCase animBuilder)
    | Animate2Test (Animate2TestCase animBuilder)


type alias PropertyTestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , propertyPipeline : animBuilder -> animBuilder
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias PropertyCase animBuilder =
    { description : String
    , propertyPipeline : animBuilder -> animBuilder
    , expected : String
    , notExpected : List String
    }


type alias MultiPropertyTestCase animBuilder =
    { description : String
    , propertyPipeline : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , animGroups : List String
    , propertyPipelines : List (List (animBuilder -> animBuilder))
    , expected : List (List NameValuePair)
    , notExpected : List (List String)
    }


type alias Animate2TestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , propertyPipeline1 : animBuilder -> animBuilder
    , propertyPipeline2 : animBuilder -> animBuilder
    , expected : List NameValuePair
    , notExpected : List String
    }


buildPropertyCases : String -> TimingProfile -> List (PropertyCase animBuilder) -> List (TestCase animBuilder)
buildPropertyCases propertyName timing =
    List.map (buildPropertyCase propertyName timing)


buildPropertyCase : String -> TimingProfile -> PropertyCase animBuilder -> TestCase animBuilder
buildPropertyCase propertyName timing c =
    PropertyTest
        { description = c.description
        , timing = timing
        , propertyPipeline = c.propertyPipeline
        , expected = [ NameValuePair propertyName c.expected ]
        , notExpected = c.notExpected
        }
