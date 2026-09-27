module Factories.Capabilities exposing
    ( WithLiveDelta
    , WithSpring
    , WithTiming
    )


type alias WithLiveDelta eng =
    { eng | withLiveDelta : () }


type alias WithSpring eng =
    { eng | withSpring : () }


type alias WithTiming eng =
    { eng | withTiming : () }
