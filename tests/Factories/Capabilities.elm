module Factories.Capabilities exposing
    ( WithBounds
    , WithLiveDelta
    , WithSpring
    , WithTiming
    )


type alias WithBounds eng =
    { eng | withBounds : () }


type alias WithLiveDelta eng =
    { eng | withLiveDelta : () }


type alias WithSpring eng =
    { eng | withSpring : () }


type alias WithTiming eng =
    { eng | withTiming : () }
