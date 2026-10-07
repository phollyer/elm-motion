module Factories.Engines.Transition exposing
    ( Factory
    , factory
    , transitionString
    )

import Anim.Engine.Transition as Transition exposing (AnimState, EngineBuilder)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Engine.CSS.CSS as InternalCss
import Anim.Internal.Engine.CSS.Styles as InternalStyles
import Anim.Internal.Engine.Shared.AnimGroups as InternalAnimGroups
import Anim.Internal.Engine.Transition.AnimGroup as InternalAnimGroup


type alias Factory builder animState =
    { init : List (builder -> builder) -> animState
    , for : String -> (builder -> builder)
    , animate : animState -> (builder -> builder) -> animState
    , delay : Int -> builder -> builder
    , transformOrder : List TransformProperty -> builder -> builder
    , transitionString : String -> animState -> Maybe String
    , propertyString : String -> String -> Maybe String
    }


factory : Factory EngineBuilder AnimState
factory =
    { init = Transition.init
    , for = Transition.for
    , animate = Transition.animate
    , delay = Transition.delay
    , transformOrder = Transition.transformOrder
    , transitionString = transitionString
    , propertyString = propertyString
    }


transitionString : String -> AnimState -> Maybe String
transitionString animGroupName (InternalCss.AnimState _ animGroups) =
    animGroups
        |> InternalAnimGroups.get animGroupName
        |> Maybe.map InternalAnimGroup.getStyles
        |> Maybe.andThen (InternalStyles.get "transition")


propertyString : String -> String -> Maybe String
propertyString propertyName =
    String.split ","
        >> List.map String.trim
        >> List.filter (String.startsWith propertyName)
        >> List.head
