module Specs.InitSpec.TestData.Size exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Size as Size
import Anim.Unit exposing (Unit(..))
import Helpers.AnimGroups exposing (animGroup)
import Specs.InitSpec.TestData exposing (TestCase(..), TestData)
import Specs.Shared exposing (NameValuePair)


testData : TestData (AnimBuilder eng)
testData =
    { description = "Size.init* tests"
    , testCases =
        List.map PropertyTest
            [ { description = "Size.initH writes height, and omits untouched width"
              , initFuncs = [ Size.initH animGroup 10 ]
              , expected = [ NameValuePair "height" "10px" ]
              , notExpected = [ "width" ]
              }
            , { description = "Size.initW writes width, and omits untouched height"
              , initFuncs = [ Size.initW animGroup 20 ]
              , expected = [ NameValuePair "width" "20px" ]
              , notExpected = [ "height" ]
              }
            , { description = "Size.initHW writes height and width"
              , initFuncs = [ Size.initHW animGroup 10 20 ]
              , expected =
                    [ NameValuePair "width" "20px"
                    , NameValuePair "height" "10px"
                    ]
              , notExpected = []
              }
            , { description = "Size.initH with custom CSS unit writes height, and omits untouched width"
              , initFuncs =
                    [ Size.initH animGroup 10
                        >> Size.initCssUnitH Em
                    ]
              , expected = [ NameValuePair "height" "10em" ]
              , notExpected = [ "width" ]
              }
            , { description = "Size.initW with custom CSS unit writes width, and omits untouched height"
              , initFuncs =
                    [ Size.initW animGroup 10
                        >> Size.initCssUnitW Em
                    ]
              , expected = [ NameValuePair "width" "10em" ]
              , notExpected = [ "height" ]
              }
            , { description = "Size.initHW with custom CSS unit writes height and width"
              , initFuncs =
                    [ Size.initHW animGroup 10 20
                        >> Size.initCssUnit Em
                    ]
              , expected =
                    [ NameValuePair "width" "20em"
                    , NameValuePair "height" "10em"
                    ]
              , notExpected = []
              }
            , { description = "Size.initHW with custom CSS units writes height and width"
              , initFuncs =
                    [ Size.initHW animGroup 10 20
                        >> Size.initCssUnitH Em
                        >> Size.initCssUnitW Percent
                    ]
              , expected =
                    [ NameValuePair "width" "20%"
                    , NameValuePair "height" "10em"
                    ]
              , notExpected = []
              }
            , { description = "Size.initH prefers axis-specific unit when applied after general unit"
              , initFuncs =
                    [ Size.initH animGroup 10
                        >> Size.initCssUnit Em
                        >> Size.initCssUnitH Px
                    ]
              , expected = [ NameValuePair "height" "10px" ]
              , notExpected = [ "width" ]
              }
            , { description = "Size.initH uses general unit when applied after axis-specific unit"
              , initFuncs =
                    [ Size.initH animGroup 10
                        >> Size.initCssUnitH Px
                        >> Size.initCssUnit Em
                    ]
              , expected = [ NameValuePair "height" "10em" ]
              , notExpected = [ "width" ]
              }
            , { description = "Size.initH last write wins for duplicate initH calls"
              , initFuncs =
                    [ Size.initH animGroup 10
                        >> Size.initH animGroup 12
                    ]
              , expected = [ NameValuePair "height" "12px" ]
              , notExpected = [ "width" ]
              }
            ]
    }
