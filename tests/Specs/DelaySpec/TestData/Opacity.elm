module Specs.DelaySpec.TestData.Opacity exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.Runner exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Opacity.delay tests"
    , testCases =
        [ PropertyTest
            { description = "a local delay is preserved when no duration is supplied"
            , animateFuncs =
                Opacity.begin
                    >> Opacity.to 0.4
                    >> Opacity.delay 1000
                    >> Opacity.end
            , transitionExpected = NameValuePair "transition" "opacity 0ms ease-in-out 1000ms"
            , keyframeExpected = "1000ms"
            }
        , EngineTest
            { description = "a global delay is preserved when no duration is supplied"
            , animateFuncs =
                Opacity.begin
                    >> Opacity.to 0.4
                    >> Opacity.end
            , delayMs = 1000
            , transitionExpected = NameValuePair "transition" "opacity 0ms ease-in-out 1000ms"
            , keyframeExpected = "1000ms"
            }
        ]
    }
