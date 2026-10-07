module Specs.DelaySpec.TestData.Rotate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Rotate as Rotate
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestData, engineCase, propertyCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Rotate.delay tests"
    , testCases =
        [ propertyCase
            { description = "a property delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 100
            , buildAnimate =
                \d ->
                    Rotate.begin
                        >> Rotate.toX 10
                        >> Rotate.duration 100
                        >> Rotate.delay d
                        >> Rotate.end
            }
        , propertyCase
            { description = "a property delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 200
            , buildAnimate =
                \d ->
                    Rotate.begin
                        >> Rotate.toY 20
                        >> Rotate.delay d
                        >> Rotate.end
            }
        , engineCase
            { description = "an engine delay with no duration is written correctly"
            , propertyName = "transform"
            , delayMs = 300
            , animateFuncs =
                Rotate.begin
                    >> Rotate.toZ 30
                    >> Rotate.end
            }
        , engineCase
            { description = "an engine delay with a duration is written correctly"
            , propertyName = "transform"
            , delayMs = 400
            , animateFuncs =
                Rotate.begin
                    >> Rotate.toXY 10 20
                    >> Rotate.duration 1000
                    >> Rotate.end
            }
        ]
    }
