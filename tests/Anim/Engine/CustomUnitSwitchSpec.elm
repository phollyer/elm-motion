module Anim.Engine.CustomUnitSwitchSpec exposing (suite)

{-| Sequential CSS unit switching for numeric custom properties.
-}

import Anim.Engine.Sub as Sub
import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.Transition as Transition
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.Sub as InternalSub
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Custom as Custom
import Anim.Unit exposing (Unit(..))
import Expect
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


advanceBuilderAfterAnimate : Builder.AnimBuilder eng -> Builder.AnimBuilder eng
advanceBuilderAfterAnimate builder =
    let
        processed =
            Builder.process builder
    in
    builder
        |> Builder.addAnimationToHistory processed
        |> Builder.mergeBaselines
        |> Builder.clearAnimData


decodeCustomUnit : String -> String -> Maybe String
decodeCustomUnit animGroupName json =
    let
        propertyDecoder =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\propertyType ->
                        if propertyType == "customProperty" then
                            Decode.field "unit" Decode.string

                        else
                            Decode.fail "not customProperty"
                    )
    in
    Decode.decodeString
        (Decode.at [ "elements", animGroupName, "properties" ]
            (Decode.list (Decode.maybe propertyDecoder)
                |> Decode.map (List.filterMap identity >> List.head)
            )
        )
        json
        |> Result.toMaybe
        |> Maybe.andThen identity


encodedCustomUnit : Custom.Property -> Custom.Property -> String
encodedCustomUnit initialProperty nextProperty =
    let
        initialized =
            Builder.init [ Custom.init "card" initialProperty 0 ]
                |> Builder.mergeBaselines
                |> Builder.clearAnimData

        afterFirstPhase =
            initialized
                |> Builder.for "card"
                |> Custom.begin initialProperty
                |> Custom.to 100
                |> Custom.end
                |> advanceBuilderAfterAnimate

        processed =
            afterFirstPhase
                |> Builder.for "card"
                |> Custom.begin nextProperty
                |> Custom.to 8
                |> Custom.end
                |> Builder.process
    in
    Encoder.encode AnimGroups.init processed |> Encode.encode 0


subStep : Float -> Sub.AnimState -> Sub.AnimState
subStep deltaMs state =
    Sub.update (InternalSub.AnimationFrame deltaMs) state
        |> Tuple.first


suite : Test
suite =
    describe "Custom sequential unit switching"
        [ test "WAAPI payload uses the second animation unit after a completed baseline" <|
            \_ ->
                encodedCustomUnit (Custom.BorderRadius Percent) (Custom.BorderRadius Px)
                    |> decodeCustomUnit "card"
                    |> Expect.equal (Just "px")
        , test "WAAPI payload switches free-form unit strings" <|
            \_ ->
                encodedCustomUnit
                    (Custom.Custom "--offset" "%")
                    (Custom.Custom "--offset" "rem")
                    |> decodeCustomUnit "card"
                    |> Expect.equal (Just "rem")
        , test "Keyframe CSS uses the second animation unit for start and end" <|
            \_ ->
                let
                    afterPercentPhase =
                        Keyframe.init [ Custom.init "card" (Custom.BorderRadius Percent) 0 ]
                            |> (\state ->
                                    Keyframe.animate state
                                        (Keyframe.for "card"
                                            >> Custom.begin (Custom.BorderRadius Percent)
                                            >> Custom.to 100
                                            >> Custom.duration 500
                                            >> Custom.end
                                        )
                               )
                            |> Keyframe.stop "card"

                    css =
                        Keyframe.animate afterPercentPhase
                            (Keyframe.for "card"
                                >> Custom.begin (Custom.BorderRadius Px)
                                >> Custom.to 8
                                >> Custom.duration 500
                                >> Custom.end
                            )
                            |> Keyframe.maybeString "card"
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ ->
                        String.contains "border-radius: 100px;" css
                            |> Expect.equal True
                            |> Expect.onFail ("Expected px start value; got:\n" ++ css)
                    , \_ ->
                        String.contains "border-radius: 8px;" css
                            |> Expect.equal True
                            |> Expect.onFail ("Expected px end value; got:\n" ++ css)
                    , \_ ->
                        String.contains "border-radius: 100%;" css
                            |> Expect.equal False
                            |> Expect.onFail ("Expected old percent unit to be absent; got:\n" ++ css)
                    ]
                    ()
        , test "Transition renders the second animation unit" <|
            \_ ->
                Transition.init [ Custom.init "card" (Custom.BorderRadius Percent) 0 ]
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "card"
                                    >> Custom.begin (Custom.BorderRadius Percent)
                                    >> Custom.to 100
                                    >> Custom.end
                                )
                       )
                    |> (\state ->
                            Transition.animate state
                                (Transition.for "card"
                                    >> Custom.begin (Custom.BorderRadius Px)
                                    >> Custom.to 8
                                    >> Custom.end
                                )
                       )
                    |> (\state -> Html.div (Transition.attributes "card" state) [])
                    |> Query.fromHtml
                    |> Query.has [ Selector.style "border-radius" "8px" ]
        , test "Sub renders the second unit while the animation is running" <|
            \_ ->
                Sub.init [ Custom.init "card" (Custom.BorderRadius Percent) 0 ]
                    |> (\state ->
                            Sub.animate state
                                (Sub.for "card"
                                    >> Custom.begin (Custom.BorderRadius Percent)
                                    >> Custom.to 100
                                    >> Custom.duration 1000
                                    >> Custom.easing Linear
                                    >> Custom.end
                                )
                       )
                    |> subStep 1000
                    |> (\state ->
                            Sub.animate state
                                (Sub.for "card"
                                    >> Custom.begin (Custom.BorderRadius Px)
                                    >> Custom.to 8
                                    >> Custom.duration 1000
                                    >> Custom.easing Linear
                                    >> Custom.end
                                )
                       )
                    |> subStep 500
                    |> (\state -> Html.div (Sub.attributes "card" state) [])
                    |> Query.fromHtml
                    |> Query.has [ Selector.style "border-radius" "54px" ]
        ]
