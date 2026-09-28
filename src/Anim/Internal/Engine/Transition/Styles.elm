module Anim.Internal.Engine.Transition.Styles exposing (fromProcessedProperties, fromProcessedPropertiesWithControlledAxes)

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.CSS.Transform as Transform
import Dict exposing (Dict)
import Set exposing (Set)


fromProcessedProperties : List TransformProperty -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties maybeOrder baseStyles =
    Styles.fromProcessedProperties baseStyles <|
        extractTransformStyles Nothing maybeOrder


fromProcessedPropertiesWithControlledAxes : List TransformProperty -> Dict String (Set String) -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedPropertiesWithControlledAxes maybeOrder controlledAxes baseStyles =
    Styles.fromProcessedPropertiesWithControlledAxes (Just controlledAxes) baseStyles <|
        extractTransformStyles (Just controlledAxes) maybeOrder


extractTransformStyles : Maybe (Dict String (Set String)) -> List TransformProperty -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeControlledAxes maybeOrder properties =
    let
        transformParts =
            Transform.extractParts maybeControlledAxes properties
    in
    List.filterMap identity
        [ Transform.toStyle maybeOrder transformParts ]
