module Anim.Internal.Builder.CssUnitStore exposing
    ( Store
    , empty
    , get
    , getAxes
    , perspectiveOriginX
    , perspectiveOriginY
    , set
    , setAll
    , sizeHeight
    , sizeWidth
    , translateX
    , translateY
    , translateZ
    )

{-| Per-group CSS unit overrides keyed by `(animGroupName, slot)`. Slots are
opaque strings (one per axis or named dimension) — property modules look them
up by the constants exposed below rather than raw strings.

The store is populated by `init*` followed by `cssUnit*` calls in each
property module's pipeline; consumed by `processProperty` and baseline
extraction at render time so the same `Engine.init` list is order-independent
within a property's own chain.

-}

import Anim.Internal.Unit as InternalUnit
import Anim.Unit exposing (Unit)
import Dict exposing (Dict)


type alias Store =
    Dict ( String, String ) Unit


empty : Store
empty =
    Dict.empty



-- SLOTS


translateX : String
translateX =
    "translate.x"


translateY : String
translateY =
    "translate.y"


translateZ : String
translateZ =
    "translate.z"


sizeWidth : String
sizeWidth =
    "size.width"


sizeHeight : String
sizeHeight =
    "size.height"


perspectiveOriginX : String
perspectiveOriginX =
    "perspectiveOrigin.x"


perspectiveOriginY : String
perspectiveOriginY =
    "perspectiveOrigin.y"



-- OPS


set : String -> String -> Unit -> Store -> Store
set group slot unit =
    Dict.insert ( group, slot ) unit


setAll : String -> List String -> Unit -> Store -> Store
setAll group slots unit store =
    List.foldl (\s -> set group s unit) store slots


get : String -> String -> Store -> Maybe Unit
get group slot =
    Dict.get ( group, slot )


{-| Read a property's three axes from the store as a `CssUnitAxes`. Slots
that aren't present become `Nothing` axes — leaving them eligible for engine
defaults to fill at resolution time.
-}
getAxes : String -> { x : String, y : String, z : String } -> Store -> InternalUnit.CssUnitAxes
getAxes group slots store =
    { x = get group slots.x store
    , y = get group slots.y store
    , z = get group slots.z store
    }
