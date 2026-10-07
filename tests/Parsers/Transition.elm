module Parsers.Transition exposing (parseDelay)

import Parsers.Parser exposing (parseMs)


parseDelay : String -> Maybe Int
parseDelay transitionRule =
    transitionRule
        |> String.words
        |> List.reverse
        |> List.head
        |> Maybe.andThen parseMs
