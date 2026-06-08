module Anim.Engine.Keyframe.RunEventSpec exposing (suite)

{-| Verifies that the Keyframe engine exposes the `animationrun` lifecycle
event in addition to `animationstart`, mirroring the browser's CSS animation
event sequence. `animationrun` fires immediately when the animation is
applied (before any configured delay), so callers can react before the
visual movement begins. `animationstart` continues to fire after the delay,
matching the native spec.
-}

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Opacity as Opacity
import Expect
import Html
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query


type Msg
    = GotAnim Keyframe.AnimMsg


animState : Keyframe.AnimState
animState =
    Keyframe.init [ Opacity.init "box" 0 ]
        |> (\state ->
                Keyframe.animate state
                    (Keyframe.for "box"
                        >> Opacity.begin
                        >> Opacity.to 1
                        >> Opacity.duration 500
                        >> Opacity.delay 200
                        >> Opacity.end
                    )
           )


eventPayload : Encode.Value
eventPayload =
    Encode.object
        [ ( "target"
          , Encode.object
                [ ( "dataset", Encode.object [ ( "animGroupName", Encode.string "box" ) ] )
                , ( "id", Encode.string "box" )
                ]
          )
        , ( "currentTarget", Encode.object [ ( "id", Encode.string "box" ) ] )
        ]


simulate : String -> Result String (Maybe Keyframe.AnimEvent)
simulate eventName =
    Html.div (Keyframe.attributes "box" animState ++ Keyframe.events GotAnim) []
        |> Query.fromHtml
        |> Event.simulate ( eventName, eventPayload )
        |> Event.toResult
        |> Result.map
            (\(GotAnim animMsg) ->
                Keyframe.update animMsg animState
                    |> Tuple.second
            )


suite : Test
suite =
    describe "Keyframe Run event"
        [ test "animationrun decodes into the Run AnimEvent" <|
            \_ ->
                simulate "animationrun"
                    |> Expect.equal (Ok (Just (Keyframe.Run (Just "box") (Just "box") "box")))
        , test "animationstart still produces Started" <|
            \_ ->
                simulate "animationstart"
                    |> Expect.equal (Ok (Just (Keyframe.Started (Just "box") (Just "box") "box")))
        ]
