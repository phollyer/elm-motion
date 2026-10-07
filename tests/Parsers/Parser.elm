module Parsers.Parser exposing (parseMs)


parseMs : String -> Maybe Int
parseMs durationStr =
    if String.endsWith "ms" durationStr then
        durationStr
            |> String.dropRight 2
            |> String.toInt

    else
        Nothing
