module Specs.AnimateSpec.TestData exposing
    ( MultiGroupTestCase
    , MultiPropertyTestCase
    , PropertyCase
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
    , propertyName : String
    , propertyPipeline : animBuilder -> animBuilder
    , expected : List NameValuePair
    }


type alias PropertyCase animBuilder =
    { description : String
    , propertyPipeline : animBuilder -> animBuilder
    , expected : String
    }


type alias MultiPropertyTestCase animBuilder =
    { description : String
    , propertyPipeline : List (animBuilder -> animBuilder)
    , expected : List NameValuePair
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , animGroups : List String
    , propertyPipelines : List (List (animBuilder -> animBuilder))
    , expected : List (List NameValuePair)
    }
