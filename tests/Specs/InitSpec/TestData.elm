module Specs.InitSpec.TestData exposing
    ( InitTestCase
    , MultiGroupTestCase
    , TestCase(..)
    , TestData
    )

import Specs.Shared exposing (NameValuePair)


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TestCase animBuilder
    = PropertyTest (InitTestCase animBuilder)
    | MultiPropertyTest (InitTestCase animBuilder)
    | MultiGroupTest (MultiGroupTestCase animBuilder)


type alias InitTestCase animBuilder =
    { description : String
    , initFuncs : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , animGroups : List String
    , initFuncs : List (List (animBuilder -> animBuilder))
    , expected : List (List NameValuePair)
    , notExpected : List (List String)
    }
