module Specs.AnimateSpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Anim.Unit exposing (Unit(..))
import Specs.AnimateSpec.TestData exposing (PropertyCase, TestCase(..), TestData, TimingProfile(..))
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Size tests"
    , testCases =
        buildPropertyCases NoTiming
            ++ buildPropertyCases (DelayMs 500)
            ++ buildAnimate2Cases NoTiming
            ++ buildAnimate2Cases (DelayMs 500)
    }


buildPropertyCases : TimingProfile -> List (TestCase (AnimBuilder eng))
buildPropertyCases timing =
    List.map
        (\c ->
            PropertyTest
                { description = c.description
                , timing = timing
                , propertyPipeline = c.propertyPipeline
                , expected = toNameValuePairs c.expected
                , notExpected = c.notExpected
                }
        )
        propertyCases


buildAnimate2Cases : TimingProfile -> List (TestCase (AnimBuilder eng))
buildAnimate2Cases timing =
    List.map
        (\c ->
            Animate2Test
                { description = c.description
                , timing = timing
                , propertyPipeline1 = c.propertyPipeline1
                , propertyPipeline2 = c.propertyPipeline2
                , expected = toNameValuePairs c.expected
                , notExpected = c.notExpected
                }
        )
        animate2Cases


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
      , notExpected = [ "width" ]
      }
    , { description = "Size.toW writes width, and omits untouched height"
      , propertyPipeline =
            Size.begin
                >> Size.toW 20
                >> Size.end
      , expected = "width:20px"
      , notExpected = [ "height" ]
      }
    , { description = "Size.toHW writes height and width"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 10 20
                >> Size.end
      , expected = "width:20px;height:10px"
      , notExpected = []
      }
    , { description = "Size.toH with custom CSS unit writes height, and omits untouched width"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.cssUnitH Em
                >> Size.end
      , expected = "height:10em"
      , notExpected = [ "width" ]
      }
    , { description = "Size.toW with custom CSS unit writes width, and omits untouched height"
      , propertyPipeline =
            Size.begin
                >> Size.toW 10
                >> Size.cssUnitW Em
                >> Size.end
      , expected = "width:10em"
      , notExpected = [ "height" ]
      }
    , { description = "Size.toHW with custom CSS unit writes height and width"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 10 20
                >> Size.cssUnit Em
                >> Size.end
      , expected = "width:20em;height:10em"
      , notExpected = []
      }
    , { description = "Size.toH prefers axis-specific unit when applied after general unit"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.cssUnit Em
                >> Size.cssUnitH Px
                >> Size.end
      , expected = "height:10px"
      , notExpected = [ "width" ]
      }
    , { description = "Size.toH uses general unit when applied after axis-specific unit"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.cssUnitH Px
                >> Size.cssUnit Em
                >> Size.end
      , expected = "height:10em"
      , notExpected = [ "width" ]
      }
    , { description = "Size.toH last write wins for duplicate toH calls"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.toH 12
                >> Size.end
      , expected = "height:12px"
      , notExpected = [ "width" ]
      }
    ]


type alias Animate2Case animBuilder =
    { description : String
    , propertyPipeline1 : animBuilder -> animBuilder
    , propertyPipeline2 : animBuilder -> animBuilder
    , expected : String
    , notExpected : List String
    }


animate2Cases : List (Animate2Case (AnimBuilder eng))
animate2Cases =
    [ { description = "Size.toHW then Size.toH writes new height and keeps prior width"
      , propertyPipeline1 =
            Size.begin
                >> Size.toHW 10 20
                >> Size.end
      , propertyPipeline2 =
            Size.begin
                >> Size.toH 30
                >> Size.end
      , expected = "width:20px;height:30px"
      , notExpected = []
      }
    , { description = "Size.toHW then Size.toW writes new width and keeps prior height"
      , propertyPipeline1 =
            Size.begin
                >> Size.toHW 10 20
                >> Size.end
      , propertyPipeline2 =
            Size.begin
                >> Size.toW 30
                >> Size.end
      , expected = "width:30px;height:10px"
      , notExpected = []
      }
    ]
