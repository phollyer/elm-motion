module Specs.InitSpec.TestData.MultipleGroups exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup, otherAnimGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Multi-Group tests"
    , testCases =
        List.map MultiGroupTest
            [ { description = "Translate.initX and Translate.initCssUnitX are isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , initFuncs =
                    [ [ Translate.initX animGroup 10
                            >> Translate.initCssUnitX Em
                      ]
                    , [ Translate.initX otherAnimGroup 10
                            >> Translate.initCssUnitX Vmin
                      ]
                    ]
              , expected =
                    [ [ NameValuePair "transform" "translateX(10em)" ]
                    , [ NameValuePair "transform" "translateX(10vmin)" ]
                    ]
              , notExpected =
                    [ [ "translateY", "translateZ" ]
                    , [ "translateY", "translateZ" ]
                    ]
              }
            , { description = "Size.initH and Size.initCssUnitH are isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , initFuncs =
                    [ [ Size.initH animGroup 10
                            >> Size.initCssUnitH Em
                      ]
                    , [ Size.initH otherAnimGroup 10
                            >> Size.initCssUnitH Percent
                      ]
                    ]
              , expected =
                    [ [ NameValuePair "height" "10em" ]
                    , [ NameValuePair "height" "10%" ]
                    ]
              , notExpected =
                    [ [ "width" ]
                    , [ "width" ]
                    ]
              }
            , { description = "PerspectiveOrigin.initX and PerspectiveOrigin.initCssUnitX are isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , initFuncs =
                    [ [ PerspectiveOrigin.initX animGroup 10
                            >> PerspectiveOrigin.initCssUnitX Em
                      ]
                    , [ PerspectiveOrigin.initX otherAnimGroup 10
                            >> PerspectiveOrigin.initCssUnitX Vmin
                      ]
                    ]
              , expected =
                    [ [ NameValuePair "perspective-origin" "10em 50%" ]
                    , [ NameValuePair "perspective-origin" "10vmin 50%" ]
                    ]
              , notExpected = [ [], [] ]
              }
            ]
    }
