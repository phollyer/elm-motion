module Specs.DelaySpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestData, engineCase, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Translate.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 100
            , buildAnimate =
                \d ->
                    Translate.begin
                        >> Translate.toX 10
                        >> Translate.duration 100
                        >> Translate.delay d
                        >> Translate.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 200
            , buildAnimate =
                \d ->
                    Translate.begin
                        >> Translate.toX 10
                        >> Translate.delay d
                        >> Translate.end
            }
        , engineCase
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 300
            , animateFuncs =
                Translate.begin
                    >> Translate.toX 10
                    >> Translate.end
            }
        , engineCase
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 400
            , animateFuncs =
                Translate.begin
                    >> Translate.toX 10
                    >> Translate.duration 1000
                    >> Translate.end
            }
        ]
    }
