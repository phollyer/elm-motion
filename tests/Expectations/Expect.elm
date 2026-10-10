module Expectations.Expect exposing
    ( initialStyles
    , styles
    , stylesNotPresent
    , transform
    , transition
    , willChange
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
        |> Expect.all
            [ \s -> styles tc.expected attributesFunc animGroupName s
            , \s -> willChange tc.expected attributesFunc animGroupName s
            ]


styles : List NameValuePair -> (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Expect.Expectation
styles expected attributesFunc animGroupName =
    attributesQueryFor attributesFunc animGroupName
        >> Query.has
            (List.map
                (\nvp ->
                    Selector.style nvp.name nvp.value
                )
                expected
            )


stylesNotPresent : List String -> (String -> animState -> List String) -> String -> animState -> Expect.Expectation
stylesNotPresent notExpected getStyleDeclarations animGroupName animState =
    if List.isEmpty notExpected then
        Expect.pass

    else
        let
            declarations =
                getStyleDeclarations animGroupName animState
        in
        notExpected
            |> List.map
                (\token ->
                    \_ ->
                        case List.filter (String.contains token) declarations |> List.head of
                            Nothing ->
                                Expect.pass

                            Just decl ->
                                Expect.fail ("Expected style output not to contain: " ++ token ++ ", but got declaration: " ++ decl)
                )
            |> (\expectations ->
                    Expect.all expectations ()
               )


willChange : List NameValuePair -> (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Expect.Expectation
willChange expected attributesFunc animGroupName =
    let
        willChange_ =
            List.map (\nvp -> nvp.name) expected
                |> String.join ", "
    in
    attributesQueryFor attributesFunc animGroupName
        >> Query.has
            [ Selector.style "will-change" willChange_ ]


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
