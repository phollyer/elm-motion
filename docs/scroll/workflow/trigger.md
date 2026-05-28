# Trigger

You've [built](build.md) the scroll - that builder is just a description, not a running scroll. To actually make something move, you hand the builder to one of the three engines from your `update` function.

The three engines have three different shapes of trigger function. Same builder, different wiring.

## From `update`

??? example "View Source Code"

    === "Cmd"

        `Cmd.scroll` takes a completion message and the builder, and returns a `Cmd`. No model state, no subscriptions.

        ```elm
        import Scroll.Engine.Cmd as Cmd


        type Msg
            = ScrollTo String
            | ScrollComplete


        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( model
                    , Cmd.scroll ScrollComplete <|
                        scrollToSection targetId
                    )

                ScrollComplete ->
                    ( model, Cmd.none )
        ```

        `ScrollComplete` fires when the scroll finishes - it carries no information about success or failure. If you need to know whether the scroll worked, use Task.

    === "Task"

        `Task.scroll` returns a `Task ScrollError (List ScrollOk)`. Turn it into a `Cmd` with `Task.attempt`:

        ```elm
        import Scroll.Engine.Task as Task
        import Task as TaskCore


        type Msg
            = ScrollTo String
            | GotScrollResult (Result Task.ScrollError (List Task.ScrollOk))


        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( model
                    , scrollToSection targetId
                        |> Task.scroll
                        |> TaskCore.attempt GotScrollResult
                    )

                GotScrollResult _ ->
                    ( model, Cmd.none )
        ```

        Because it's a `Task`, you can compose it with other tasks (e.g. fetch data first, then scroll to the result) before turning the whole chain into a `Cmd`.

    === "Sub"

        `Sub.scroll` takes a tagger, the current `ScrollState`, and the builder. It returns the new state and a `Cmd` together:

        ```elm
        import Scroll.Engine.Sub as Sub


        type Msg
            = ScrollTo String
            | GotScrollMsg Sub.ScrollMsg


        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    let
                        ( newScrollState, scrollCmd ) =
                            Sub.scroll GotScrollMsg model.scrollState <|
                                scrollToSection targetId
                    in
                    ( { model | scrollState = newScrollState }, scrollCmd )

                GotScrollMsg _ ->
                    ( model, Cmd.none )
        ```

        - Store `Sub.ScrollState` in your model and seed it with `Sub.init`.
        - Triggering for a container that's already scrolling **replaces** the running scroll - smoothly carrying on from the current position.
        - Sub also needs a [subscription](subscribe.md) wired up to drive frame-by-frame updates.

## From `init`

All three engines can fire a scroll on page load - just trigger from `init`:

??? example "View Source Code"

    === "Cmd"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( {}
            , Cmd.scroll ScrollComplete <|
                scrollToSection "intro"
            )
        ```

    === "Task"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { status = Scrolling }
            , scrollToSection "intro"
                |> Task.scroll
                |> TaskCore.attempt GotScrollResult
            )
        ```

    === "Sub"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            let
                ( scrollState, scrollCmd ) =
                    Sub.scroll GotScrollMsg Sub.init <|
                        scrollToSection "intro"
            in
            ( { scrollState = scrollState }
            , scrollCmd
            )
        ```

## Next Steps

A scroll has been triggered - now handle whatever the engine sends back.

[React →](react.md){ .md-button .md-button--primary }
