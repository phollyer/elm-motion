module Scroll.Internal.Shared.Container exposing
    ( Container(..)
    , toContainer
    )

-- ============================================================
-- TYPES
-- ============================================================


type Container
    = Document
    | Container ElementId


type alias ElementId =
    String



-- ============================================================
-- BUILD
-- ============================================================


toContainer : String -> Container
toContainer id =
    if id == "document" then
        Document

    else
        Container id
