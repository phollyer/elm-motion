module Helpers.Engine.Api.InitSpec.TestData.MultipleGroups exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup, otherAnimGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.PerspectiveOrigin exposing (PerspectiveOriginInitFactory)
import Helpers.Engine.Api.InitSpec.TestData.Size exposing (SizeInitFactory)
import Helpers.Engine.Api.InitSpec.TestData.Translate exposing (TranslateInitFactory)


type alias MultiGroupInitFactory builder =
    { translate : TranslateInitFactory builder
    , size : SizeInitFactory builder
    , perspectiveOrigin : PerspectiveOriginInitFactory builder
    }


multiGroupTestData : MultiGroupInitFactory (a -> a) -> TestData (a -> a)
multiGroupTestData factory =
    { description = "Multi-Group tests"
    , testCases =
        List.map MultiGroupTest
            [ { description = "Translate init css unit is isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , initFuncs =
                    [ [ factory.translate.initX animGroup 10
                            >> factory.translate.initCssUnitX Em
                      ]
                    , [ factory.translate.initX otherAnimGroup 10 ]
                    ]
              , expected =
                    [ [ NameValuePair "transform" "translateX(10em)" ]
                    , [ NameValuePair "transform" "translateX(10px)" ]
                    ]
              , willChange = [ "transform", "transform" ]
              }
            , { description = "Size init css unit is isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , initFuncs =
                    [ [ factory.size.initH animGroup 10
                            >> factory.size.initCssUnitH Em
                      ]
                    , [ factory.size.initH otherAnimGroup 10 ]
                    ]
              , expected =
                    [ [ NameValuePair "height" "10em" ]
                    , [ NameValuePair "height" "10px" ]
                    ]
              , willChange = [ "height", "height" ]
              }
            , { description = "PerspectiveOrigin init css unit is isolated per group"
              , animGroups = [ animGroup, otherAnimGroup ]
              , initFuncs =
                    [ [ factory.perspectiveOrigin.initX animGroup 10
                            >> factory.perspectiveOrigin.initCssUnitX Em
                      ]
                    , [ factory.perspectiveOrigin.initX otherAnimGroup 10 ]
                    ]
              , expected =
                    [ [ NameValuePair "perspective-origin" "10em 50%" ]
                    , [ NameValuePair "perspective-origin" "10% 50%" ]
                    ]
              , willChange = [ "perspective-origin", "perspective-origin" ]
              }
            ]
    }
