module Specs.DelaySpec.TestData.Translate exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.Runner exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Translate.delay tests"
    , testCases =
        [ PropertyTest
            { description = "a local delay is preserved when no duration is supplied"
            , animateFuncs =
                Translate.begin
                    >> Translate.toX 120
                    >> Translate.delay 1000
                    >> Translate.end
            , transitionExpected = NameValuePair "transition" "transform 0ms ease-in-out 1000ms"
            , keyframeExpected = "1000ms"
            }
        , EngineTest
            { description = "a global delay is preserved when no duration is supplied"
            , animateFuncs =
                Translate.begin
                    >> Translate.toX 120
                    >> Translate.end
            , delayMs = 1000
            , transitionExpected = NameValuePair "transition" "transform 0ms ease-in-out 1000ms"
            , keyframeExpected = "1000ms"
            }
        ]
    }
