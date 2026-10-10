module Specs.AnimateSpec.TestData.MultipleGroups exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.AnimateSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Multi-Group tests"
    , testCases =
        List.map MultiGroupTest
            [ { description = "Translate.animate and css unit is isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , propertyPipelines =
                    [ [ Translate.begin
                            >> Translate.toX 10
                            >> Translate.cssUnitX Em
                            >> Translate.end
                      ]
                    , [ Translate.begin
                            >> Translate.toZ 10
                            >> Translate.end
                      ]
                    ]
              , expected =
                    [ [ NameValuePair "transform" "translateX(10em)" ]
                    , [ NameValuePair "transform" "translateZ(10px)" ]
                    ]
              , notExpected =
                    [ [ "translateY", "translateZ" ]
                    , [ "translateX", "translateY" ]
                    ]
              }
            , { description = "Size.animate and css unit is isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , propertyPipelines =
                    [ [ Size.begin
                            >> Size.toH 10
                            >> Size.cssUnitH Em
                            >> Size.end
                      ]
                    , [ Size.begin
                            >> Size.toW 10
                            >> Size.end
                      ]
                    ]
              , expected =
                    [ [ NameValuePair "height" "10em" ]
                    , [ NameValuePair "width" "10px" ]
                    ]
              , notExpected =
                    [ [ "width" ]
                    , [ "height" ]
                    ]
              }
            , { description = "PerspectiveOrigin.animate and css unit is isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , propertyPipelines =
                    [ [ PerspectiveOrigin.begin
                            >> PerspectiveOrigin.toX 10
                            >> PerspectiveOrigin.cssUnitX Em
                            >> PerspectiveOrigin.end
                      ]
                    , [ PerspectiveOrigin.begin
                            >> PerspectiveOrigin.toX 10
                            >> PerspectiveOrigin.end
                      ]
                    ]
              , expected =
                    [ [ NameValuePair "perspective-origin" "10em 50%" ]
                    , [ NameValuePair "perspective-origin" "10% 50%" ]
                    ]
              , notExpected = [ [], [] ]
              }
            ]
    }
