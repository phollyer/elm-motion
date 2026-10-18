module Specs.ToSpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData exposing (PropertyCase, TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "the Size property writes only configured dimensions and omits untouched height/width across timing profiles"
    , testCases =
        buildPropertyCases NoTiming
            ++ buildPropertyCases (DelayMs 500)
            ++ buildPropertyCases (DurationMs 500)
            ++ buildAnimate2Cases NoTiming
            ++ buildAnimate2Cases (DelayMs 500)
            ++ buildAnimate2Cases (DurationMs 500)
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
    [ { description = "toH writes height, and omits untouched width"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.end
      , expected = "height:10px"
      , notExpected = [ "width" ]
      }
    , { description = "toW writes width, and omits untouched height"
      , propertyPipeline =
            Size.begin
                >> Size.toW 20
                >> Size.end
      , expected = "width:20px"
      , notExpected = [ "height" ]
      }
    , { description = "toHW writes height and width"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 10 20
                >> Size.end
      , expected = "width:20px;height:10px"
      , notExpected = []
      }
    , { description = "toH last write wins for multiple toH calls"
      , propertyPipeline =
            Size.begin
                >> Size.toH 10
                >> Size.toH 12
                >> Size.end
      , expected = "height:12px"
      , notExpected = [ "width" ]
      }
    , { description = "toW last write wins for multiple toW calls"
      , propertyPipeline =
            Size.begin
                >> Size.toW 20
                >> Size.toW 25
                >> Size.end
      , expected = "width:25px"
      , notExpected = [ "height" ]
      }
    , { description = "toHW last write wins for multiple toHW calls"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 10 20
                >> Size.toHW 15 25
                >> Size.end
      , expected = "width:25px;height:15px"
      , notExpected = []
      }
    , { description = "toH writes 0 for the height"
      , propertyPipeline =
            Size.begin
                >> Size.toH 0
                >> Size.end
      , expected = "height:0px"
      , notExpected = [ "width" ]
      }
    , { description = "toW writes 0 for the width"
      , propertyPipeline =
            Size.begin
                >> Size.toW 0
                >> Size.end
      , expected = "width:0px"
      , notExpected = [ "height" ]
      }
    , { description = "toHW writes 0 for both height and width"
      , propertyPipeline =
            Size.begin
                >> Size.toHW 0 0
                >> Size.end
      , expected = "width:0px;height:0px"
      , notExpected = []
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
    [ { description = "toHW then toH writes new height and keeps prior width"
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
    , { description = "toHW then toW writes new width and keeps prior height"
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
