module Anim.Internal.Engine.ScrollTimeline exposing
    ( AnimEvent(..)
    , AnimMsg(..)
    , EngineBuilder
    , alternate
    , animate
    , attributes
    , cssUnit
    , cssUnitX
    , cssUnitY
    , cssUnitZ
    , discreteEntry
    , discreteExit
    , easing
    , horizontal
    , iterations
    , spring
    , subscriptions
    , transformOrder
    , update
    , withProgressEvents
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Engine.WAAPI.Timeline as Timeline
import Anim.Unit exposing (Unit)
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type AnimMsg
    = JavascriptUpdate Decode.Value
    | Ignored


type alias AnimGroupName =
    String


type alias EngineBuilder =
    Builder.AnimBuilder Builder.ForScroll



-- ============================================================
-- TRIGGER
-- ============================================================


animate : (a -> String) -> (Encode.Value -> Cmd msg) -> a -> (EngineBuilder -> EngineBuilder) -> Cmd msg
animate containerToId sendToPort container pipeline =
    Builder.init [ pipeline ]
        |> Builder.setScrollSource (containerToId container)
        |> Encoder.encodeScroll
        |> sendToPort



-- ============================================================
-- EVENTS
-- ============================================================


type AnimEvent
    = Run AnimGroupName
    | Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


update : (AnimEvent -> a) -> AnimMsg -> Maybe a
update toMsg msg =
    case msg of
        JavascriptUpdate jsonValue ->
            if Timeline.isAnimationUpdateFor Timeline.ScrollTimeline jsonValue then
                decodeScrollEvent jsonValue
                    |> Maybe.map toMsg

            else
                Nothing

        Ignored ->
            Nothing


decodeScrollEvent : Decode.Value -> Maybe AnimEvent
decodeScrollEvent jsonValue =
    let
        animGroupDecoder =
            Decode.oneOf
                [ Decode.at [ "payload", "animGroup" ] Decode.string
                , Decode.at [ "payload", "elementId" ] Decode.string
                ]

        statusDecoder =
            Decode.at [ "payload", "status" ] Decode.string

        progressDecoder =
            Decode.at [ "payload", "progress" ] Decode.float
    in
    case Decode.decodeValue (Decode.map3 scrollStatusToEvent animGroupDecoder statusDecoder progressDecoder) jsonValue of
        Ok event ->
            Just event

        Err err ->
            Just (AnimError (Decode.errorToString err))


scrollStatusToEvent : AnimGroupName -> String -> Float -> AnimEvent
scrollStatusToEvent animGroup status progress =
    case status of
        "run" ->
            Run animGroup

        "started" ->
            Started animGroup

        "completed" ->
            Ended animGroup

        "cancelled" ->
            Cancelled animGroup progress

        "iteration" ->
            Iteration animGroup (round progress)

        "progress" ->
            Progress animGroup progress

        unknown ->
            AnimError ("Unknown scroll status: " ++ unknown)



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions toMsg portSubscription =
    portSubscription <|
        toMsg
            << Timeline.routeForEngine Timeline.ScrollTimeline JavascriptUpdate Ignored



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> List (Html.Attribute msg)
attributes animGroupName =
    [ Html.Attributes.attribute "data-anim-target" animGroupName ]



-- ============================================================
-- AXIS
-- ============================================================


horizontal : EngineBuilder -> EngineBuilder
horizontal =
    Builder.setScrollAxis "inline"



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> EngineBuilder -> EngineBuilder
iterations =
    Builder.iterations


alternate : EngineBuilder -> EngineBuilder
alternate =
    Builder.alternate



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> EngineBuilder -> EngineBuilder
easing =
    Builder.easing



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> EngineBuilder -> EngineBuilder
spring =
    Builder.spring



-- ============================================================
-- UNIT
-- ============================================================


cssUnit : Unit -> EngineBuilder -> EngineBuilder
cssUnit =
    Builder.cssUnit


cssUnitX : Unit -> EngineBuilder -> EngineBuilder
cssUnitX =
    Builder.cssUnitX


cssUnitY : Unit -> EngineBuilder -> EngineBuilder
cssUnitY =
    Builder.cssUnitY


cssUnitZ : Unit -> EngineBuilder -> EngineBuilder
cssUnitZ =
    Builder.cssUnitZ



-- ============================================================
-- PROPERTIES
-- ============================================================


transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Builder.transformOrder


discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    Builder.discreteExit



-- ============================================================
-- EVENTS
-- ============================================================


withProgressEvents : Bool -> EngineBuilder -> EngineBuilder
withProgressEvents =
    Builder.setScrollEmitProgress
