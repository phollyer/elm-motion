module Expectations.Expect exposing
    ( initialStyles
    , styles
    , transform
    , transition
    )

import Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Html
import Specs.Shared exposing (NameValuePair, attributesQueryFor)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


initialStyles : EngineFactory animBuilder animState -> String -> (String -> animState -> List (Html.Attribute msg)) -> { a | initFuncs : List (animBuilder -> animBuilder), expected : List NameValuePair } -> Expect.Expectation
initialStyles factory animGroupName attributesFunc tc =
    let
        f =
            Factory.create factory
    in
    f.init tc.initFuncs
        |> styles animGroupName attributesFunc tc


styles : String -> (String -> animState -> List (Html.Attribute msg)) -> { a | initFuncs : List (animBuilder -> animBuilder), expected : List NameValuePair } -> animState -> Expect.Expectation
styles animGroupName attributesFunc tc =
    let
        willChange =
            List.map (\nvp -> nvp.name) tc.expected
                |> String.join ", "
    in
    attributesQueryFor attributesFunc animGroupName
        >> Query.has
            (Selector.style "will-change" willChange
                :: List.map
                    (\nvp ->
                        Selector.style nvp.name nvp.value
                    )
                    tc.expected
            )


transform : String -> (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Expect.Expectation
transform =
    attributesFor "transform"


transition : String -> (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Expect.Expectation
transition =
    attributesFor "transition"


attributesFor : String -> String -> (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Expect.Expectation
attributesFor name expected attributesFunc animGroupName =
    attributesQueryFor attributesFunc animGroupName
        >> Query.has
            [ Selector.style name expected ]
