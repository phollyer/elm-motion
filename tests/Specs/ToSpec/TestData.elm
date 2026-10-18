module Specs.ToSpec.TestData exposing
    ( Animate2TestCase
    , MultiGroupCase
    , MultiGroupTestCase
    , MultiPropertyCase
    , MultiPropertyTestCase
    , PropertyCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    , buildMultiGroupCases
    , buildMultiPropertyCases
    , buildPropertyCase
    , buildPropertyCases
    )

import Specs.Shared exposing (NameValuePair)
import Specs.Shared.TimingProfile exposing (TimingProfile)


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


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
    , timing : TimingProfile
    , propertyPipeline : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiPropertyCase animBuilder =
    { description : String
    , propertyPipeline : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , animGroups : List String
    , propertyPipelines : List (List (animBuilder -> animBuilder))
    , expected : List (List NameValuePair)
    , notExpected : List (List String)
    }


type alias MultiGroupCase animBuilder =
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


buildMultiPropertyCases : TimingProfile -> List (MultiPropertyCase animBuilder) -> List (TestCase animBuilder)
buildMultiPropertyCases timing =
    List.map (buildMultiPropertyCase timing)


buildMultiPropertyCase : TimingProfile -> MultiPropertyCase animBuilder -> TestCase animBuilder
buildMultiPropertyCase timing c =
    MultiPropertyTest
        { description = c.description
        , timing = timing
        , propertyPipeline = c.propertyPipeline
        , expected = c.expected
        , notExpected = c.notExpected
        }


buildMultiGroupCases : TimingProfile -> List (MultiGroupCase animBuilder) -> List (TestCase animBuilder)
buildMultiGroupCases timing =
    List.map (buildMultiGroupCase timing)


buildMultiGroupCase : TimingProfile -> MultiGroupCase animBuilder -> TestCase animBuilder
buildMultiGroupCase timing c =
    MultiGroupTest
        { description = c.description
        , timing = timing
        , animGroups = c.animGroups
        , propertyPipelines = c.propertyPipelines
        , expected = c.expected
        , notExpected = c.notExpected
        }
