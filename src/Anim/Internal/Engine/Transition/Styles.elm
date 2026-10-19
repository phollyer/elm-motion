module Anim.Internal.Engine.Transition.Styles exposing (fromProcessedProperties)

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.CSS.Transform as Transform
import Dict exposing (Dict)
import Set exposing (Set)


fromProcessedProperties : List TransformProperty -> Dict String (Set String) -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties transformOrder controlledAxes baseStyles =
    Styles.fromProcessedProperties (Just controlledAxes) baseStyles <|
        extractTransformStyles (Just controlledAxes) transformOrder


extractTransformStyles : Maybe (Dict String (Set String)) -> List TransformProperty -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeControlledAxes transformOrder properties =
    let
        transformParts =
            Transform.extractParts maybeControlledAxes properties
    in
    List.filterMap identity
        [ Transform.toStyle transformOrder transformParts ]
