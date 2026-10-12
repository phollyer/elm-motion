module Specs.Shared exposing
    ( NameValuePair
    , TimingProfile(..)
    )


type alias NameValuePair =
    { name : String
    , value : String
    }


type TimingProfile
    = NoTiming
    | DelayMs Int
    | DurationMs Int
