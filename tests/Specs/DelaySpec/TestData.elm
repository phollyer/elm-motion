module Specs.DelaySpec.TestData exposing
    ( EngineTestCase
    , MultiPropertyTestCase
    , MultiPropertyTransformOrderTestCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    , engineCase
    , multiPropertyCase
    , multiPropertyTransformOrderCase
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
    , transformOrder : List TransformProperty
    , properties : List (PropertyTestCase animBuilder)
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


engineCase :
    { description : String
    , propertyName : String
    , delayMs : Int
    , propertyPipeline : AnimBuilder (WithTiming eng) -> AnimBuilder (WithTiming eng)
    }
    -> TestCase (AnimBuilder (WithTiming eng))
engineCase cfg =
    EngineTest
        { description = cfg.description
        , propertyName = cfg.propertyName
        , delayMs = cfg.delayMs
        , propertyPipeline = cfg.propertyPipeline
        }


multiPropertyCase :
    { description : String
    , properties : List (PropertyTestCase (AnimBuilder (WithTiming eng)))
    }
    -> TestCase (AnimBuilder (WithTiming eng))
multiPropertyCase cfg =
    MultiPropertyTest
        { description = cfg.description
        , properties = cfg.properties
        }


multiPropertyTransformOrderCase :
    { description : String
    , transformOrder : List TransformProperty
    , properties : List (PropertyTestCase (AnimBuilder (WithTiming eng)))
    }
    -> TestCase (AnimBuilder (WithTiming eng))
multiPropertyTransformOrderCase cfg =
    MultiPropertyTransformOrderTest
        { description = cfg.description
        , transformOrder = cfg.transformOrder
        , properties = cfg.properties
        }
