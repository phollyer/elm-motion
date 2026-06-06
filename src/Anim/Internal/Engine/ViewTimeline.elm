module Anim.Internal.Engine.ViewTimeline exposing
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
    , rangeEnd
    , rangeStart
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
    Builder.AnimBuilder Builder.ForView



-- ============================================================
-- TRIGGER
-- ============================================================


animate : (Encode.Value -> Cmd msg) -> (EngineBuilder -> EngineBuilder) -> Cmd msg
animate sendToPort pipeline =
    Builder.init [ pipeline ]
        |> Encoder.encodeView
        |> sendToPort



-- ============================================================
-- EVENTS
-- ============================================================


type AnimEvent
    = Started AnimGroupName
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
            if Timeline.isAnimationUpdateFor Timeline.ViewTimeline jsonValue then
                decodeViewEvent jsonValue |> Maybe.map toMsg

            else
                Nothing

        Ignored ->
            Nothing


decodeViewEvent : Decode.Value -> Maybe AnimEvent
decodeViewEvent jsonValue =
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
    case Decode.decodeValue (Decode.map3 viewStatusToEvent animGroupDecoder statusDecoder progressDecoder) jsonValue of
        Ok event ->
            Just event

        Err err ->
            Just (AnimError (Decode.errorToString err))


viewStatusToEvent : AnimGroupName -> String -> Float -> AnimEvent
viewStatusToEvent animGroup status progress =
    case status of
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
            AnimError ("Unknown view status: " ++ unknown)



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions toMsg portSubscription =
    portSubscription <|
        toMsg
            << Timeline.routeForEngine Timeline.ViewTimeline JavascriptUpdate Ignored



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> List (Html.Attribute msg)
attributes animGroupName =
    [ Html.Attributes.attribute "data-anim-target" animGroupName ]



-- ============================================================
-- RANGE
-- ============================================================


rangeStart : String -> EngineBuilder -> EngineBuilder
rangeStart =
    Builder.setViewRangeStart


rangeEnd : String -> EngineBuilder -> EngineBuilder
rangeEnd =
    Builder.setViewRangeEnd



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
-- SPRING
-- ============================================================


spring : Spring -> EngineBuilder -> EngineBuilder
spring =
    Builder.spring



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
