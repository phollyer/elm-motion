module Specs.DelaySpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.Runner exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Size.delay tests"
    , testCases =
        [ PropertyTest
            { description = "a local delay is preserved when no duration is supplied"
            , animateFuncs =
                Size.begin
                    >> Size.toH 120
                    >> Size.delay 1000
                    >> Size.end
            , transitionExpected = NameValuePair "transition" "height 0ms ease-in-out 1000ms"
            , keyframeExpected = "1000ms"
            }
        , EngineTest
            { description = "a global delay is preserved when no duration is supplied"
            , animateFuncs =
                Size.begin
                    >> Size.toH 120
                    >> Size.end
            , delayMs = 1000
            , transitionExpected = NameValuePair "transition" "height 0ms ease-in-out 1000ms"
            , keyframeExpected = "1000ms"
            }
        ]
    }
