module Specs.ToSpec.TestData.MultipleGroups exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Helpers.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.Shared exposing (NameValuePair)
import Specs.Shared.TimingProfile exposing (TimingProfile(..))
import Specs.ToSpec.TestData as TD exposing (MultiGroupCase, TestCase(..), TestData)


testData : TestData (AnimBuilder eng)
testData =
    { description = "multiple groups keep their own styles across timing profiles"
    , testCases =
        TD.buildMultiGroupCases NoTiming multiGroupCases
            ++ TD.buildMultiGroupCases (DelayMs 500) multiGroupCases
            ++ TD.buildMultiGroupCases (DurationMs 500) multiGroupCases
    }


multiGroupCases : List (MultiGroupCase (AnimBuilder eng))
multiGroupCases =
    [ { description = "Translate axes are isolated per group"
      , animGroups = [ animGroup, otherAnimGroup ]
      , propertyPipelines =
            [ [ Translate.begin
                    >> Translate.toX 10
                    >> Translate.end
              ]
            , [ Translate.begin
                    >> Translate.toZ 10
                    >> Translate.end
              ]
            ]
      , expected =
            [ [ NameValuePair "transform" "translateX(10px)" ]
            , [ NameValuePair "transform" "translateZ(10px)" ]
            ]
      , notExpected =
            [ [ "translateY", "translateZ" ]
            , [ "translateX", "translateY" ]
            ]
      }
    , { description = "Size axes are isolated per group"
      , animGroups = [ animGroup, otherAnimGroup ]
      , propertyPipelines =
            [ [ Size.begin
                    >> Size.toH 10
                    >> Size.end
              ]
            , [ Size.begin
                    >> Size.toW 10
                    >> Size.end
              ]
            ]
      , expected =
            [ [ NameValuePair "height" "10px" ]
            , [ NameValuePair "width" "10px" ]
            ]
      , notExpected =
            [ [ "width" ]
            , [ "height" ]
            ]
      }
    , { description = "PerspectiveOrigin axes are isolated per group"
      , animGroups = [ animGroup, otherAnimGroup ]
      , propertyPipelines =
            [ [ PerspectiveOrigin.begin
                    >> PerspectiveOrigin.toX 10
                    >> PerspectiveOrigin.end
              ]
            , [ PerspectiveOrigin.begin
                    >> PerspectiveOrigin.toY 10
                    >> PerspectiveOrigin.end
              ]
            ]
      , expected =
            [ [ NameValuePair "perspective-origin" "10% 50%" ]
            , [ NameValuePair "perspective-origin" "50% 10%" ]
            ]
      , notExpected = [ [], [] ]
      }
    , { description = "Opacity and Rotate are isolated per group"
      , animGroups = [ animGroup, otherAnimGroup ]
      , propertyPipelines =
            [ [ Opacity.begin
                    >> Opacity.to 0.5
                    >> Opacity.end
              ]
            , [ Rotate.begin
                    >> Rotate.toX 45
                    >> Rotate.end
              ]
            ]
      , expected =
            [ [ NameValuePair "opacity" "0.5" ]
            , [ NameValuePair "transform" "rotateX(45deg)" ]
            ]
      , notExpected =
            [ [ "transform" ]
            , [ "opacity" ]
            ]
      }
    ]
