module Specs.Shared.TimingProfile exposing
    ( TimingProfile(..)
    , apply
    , suffix
    )

import Factories.Engines.Factory as Factory exposing (EngineFactory)


type TimingProfile
    = NoTiming
    | DelayMs Int
    | DurationMs Int


apply : EngineFactory animBuilder animState -> TimingProfile -> (animBuilder -> animBuilder) -> (animBuilder -> animBuilder)
apply factory timing pipeline =
    let
        f =
            Factory.create factory
    in
    case timing of
        NoTiming ->
            pipeline

        DelayMs delayMs ->
            f.delay delayMs
                >> pipeline

        DurationMs durationMs ->
            f.duration durationMs
                >> pipeline


suffix : TimingProfile -> String
suffix timing =
    case timing of
        NoTiming ->
            ""

        DelayMs delayMs ->
            " [delay " ++ String.fromInt delayMs ++ "ms]"

        DurationMs durationMs ->
            " [duration " ++ String.fromInt durationMs ++ "ms]"
