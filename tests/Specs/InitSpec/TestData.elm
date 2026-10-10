module Specs.InitSpec.TestData exposing
    ( MultiGroupTestCase
    , MultiPropertyTestCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    )

import Specs.Shared exposing (NameValuePair)


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
    , initFuncs : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    , notExpected : List String
    }


type alias MultiPropertyTestCase animBuilder =
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
