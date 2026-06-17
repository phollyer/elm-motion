module Anim.Internal.Engine.Sub.Animations exposing
    ( Animations
    , add
    , foldl
    , fromList
    , get
    , init
    , list
    , map
    )

import Anim.Internal.Engine.Sub.Animation exposing (Animation)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


type Animations
    = Animations (Dict PropertyName Animation)


type alias PropertyName =
    String



-- ============================================================
-- BUILD
-- ============================================================


add : Animations -> Animations -> Animations
add (Animations additional) (Animations existing) =
    Animations (Dict.union existing additional)



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Animations
init =
    Animations Dict.empty



-- ============================================================
-- QUERY
-- ============================================================


get : PropertyName -> Animations -> Maybe Animation
get key (Animations dict) =
    Dict.get key dict


list : Animations -> List Animation
list (Animations dict) =
    Dict.values dict



-- ============================================================
-- TRANSFORM
-- ============================================================


foldl : (PropertyName -> Animation -> v -> v) -> v -> Animations -> v
foldl f acc (Animations dict) =
    Dict.foldl f acc dict


fromList : List ( PropertyName, Animation ) -> Animations
fromList =
    Dict.fromList >> Animations


map : (PropertyName -> Animation -> Animation) -> Animations -> Animations
map f (Animations dict) =
    Animations (Dict.map f dict)
