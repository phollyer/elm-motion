module Expectations.Expect exposing
    ( initialStyles
    , styles
    , transform
    , transition
    )

import Expect
import Factories.Engines.Factory as Factory exposing (EngineFactory(..))
import Html
import Specs.Shared exposing (NameValuePair)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


initialStyles : EngineFactory animBuilder animState -> { a | initFuncs : List (animBuilder -> animBuilder), expected : List NameValuePair } -> (String -> animState -> List (Html.Attribute msg)) -> String -> Expect.Expectation
initialStyles factory tc attributesFunc animGroupName =
    let
        f =
            Factory.create factory
    in
    f.init tc.initFuncs
        |> styles tc.expected attributesFunc animGroupName


styles : List NameValuePair -> (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Expect.Expectation
styles expected attributesFunc animGroupName =
    let
        willChange =
            List.map (\nvp -> nvp.name) expected
                |> String.join ", "
    in
    attributesQueryFor attributesFunc animGroupName
        >> Query.has
            (Selector.style "will-change" willChange
                :: List.map
                    (\nvp ->
                        Selector.style nvp.name nvp.value
                    )
                    expected
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


attributesQueryFor : (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Query.Single msg
attributesQueryFor getAttributes groupName animState =
    Html.div (getAttributes groupName animState) []
        |> Query.fromHtml
