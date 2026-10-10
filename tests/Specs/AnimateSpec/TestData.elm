module Specs.AnimateSpec.TestData exposing
    ( Animate2TestCase
    , MultiGroupTestCase
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
    | Animate2Test (Animate2TestCase animBuilder)


type alias PropertyTestCase animBuilder =
    { description : String
    , propertyName : String
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
    , propertyName : String
    , propertyPipeline1 : animBuilder -> animBuilder
    , propertyPipeline2 : animBuilder -> animBuilder
    , expected : List NameValuePair
    , notExpected : List String
    }
