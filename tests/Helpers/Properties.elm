module Helpers.Properties exposing
    ( nonTransformOnly
    , toTransformOrder
    , transformOnly
    )

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformProperty(..))
import List.Extra as ListExtra
import Specs.DelaySpec.TestData exposing (PropertyTestCase)


toTransformOrder : List TransformProperty -> List (PropertyTestCase animBuilder) -> List (PropertyTestCase animBuilder)
toTransformOrder order properties =
    let
        matchedProperties transformProp_ =
            List.filter
                (\tc ->
                    let
                        maybeTransformProp =
                            case tc.propertyName of
                                "translate" ->
                                    Just Translate

                                "rotate" ->
                                    Just Rotate

                                "scale" ->
                                    Just Scale

                                "skew" ->
                                    Just Skew

                                _ ->
                                    Nothing
                    in
                    case maybeTransformProp of
                        Just prop ->
                            prop == transformProp_

                        Nothing ->
                            False
                )
                properties
                |> List.head
    in
    (order ++ TransformOrder.default)
        |> ListExtra.unique
        |> List.foldl
            (\transformProp acc ->
                case matchedProperties transformProp of
                    Just propertyTestCase ->
                        propertyTestCase :: acc

                    Nothing ->
                        acc
            )
            []
        |> List.reverse


isTransformProperty : String -> Bool
isTransformProperty propertyName =
    (propertyName == "translate")
        || (propertyName == "rotate")
        || (propertyName == "scale")
        || (propertyName == "skew")


transformOnly : List { a | propertyName : String } -> List { a | propertyName : String }
transformOnly =
    List.filter
        (isTransformProperty << .propertyName)


nonTransformOnly : List { a | propertyName : String } -> List { a | propertyName : String }
nonTransformOnly =
    List.filter
        (not << isTransformProperty << .propertyName)
