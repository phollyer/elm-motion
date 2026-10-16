module Specs.DelaySpec.TestData exposing
    ( EngineCase
    , EngineTestCase
    , GroupPropertyTestCase
    , MultiGroupCase
    , MultiGroupTestCase
    , MultiPropertyCase
    , MultiPropertyTestCase
    , MultiPropertyTransformOrderCase
    , MultiPropertyTransformOrderTestCase
    , PropertyCase
    , PropertyTestCase
    , TestCase(..)
    , TestData
    , buildEngineCases
    , buildMultiGroupCases
    , buildMultiPropertyCases
    , buildMultiPropertyTransformOrderCases
    , buildPropertyCases
    , groupPropertyTestCase
    , propertyTestCase
    )

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Factories.Capabilities exposing (WithTiming)
import Specs.Shared exposing (TimingProfile(..))


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
    , timing : TimingProfile
    , propertyName : String
    , delayMs : Int
    , propertyPipeline : animBuilder -> animBuilder
    }


type alias PropertyCase animBuilder =
    { description : String
    , propertyName : String
    , delayMs : Int
    , pipelineWithDelay : Int -> animBuilder -> animBuilder
    }


type alias MultiPropertyTestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , properties : List (PropertyTestCase animBuilder)
    }


type alias MultiPropertyCase animBuilder =
    { description : String
    , properties : List (PropertyTestCase animBuilder)
    }


type alias MultiPropertyTransformOrderTestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , properties : List (PropertyTestCase animBuilder)
    , transformOrder : List TransformProperty
    , expectDelay : Int
    }


type alias MultiPropertyTransformOrderCase animBuilder =
    { description : String
    , properties : List (PropertyTestCase animBuilder)
    , transformOrder : List TransformProperty
    , expectDelay : Int
    }


type alias GroupPropertyTestCase animBuilder =
    { animGroup : String
    , timing : TimingProfile
    , property : PropertyTestCase animBuilder
    }


type alias MultiGroupTestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , groups : List (GroupPropertyTestCase animBuilder)
    }


type alias MultiGroupCase animBuilder =
    { description : String
    , groups : List (GroupPropertyTestCase animBuilder)
    }


type alias EngineTestCase animBuilder =
    { description : String
    , timing : TimingProfile
    , propertyName : String
    , delayMs : Int
    , propertyPipeline : animBuilder -> animBuilder
    }


type alias EngineCase animBuilder =
    { description : String
    , propertyName : String
    , delayMs : Int
    , propertyPipeline : animBuilder -> animBuilder
    }


propertyTestCase :
    { description : String
    , propertyName : String
    , delayMs : Int
    , pipelineWithDelay : Int -> AnimBuilder (WithTiming eng) -> AnimBuilder (WithTiming eng)
    }
    -> PropertyTestCase (AnimBuilder (WithTiming eng))
propertyTestCase cfg =
    { description = cfg.description
    , timing = NoTiming
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
    , timing = NoTiming
    , property =
        propertyTestCase
            { description = cfg.description ++ " for " ++ cfg.animGroup
            , propertyName = cfg.propertyName
            , delayMs = cfg.delayMs
            , pipelineWithDelay = cfg.pipelineWithDelay
            }
    }


buildPropertyCases : TimingProfile -> List (PropertyCase (AnimBuilder (WithTiming eng))) -> List (TestCase (AnimBuilder (WithTiming eng)))
buildPropertyCases timing =
    List.map (buildPropertyCase timing)


buildPropertyCase : TimingProfile -> PropertyCase animBuilder -> TestCase animBuilder
buildPropertyCase timing c =
    PropertyTest
        { description = c.description
        , timing = timing
        , propertyName = c.propertyName
        , delayMs = c.delayMs
        , propertyPipeline = c.pipelineWithDelay c.delayMs
        }


buildMultiPropertyCases : TimingProfile -> List (MultiPropertyCase (AnimBuilder (WithTiming eng))) -> List (TestCase (AnimBuilder (WithTiming eng)))
buildMultiPropertyCases timing =
    List.map (buildMultiPropertyCase timing)


buildMultiPropertyCase : TimingProfile -> MultiPropertyCase animBuilder -> TestCase animBuilder
buildMultiPropertyCase timing c =
    MultiPropertyTest
        { description = c.description
        , properties = c.properties
        , timing = timing
        }


buildMultiPropertyTransformOrderCases : TimingProfile -> List (MultiPropertyTransformOrderCase (AnimBuilder (WithTiming eng))) -> List (TestCase (AnimBuilder (WithTiming eng)))
buildMultiPropertyTransformOrderCases timing =
    List.map (buildMultiPropertyTransformOrderCase timing)


buildMultiPropertyTransformOrderCase : TimingProfile -> MultiPropertyTransformOrderCase animBuilder -> TestCase animBuilder
buildMultiPropertyTransformOrderCase timing c =
    MultiPropertyTransformOrderTest
        { description = c.description
        , transformOrder = c.transformOrder
        , properties = c.properties
        , timing = timing
        , expectDelay = c.expectDelay
        }


buildMultiGroupCases : TimingProfile -> List (MultiGroupCase (AnimBuilder (WithTiming eng))) -> List (TestCase (AnimBuilder (WithTiming eng)))
buildMultiGroupCases timing =
    List.map (buildMultiGroupCase timing)


buildMultiGroupCase : TimingProfile -> MultiGroupCase animBuilder -> TestCase animBuilder
buildMultiGroupCase timing c =
    MultiGroupTest
        { description = c.description
        , groups = c.groups
        , timing = timing
        }


buildEngineCases : TimingProfile -> List (EngineCase (AnimBuilder (WithTiming eng))) -> List (TestCase (AnimBuilder (WithTiming eng)))
buildEngineCases timing =
    List.map (buildEngineCase timing)


buildEngineCase : TimingProfile -> EngineCase animBuilder -> TestCase animBuilder
buildEngineCase timing c =
    EngineTest
        { description = c.description
        , timing = timing
        , propertyName = c.propertyName
        , delayMs = c.delayMs
        , propertyPipeline = c.propertyPipeline
        }
