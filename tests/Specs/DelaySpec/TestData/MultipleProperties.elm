module Specs.DelaySpec.TestData.MultipleProperties exposing (testData)

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Property.Custom as Custom exposing (Property(..))
import Anim.Property.CustomColor as CustomColor exposing (ColorProperty(..))
import Anim.Property.Opacity as Opacity
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Anim.Unit exposing (Unit(..))
import Factories.Capabilities exposing (WithTiming)
import Specs.DelaySpec.TestData exposing (TestData, multiPropertyCase, multiPropertyTransformOrderCase, propertyTestCase)


testData : TestData (AnimBuilder (WithTiming eng))
testData =
    { description = "Multiple property delay tests"
    , testCases =
        [ multiPropertyCase
            { description = "Non transform property delays with a duration are written correctly"
            , properties =
                [ propertyTestCase
                    { description = "a Custom font size delay is written correctly"
                    , propertyName = "font-size"
                    , delayMs = 100
                    , pipelineWithDelay =
                        \d ->
                            Custom.begin (FontSize Em)
                                >> Custom.to 1
                                >> Custom.duration 100
                                >> Custom.delay d
                                >> Custom.end
                    }
                , propertyTestCase
                    { description = "a Custom border width delay is written correctly"
                    , propertyName = "border-width"
                    , delayMs = 150
                    , pipelineWithDelay =
                        \d ->
                            Custom.begin (BorderWidth Em)
                                >> Custom.to 1
                                >> Custom.duration 100
                                >> Custom.delay d
                                >> Custom.end
                    }
                , propertyTestCase
                    { description = "a Custom border color delay is written correctly"
                    , propertyName = "border-color"
                    , delayMs = 160
                    , pipelineWithDelay =
                        \d ->
                            CustomColor.begin BorderColor
                                >> CustomColor.to (Color.rgb 255 0 0)
                                >> CustomColor.duration 100
                                >> CustomColor.delay d
                                >> CustomColor.end
                    }
                , propertyTestCase
                    { description = "a Custom font color delay is written correctly"
                    , propertyName = "color"
                    , delayMs = 170
                    , pipelineWithDelay =
                        \d ->
                            CustomColor.begin TextColor
                                >> CustomColor.to (Color.rgb 255 0 0)
                                >> CustomColor.duration 100
                                >> CustomColor.delay d
                                >> CustomColor.end
                    }
                , propertyTestCase
                    { description = "an Opacity delay is written correctly"
                    , propertyName = "opacity"
                    , delayMs = 200
                    , pipelineWithDelay =
                        \d ->
                            Opacity.begin
                                >> Opacity.to 0.5
                                >> Opacity.duration 100
                                >> Opacity.delay d
                                >> Opacity.end
                    }
                , propertyTestCase
                    { description = "a PerspectiveOrigin delay is written correctly"
                    , propertyName = "perspective-origin"
                    , delayMs = 300
                    , pipelineWithDelay =
                        \d ->
                            PerspectiveOrigin.begin
                                >> PerspectiveOrigin.toX 10
                                >> PerspectiveOrigin.duration 100
                                >> PerspectiveOrigin.delay d
                                >> PerspectiveOrigin.end
                    }
                , propertyTestCase
                    { description = "a Size (width) delay is written correctly"
                    , propertyName = "width"
                    , delayMs = 400
                    , pipelineWithDelay =
                        \d ->
                            Size.begin
                                >> Size.toW 100
                                >> Size.duration 100
                                >> Size.delay d
                                >> Size.end
                    }
                ]
            }
        , multiPropertyCase
            { description = "Translate and Scale property delays without a transform order are written correctly"
            , properties =
                [ propertyTestCase
                    { description = "a Translate delay is written correctly"
                    , propertyName = "translate"
                    , delayMs = 500
                    , pipelineWithDelay =
                        \d ->
                            Translate.begin
                                >> Translate.toX 100
                                >> Translate.delay d
                                >> Translate.end
                    }
                , propertyTestCase
                    { description = "a Scale delay is written correctly"
                    , propertyName = "scale"
                    , delayMs = 600
                    , pipelineWithDelay =
                        \d ->
                            Scale.begin
                                >> Scale.to 2
                                >> Scale.delay d
                                >> Scale.end
                    }
                ]
            }
        , multiPropertyCase
            { description = "Scale and Rotate property delays without a transform order are written correctly"
            , properties =
                [ propertyTestCase
                    { description = "a Scale delay is written correctly"
                    , propertyName = "scale"
                    , delayMs = 600
                    , pipelineWithDelay =
                        \d ->
                            Scale.begin
                                >> Scale.to 2
                                >> Scale.delay d
                                >> Scale.end
                    }
                , propertyTestCase
                    { description = "a Rotate delay is written correctly"
                    , propertyName = "rotate"
                    , delayMs = 700
                    , pipelineWithDelay =
                        \d ->
                            Rotate.begin
                                >> Rotate.toX 90
                                >> Rotate.delay d
                                >> Rotate.end
                    }
                ]
            }
        , multiPropertyTransformOrderCase
            { description = "Transform property delays with a transform order are written correctly"
            , transformOrder = [ Scale, Rotate, Translate ]
            , properties =
                [ propertyTestCase
                    { description = "a Rotate delay is written correctly"
                    , propertyName = "rotate"
                    , delayMs = 600
                    , pipelineWithDelay =
                        \d ->
                            Rotate.begin
                                >> Rotate.toX 90
                                >> Rotate.duration 100
                                >> Rotate.delay d
                                >> Rotate.end
                    }
                , propertyTestCase
                    { description = "a Scale delay is written correctly"
                    , propertyName = "scale"
                    , delayMs = 700
                    , pipelineWithDelay =
                        \d ->
                            Scale.begin
                                >> Scale.to 2
                                >> Scale.duration 100
                                >> Scale.delay d
                                >> Scale.end
                    }
                , propertyTestCase
                    { description = "a Translate delay is written correctly"
                    , propertyName = "translate"
                    , delayMs = 700
                    , pipelineWithDelay =
                        \d ->
                            Translate.begin
                                >> Translate.toX 200
                                >> Translate.duration 100
                                >> Translate.delay d
                                >> Translate.end
                    }
                ]
            }
        ]
    }
