module Helpers.Engine.Api.InitSpec.TestData.Size exposing (..)

import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Helpers.Engine.Api.InitSpec.Runner exposing (..)


type alias SizeInitFactory builder =
    { initH : String -> Float -> builder
    , initW : String -> Float -> builder
    , initHW : String -> Float -> Float -> builder
    , initCssUnitH : Unit -> builder
    , initCssUnitW : Unit -> builder
    , initCssUnit : Unit -> builder
    }


sizeTestData : SizeInitFactory (a -> a) -> TestData (a -> a)
sizeTestData factory =
    { description = "Size.init* tests"
    , testCases =
        List.map SizeTest
            [ { description = "Size.initH writes height, and omits untouched width"
              , initFuncs = factory.initH animGroup 10
              , expectedHeight = Just "10px"
              , expectedWidth = Nothing
              , willChange = "height"
              }
            , { description = "Size.initW writes width, and omits untouched height"
              , initFuncs = factory.initW animGroup 20
              , expectedHeight = Nothing
              , expectedWidth = Just "20px"
              , willChange = "width"
              }
            , { description = "Size.initHW writes height and width"
              , initFuncs = factory.initHW animGroup 10 20
              , expectedHeight = Just "10px"
              , expectedWidth = Just "20px"
              , willChange = "width, height"
              }
            , { description = "Size.initH with custom CSS unit writes height, and omits untouched width"
              , initFuncs =
                    factory.initH animGroup 10
                        >> factory.initCssUnitH Em
              , expectedHeight = Just "10em"
              , expectedWidth = Nothing
              , willChange = "height"
              }
            , { description = "Size.initW with custom CSS unit writes width, and omits untouched height"
              , initFuncs =
                    factory.initW animGroup 10
                        >> factory.initCssUnitW Em
              , expectedHeight = Nothing
              , expectedWidth = Just "10em"
              , willChange = "width"
              }
            , { description = "Size.initHW with custom CSS unit writes height and width"
              , initFuncs =
                    factory.initHW animGroup 10 20
                        >> factory.initCssUnit Em
              , expectedHeight = Just "10em"
              , expectedWidth = Just "20em"
              , willChange = "width, height"
              }
            , { description = "Size.initH prefers axis-specific unit when applied after global unit"
              , initFuncs =
                    factory.initH animGroup 10
                        >> factory.initCssUnit Em
                        >> factory.initCssUnitH Px
              , expectedHeight = Just "10px"
              , expectedWidth = Nothing
              , willChange = "height"
              }
            , { description = "Size.initH uses global unit when applied after axis-specific unit"
              , initFuncs =
                    factory.initH animGroup 10
                        >> factory.initCssUnitH Px
                        >> factory.initCssUnit Em
              , expectedHeight = Just "10em"
              , expectedWidth = Nothing
              , willChange = "height"
              }
            , { description = "Size.initH last write wins for duplicate initH calls"
              , initFuncs =
                    factory.initH animGroup 10
                        >> factory.initH animGroup 12
              , expectedHeight = Just "12px"
              , expectedWidth = Nothing
              , willChange = "height"
              }
            ]
    }
