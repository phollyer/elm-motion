# React

Once you've [triggered](trigger.md) a scroll, you'll usually want to do something when it finishes - update a status bar, fire a follow-up action, mark a step complete, or track live progress.

How you react depends entirely on which engine you used.

## What Each Engine Sends Back

| Engine | What you handle in `update` |
| ------ | --------------------------- |
| [Cmd](../engines/cmd.md) | A single completion message. No payload. |
| [Task](../engines/task.md) | A `Result ScrollError (List ScrollOk)`. |
| [Sub](../engines/sub.md) | A stream of `ScrollEvent`s - `Started`, `Progress`, `Ended`, etc. |

??? example "View Source Code"

    === "Cmd"

        The completion message is purely a signal that the scroll has ended - success and failure both look the same:

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( model
                    , Cmd.scroll ScrollComplete <|
                        scrollToSection targetId
                    )

                ScrollComplete ->
                    ( { model | status = Arrived }, Cmd.none )
        ```

        Use Task instead if you need to know whether the scroll actually succeeded.

    === "Task"

        `Task.scroll` resolves to a typed `Result`. Pattern-match on `Ok` and `Err` in your `update`:

        ```elm
        type Msg
            = ScrollTo String
            | GotScrollResult (Result ScrollError (List ScrollOk))


        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( { model | status = Scrolling }
                    , scrollToSection targetId
                        |> Task.scroll
                        |> TaskCore.attempt GotScrollResult
                    )

                GotScrollResult (Ok _) ->
                    ( { model | status = Arrived }, Cmd.none )

                GotScrollResult (Err _) ->
                    ( { model | status = Failed }, Cmd.none )
        ```

        📖 See [Task Engine - Success / Failure](../engines/task.md#success-scrollok) for the full `ScrollOk` and `ScrollError` field reference.

    === "Sub"

        `Sub.update` returns the new state, a list of events that fired on this frame, and any `Cmd` the engine needs to issue. Fold over the events to fan them out into your own model updates:

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotScrollMsg scrollMsg ->
                    let
                        ( newScrollState, events, scrollCmd ) =
                            Sub.update GotScrollMsg scrollMsg model.scrollState

                        updatedModel =
                            List.foldl handleEvent
                                { model | scrollState = newScrollState }
                                events
                    in
                    ( updatedModel, scrollCmd )


        handleEvent : Sub.ScrollEvent -> Model -> Model
        handleEvent event model =
            case event of
                Sub.Started _ ->
                    { model | status = Scrolling }

                Sub.Ended _ ->
                    { model | status = Arrived }

                Sub.Progress _ position progress ->
                    { model
                        | scrollX = position.x
                        , scrollY = position.y
                        , percent = round (progress * 100)
                    }

                _ ->
                    model
        ```

        **Why a list?** Multiple scrolls in the same `ScrollState` can each emit events on the same frame, so they all arrive together.

        📖 See [Sub Engine - Events](../engines/sub.md#events) for the complete event reference and [Live Progress](../engines/sub.md#live-progress) for richer examples.

## Next Steps

The Sub engine also needs a subscription wired into your app so it can receive frame updates while scrolls are running.

[Subscribe →](subscribe.md){ .md-button .md-button--primary }
