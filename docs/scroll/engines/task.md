# `Scroll.Task`

This is everything `Scroll.Task` offers:

| Function | Type |
| -------- | ---- |
| `scroll` | `(ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)` |
| `scrollEach` | `(ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))` |

Two functions. Same fire-and-forget mental model as [`Cmd`](cmd.md), but the result is typed - so you can:

- find out whether the scroll succeeded or failed,
- chain a scroll with other `Task`s (e.g. fetch data, then scroll to it),
- decide what to do when one scroll in a sequence fails.

If you don't need any of those, [`Cmd`](cmd.md) is simpler. If you need pause / resume / mid-flight redirect / per-frame progress, you want [`Sub`](sub.md).

## Example

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Task/FirstScroll/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Task/FirstScroll/Main.elm"
    ```

## Trigger

`Task.scroll` returns a `Task ScrollError (List ScrollOk)`. Turn it into a `Cmd` with `Task.attempt`:

??? example "View Source Code"

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

            GotScrollResult (Ok _) ->
                ( { model | status = "Arrived" }, Cmd.none )

            GotScrollResult (Err _) ->
                ( { model | status = "Scroll failed" }, Cmd.none )
    ```

## `ScrollOk` and `ScrollError`

| Type | Field | Description |
| ---- | ----- | ----------- |
| `ScrollOk` | `container` | The container that was scrolled |
| `ScrollOk` | `targetElementId` | The element ID, if `toElement` was used |
| `ScrollError` | `container` | The container that was being scrolled |
| `ScrollError` | `targetElementId` | The element ID, if one was specified |
| `ScrollError` | `domError` | The underlying [`Dom.Error`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) |

## `scroll` vs `scrollEach`

`Task.scroll` is **fail-fast**: the first scroll to fail ends the task immediately, and later scrolls in the same builder are skipped. The `Ok` payload lists every scroll that *did* complete, in order.

If you'd rather get a result for **every** target - failures included - use `Task.scrollEach`:

??? example "View Source Code"

    ```elm
    type Msg
        = ScrollAttempts (List (Result ScrollError ScrollOk))


    ScrollToSequence ->
        ( model
        , scrollSequence
            |> Task.scrollEach
            |> TaskCore.perform ScrollAttempts
        )
    ```

`scrollEach` always completes (its error type is `Never`) and returns one `Result` per target.

## Parallel Scrolls

To run independent scrolls in parallel - each with its own success/failure handling - build them separately and batch the resulting `Cmd`s:

??? example "View Source Code"

    ```elm
    ( model
    , Cmd.batch
        [ Task.scroll scrollSidebar
            |> TaskCore.attempt SidebarResult
        , Task.scroll scrollMain
            |> TaskCore.attempt MainResult
        ]
    )
    ```

## Task Composition

Because `Task.scroll` is a regular `Task`, you can compose it with anything else that returns a `Task`. Classic example - fetch data, then scroll to wherever the response points:

??? example "View Source Code"

    ```elm
    fetchArticle "article-123"
        |> TaskCore.andThen
            (Task.scroll << scrollToSection << .anchorId)
        |> TaskCore.attempt GotResult
    ```

## Caveats

`Task` inherits the two pre-calculation trade-offs from [`Cmd`](cmd.md#caveats):

- **Timing drift** on busy pages or high-refresh-rate displays.
- **Re-triggering doesn't cancel** - parallel scrolls compete for the container, longest wins.

Both are fixed by [`Sub`](sub.md) if they matter to you. The `Task` shape does give you one extra workaround for the re-trigger case that `Cmd` doesn't have: serialize. Trigger the next scroll only after the previous `Task` resolves (or chain them with `Task.andThen`).

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live side-by-side demonstration.

## Next Steps

Need state, mid-flight redirects, pause / resume, or per-frame progress?

[Sub Engine →](sub.md){ .md-button .md-button--primary }
