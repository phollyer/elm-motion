module Specs.TransformOrderSpec.TestData exposing
    ( AnimateTestCase
    , InitTestCase
    , TestCase(..)
    , TestData
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TestCase animBuilder
    = InitTest (InitTestCase animBuilder)
    | AnimateTest (AnimateTestCase animBuilder)


type alias InitTestCase animBuilder =
    { description : String
    , initFuncs : List (animBuilder -> animBuilder)
    , expected : String
    }


type alias AnimateTestCase animBuilder =
    { description : String
    , animateFuncs : animBuilder -> animBuilder
    , transformOrder : List TransformProperty
    , expected : String
    }
