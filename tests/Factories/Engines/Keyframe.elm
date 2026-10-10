module Factories.Engines.Keyframe exposing
    ( Factory
    , animationString
    , factory
    , styleDeclarations
    , styleValue
    )

import Anim.Engine.Keyframe as Keyframe exposing (AnimState, EngineBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Engine.CSS.CSS as InternalCss
import Anim.Internal.Engine.CSS.Styles as InternalStyles
import Anim.Internal.Engine.Keyframe.AnimGroup as InternalAnimGroup
import Anim.Internal.Engine.Keyframe.Animation as InternalAnimation
import Anim.Internal.Engine.Shared.AnimGroups as InternalAnimGroups
import Html


type alias Factory builder animState =
    { init : List (builder -> builder) -> animState
    , for : String -> (builder -> builder)
    , animate : animState -> (builder -> builder) -> animState
    , attributes : String -> animState -> List (Html.Attribute Never)
    , delay : Int -> builder -> builder
    , transformOrder : List TransformProperty -> builder -> builder
    , animationString : String -> animState -> Maybe String
    , keyframesString : String -> animState -> Maybe String
    , styleValue : String -> String -> animState -> Maybe String
    , styleDeclarations : String -> animState -> List String
    }


factory : Factory EngineBuilder AnimState
factory =
    { init = Keyframe.init
    , for = Keyframe.for
    , animate = Keyframe.animate
    , attributes = Keyframe.attributes
    , delay = Keyframe.delay
    , transformOrder = Keyframe.transformOrder
    , animationString = animationString
    , keyframesString = Keyframe.maybeString
    , styleValue = styleValue
    , styleDeclarations = styleDeclarations
    }


animationString : String -> AnimState -> Maybe String
animationString animGroupName (InternalCss.AnimState _ animGroups) =
    animGroups
        |> InternalAnimGroups.get animGroupName
        |> Maybe.andThen InternalAnimGroup.getAnimation
        |> Maybe.map InternalAnimation.toCssString


styleValue : String -> String -> AnimState -> Maybe String
styleValue animGroupName propertyName (InternalCss.AnimState _ animGroups) =
    animGroups
        |> InternalAnimGroups.get animGroupName
        |> Maybe.map InternalAnimGroup.getStyles
        |> Maybe.andThen (InternalStyles.get propertyName)


styleDeclarations : String -> AnimState -> List String
styleDeclarations animGroupName (InternalCss.AnimState _ animGroups) =
    animGroups
        |> InternalAnimGroups.get animGroupName
        |> Maybe.map InternalAnimGroup.getStyles
        |> Maybe.map InternalStyles.toList
        |> Maybe.withDefault []
        |> List.map (\( name, value ) -> name ++ ":" ++ value)
