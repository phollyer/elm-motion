module Specs.AnimateSpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData exposing (PropertyCase, TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Size tests"
    , testCases =
        List.map
            (\c ->
                PropertyTest
                    { description = c.description
                    , propertyName = "transform"
                    , propertyPipeline = c.propertyPipeline
                    , expected = toNameValuePairs c.expected
                    }
            )
            propertyCases
    }


toNameValuePairs : String -> List NameValuePair
toNameValuePairs str =
    str
        |> String.split ";"
        |> List.filter (\s -> s /= "")
        |> List.map
            (\s ->
                case String.split ":" s of
                    [ name, value ] ->
                        Just { name = name, value = value }

                    _ ->
                        Nothing
            )
        |> List.filterMap identity


propertyCases : List (PropertyCase (AnimBuilder eng))
propertyCases =
    [ { description = "Size.toH writes height, and omits untouched width"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.end
      , expected = "height:10px"
      }
    , { description = "Size.toW writes width, and omits untouched height"
      , propertyPipeline =
            Size.begin
                >> Size.toW 20
                >> Size.end
      , expected = "width:20px"
      }
    , { description = "Size.toHW writes height and width"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 10 20
                >> Size.end
      , expected = "width:20px;height:10px"
      }
    , { description = "Size.toH with custom CSS unit writes height, and omits untouched width"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.cssUnitH Em
                >> Size.end
      , expected = "height:10em"
      }
    , { description = "Size.toW with custom CSS unit writes width, and omits untouched height"
      , propertyPipeline =
            Size.begin
                >> Size.toW 10
                >> Size.cssUnitW Em
                >> Size.end
      , expected = "width:10em"
      }
    , { description = "Size.toHW with custom CSS unit writes height and width"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 10 20
                >> Size.cssUnit Em
                >> Size.end
      , expected = "width:20em;height:10em"
      }
    , { description = "Size.initH prefers axis-specific unit when applied after general unit"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.cssUnit Em
                >> Size.cssUnitH Px
                >> Size.end
      , expected = "height:10px"
      }
    , { description = "Size.toH uses general unit when applied after axis-specific unit"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.cssUnitH Px
                >> Size.cssUnit Em
                >> Size.end
      , expected = "height:10em"
      }
    , { description = "Size.initH last write wins for duplicate initH calls"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.toH 12
                >> Size.end
      , expected = "height:12px"
      }
    ]
