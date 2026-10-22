module Anim.Internal.Property.Shared.Discrete exposing
    ( Config
    , Entry
    , Exit
    , empty
    , firstNonEmpty
    , firstNonEmptyEntry
    , firstNonEmptyExit
    , insertEntry
    , insertExit
    , setEntry
    , setExit
    , union
    )

import Dict exposing (Dict)


type alias Config =
    { entry : Entry
    , exit : Exit
    }


type alias Entry =
    Dict String EntryProperty


type alias Exit =
    Dict String ExitProperty


type alias EntryProperty =
    String


type alias ExitProperty =
    { from : String
    , to : String
    }


empty : Config
empty =
    { entry = Dict.empty
    , exit = Dict.empty
    }


setEntry : Entry -> Config -> Config
setEntry entry config =
    { config | entry = entry }


setExit : Exit -> Config -> Config
setExit exit config =
    { config | exit = exit }


insertEntry : String -> EntryProperty -> Config -> Config
insertEntry propertyName value config =
    { config
        | entry = Dict.insert propertyName value config.entry
    }


insertExit : String -> ExitProperty -> Config -> Config
insertExit propertyName value config =
    { config
        | exit = Dict.insert propertyName value config.exit
    }


firstNonEmpty : Config -> Config -> Config
firstNonEmpty config1 config2 =
    let
        withEntryFallback =
            firstNonEmptyEntry config1 config2
    in
    firstNonEmptyExit withEntryFallback config2


firstNonEmptyEntry : Config -> Config -> Config
firstNonEmptyEntry config1 config2 =
    { config1
        | entry =
            if Dict.isEmpty config1.entry then
                config2.entry

            else
                config1.entry
    }


firstNonEmptyExit : Config -> Config -> Config
firstNonEmptyExit config1 config2 =
    { config1
        | exit =
            if Dict.isEmpty config1.exit then
                config2.exit

            else
                config1.exit
    }


union : Config -> Config -> Config
union config1 config2 =
    { entry = Dict.union config1.entry config2.entry
    , exit = Dict.union config1.exit config2.exit
    }
