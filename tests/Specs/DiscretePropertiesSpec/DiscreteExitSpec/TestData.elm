module Specs.DiscretePropertiesSpec.DiscreteExitSpec.TestData exposing
    ( DiscreteOps
    , MultiGroupTestCase
    , MultiPropertyTestCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    )

import Specs.Shared exposing (NameValuePair)


type alias DiscreteOps animBuilder =
    { for : String -> animBuilder -> animBuilder
    , discreteEntry : String -> String -> animBuilder -> animBuilder
    , discreteExit : String -> String -> String -> animBuilder -> animBuilder
    }


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TestCase animBuilder
    = PropertyTest (PropertyTestCase animBuilder)
    | MultiPropertyTest (MultiPropertyTestCase animBuilder)
    | MultiGroupTest (MultiGroupTestCase animBuilder)


type alias PropertyTestCase animBuilder =
    { description : String
    , animGroup : String
    , initFuncs : List (DiscreteOps animBuilder -> animBuilder -> animBuilder)
    , propertyPipeline : DiscreteOps animBuilder -> animBuilder -> animBuilder
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiPropertyTestCase animBuilder =
    { description : String
    , animGroup : String
    , initFuncs : List (DiscreteOps animBuilder -> animBuilder -> animBuilder)
    , propertyPipelines : List (DiscreteOps animBuilder -> animBuilder -> animBuilder)
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , animGroups : List String
    , initFuncs : List (DiscreteOps animBuilder -> animBuilder -> animBuilder)
    , propertyPipelines : List (List (DiscreteOps animBuilder -> animBuilder -> animBuilder))
    , expected : List (List NameValuePair)
    , notExpected : List (List String)
    }
