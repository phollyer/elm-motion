module Specs.DelaySpec.TestData exposing
    ( EngineTestCase
    , GroupPropertyTestCase
    , MultiGroupTestCase
    , MultiPropertyTestCase
    , MultiPropertyTransformOrderTestCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    , groupPropertyTestCase
    , propertyCase
    , propertyTestCase
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Factories.Capabilities exposing (WithTiming)


type alias TestData animBuilder =
    { description : String
    , testCases : List (TestCase animBuilder)
    }


type TestCase animBuilder
    = PropertyTest (PropertyTestCase animBuilder)
    | EngineTest (EngineTestCase animBuilder)
    | MultiPropertyTest (MultiPropertyTestCase animBuilder)
    | MultiPropertyTransformOrderTest (MultiPropertyTransformOrderTestCase animBuilder)
    | MultiGroupTest (MultiGroupTestCase animBuilder)


type alias PropertyTestCase animBuilder =
    { description : String
    , propertyName : String
    , delayMs : Int
    , propertyPipeline : animBuilder -> animBuilder
    }


type alias MultiPropertyTestCase animBuilder =
    { description : String
    , properties : List (PropertyTestCase animBuilder)
    }


type alias MultiPropertyTransformOrderTestCase animBuilder =
    { description : String
    , properties : List (PropertyTestCase animBuilder)
    , transformOrder : List TransformProperty
    }


type alias GroupPropertyTestCase animBuilder =
    { animGroup : String
    , property : PropertyTestCase animBuilder
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , groups : List (GroupPropertyTestCase animBuilder)
    }


type alias EngineTestCase animBuilder =
    { description : String
    , propertyName : String
    , delayMs : Int
    , propertyPipeline : animBuilder -> animBuilder
    }


propertyCase :
    { description : String
    , propertyName : String
    , delayMs : Int
    , pipelineWithDelay : Int -> AnimBuilder (WithTiming eng) -> AnimBuilder (WithTiming eng)
    }
    -> TestCase (AnimBuilder (WithTiming eng))
propertyCase cfg =
    PropertyTest
        (propertyTestCase cfg)


propertyTestCase :
    { description : String
    , propertyName : String
    , delayMs : Int
    , pipelineWithDelay : Int -> AnimBuilder (WithTiming eng) -> AnimBuilder (WithTiming eng)
    }
    -> PropertyTestCase (AnimBuilder (WithTiming eng))
propertyTestCase cfg =
    { description = cfg.description
    , propertyName = cfg.propertyName
    , delayMs = cfg.delayMs
    , propertyPipeline = cfg.pipelineWithDelay cfg.delayMs
    }


groupPropertyTestCase :
    { description : String
    , animGroup : String
    , propertyName : String
    , delayMs : Int
    , pipelineWithDelay : Int -> AnimBuilder (WithTiming eng) -> AnimBuilder (WithTiming eng)
    }
    -> GroupPropertyTestCase (AnimBuilder (WithTiming eng))
groupPropertyTestCase cfg =
    { animGroup = cfg.animGroup
    , property =
        propertyTestCase
            { description = cfg.description ++ " for " ++ cfg.animGroup
            , propertyName = cfg.propertyName
            , delayMs = cfg.delayMs
            , pipelineWithDelay = cfg.pipelineWithDelay
            }
    }
