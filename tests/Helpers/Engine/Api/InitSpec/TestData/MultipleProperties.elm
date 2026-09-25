module Helpers.Engine.Api.InitSpec.TestData.MultipleProperties exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Opacity exposing (..)
import Helpers.Engine.Api.InitSpec.TestData.Translate exposing (..)


type alias MultiPropertyInitFactory builder =
    { opacity : OpacityInitFactory builder
    , translate : TranslateInitFactory builder
    }


multiPropertyTestData : MultiPropertyInitFactory (a -> a) -> TestData (a -> a)
multiPropertyTestData factory =
    { description = "Multi-Property tests"
    , testCases =
        List.map MultiPropertyTest
            [ { description = "composed init writes transform + opacity and combines will-change"
              , initFuncs =
                    [ factory.opacity.init animGroup 0.5
                    , factory.translate.initX animGroup 10
                    ]
              , expected =
                    [ NameValuePair "opacity" "0.5"
                    , NameValuePair "transform" "translateX(10px)"
                    ]
              , willChange = "opacity, transform"
              }
            ]
    }
