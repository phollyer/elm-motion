module Specs.Shared exposing
    ( NameValuePair
    , attributesQueryFor
    )

import Html
import Test.Html.Query as Query


type alias NameValuePair =
    { name : String
    , value : String
    }


attributesQueryFor : (String -> animState -> List (Html.Attribute msg)) -> String -> animState -> Query.Single msg
attributesQueryFor getAttributes groupName animState =
    Html.div (getAttributes groupName animState) []
        |> Query.fromHtml
