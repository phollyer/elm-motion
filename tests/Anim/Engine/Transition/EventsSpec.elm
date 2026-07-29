module Anim.Engine.Transition.EventsSpec exposing (suite)

{-| Behavioural tests for the CSS-transition lifecycle events surfaced by
`Anim.Engine.Transition`.

The events are driven end-to-end through the public surface: the engine's
`attributes` / `events` wiring is rendered to HTML and the native DOM events
(`transitionstart` / `transitionend` / `transitionrun` / `transitioncancel`)
are simulated with `Test.Html.Event`, then fed back through `Transition.update`.
This exercises the real decoder, the `currentTargetId` / `targetId` bubbling
distinction, and the `Cancelled` gate that suppresses self-inflicted cancels.

-}

import Anim.Engine.Transition as Transition
import Anim.Property.Opacity as Opacity
import Expect
import Html
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query


type Msg
    = GotAnim Transition.AnimMsg


group : String
group =
    "box"


baseState : Transition.AnimState
baseState =
    Transition.init [ Opacity.init group 0 ]
        |> (\state ->
                Transition.animate state
                    (Transition.for group
                        >> Opacity.begin
                        >> Opacity.to 1
                        >> Opacity.duration 500
                        >> Opacity.end
                    )
           )


{-| Build a DOM event payload. Empty ids decode to `Nothing`, matching the
engine's `elementIdDecoder`.
-}
payload : { target : String, current : String } -> Encode.Value
payload ids =
    Encode.object
        [ ( "target"
          , Encode.object
                [ ( "dataset", Encode.object [ ( "animGroupName", Encode.string group ) ] )
                , ( "id", Encode.string ids.target )
                ]
          )
        , ( "currentTarget", Encode.object [ ( "id", Encode.string ids.current ) ] )
        ]


{-| Render the engine, simulate a native DOM event, and run the decoded
message through `update`, returning the next state and the surfaced event.
-}
fire : Transition.AnimState -> String -> Encode.Value -> Result String ( Transition.AnimState, Maybe Transition.AnimEvent )
fire state eventName eventPayload =
    Html.div (Transition.attributes group state ++ Transition.events GotAnim) []
        |> Query.fromHtml
        |> Event.simulate ( eventName, eventPayload )
        |> Event.toResult
        |> Result.map (\(GotAnim animMsg) -> Transition.update animMsg state)


eventOf : Result String ( Transition.AnimState, Maybe Transition.AnimEvent ) -> Result String (Maybe Transition.AnimEvent)
eventOf =
    Result.map Tuple.second


suite : Test
suite =
    describe "Anim.Engine.Transition lifecycle events"
        [ test "transitionstart surfaces Started with the current target id" <|
            \_ ->
                fire baseState "transitionstart" (payload { target = "", current = "el" })
                    |> eventOf
                    |> Expect.equal (Ok (Just (Transition.Started (Just "el") Nothing group)))
        , test "transitionrun surfaces Run" <|
            \_ ->
                fire baseState "transitionrun" (payload { target = "el", current = "el" })
                    |> eventOf
                    |> Expect.equal (Ok (Just (Transition.Run (Just "el") (Just "el") group)))
        , test "transitionend surfaces Ended" <|
            \_ ->
                fire baseState "transitionend" (payload { target = "el", current = "el" })
                    |> eventOf
                    |> Expect.equal (Ok (Just (Transition.Ended (Just "el") (Just "el") group)))
        , test "a bubbled event keeps the current and target ids distinct" <|
            \_ ->
                fire baseState "transitionstart" (payload { target = "child", current = "parent" })
                    |> eventOf
                    |> Expect.equal (Ok (Just (Transition.Started (Just "parent") (Just "child") group)))
        , test "an external cancel of a running group surfaces Cancelled" <|
            \_ ->
                fire baseState "transitionrun" (payload { target = "el", current = "el" })
                    |> Result.andThen
                        (\( running, _ ) ->
                            fire running "transitioncancel" (payload { target = "el", current = "el" })
                        )
                    |> eventOf
                    |> Expect.equal (Ok (Just (Transition.Cancelled (Just "el") (Just "el") group)))
        , test "a cancel after the group has ended is suppressed as a self-cancel" <|
            \_ ->
                fire baseState "transitionend" (payload { target = "el", current = "el" })
                    |> Result.andThen
                        (\( ended, _ ) ->
                            fire ended "transitioncancel" (payload { target = "el", current = "el" })
                        )
                    |> eventOf
                    |> Expect.equal (Ok Nothing)
        ]
