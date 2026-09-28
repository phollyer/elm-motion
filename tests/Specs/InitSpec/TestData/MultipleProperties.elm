module Specs.InitSpec.TestData.MultipleProperties exposing (testData)

import Factories.Properties.All exposing (Factory)
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.Runner exposing (NameValuePair, TestCase(..), TestData)


testData : Factory a b c d e f g h i j -> TestData a
testData factory =
    { description = "Multi-Property tests"
    , testCases =
        List.map MultiPropertyTest
            [ { description = "composed init writes transform + opacity and combines will-change"
              , initFuncs =
                    [ factory.opacity.init animGroup 0.5
                    , factory.translate.initX animGroup 10
                    ]
              , expected =
                    [ NameValuePair "opacity" "0.5"
                    , NameValuePair "transform" "translateX(10px)"
                    ]
              , willChange = "opacity, transform"
              }
            , { description = "composed init writes translateX and skewX"
              , initFuncs =
                    [ factory.translate.initX animGroup 10
                    , factory.skew.initX animGroup 5
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) skewX(5deg)"
                    ]
              , willChange = "transform"
              }
            , { description = "composed init writes translateX, scaleX and skewX"
              , initFuncs =
                    [ factory.translate.initX animGroup 10
                    , factory.scale.initX animGroup 2
                    , factory.skew.initX animGroup 5
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) skewX(5deg) scaleX(2)"
                    ]
              , willChange = "transform"
              }
            , { description = "composed init writes translateX, rotateX, scaleX and skewX"
              , initFuncs =
                    [ factory.translate.initX animGroup 10
                    , factory.rotate.initX animGroup 15
                    , factory.scale.initX animGroup 2
                    , factory.skew.initX animGroup 0
                    ]
              , expected =
                    [ NameValuePair "transform" "translateX(10px) rotateX(15deg) skewX(0deg) scaleX(2)"
                    ]
              , willChange = "transform"
              }
            ]
    }
