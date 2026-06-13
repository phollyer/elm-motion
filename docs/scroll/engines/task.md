# `Scroll.Task`

This is everything `Scroll.Task` offers:

| Function | Type |
| -------- | ---- |
| `scroll` | `(ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)` |
| `scrollEach` | `(ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))` |
| `delay` | `Float -> ScrollBuilder -> ScrollBuilder` |
| `duration` | `Float -> ScrollBuilder -> ScrollBuilder` |
| `speed` | `Float -> ScrollBuilder -> ScrollBuilder` |
| `easing` | `Easing -> ScrollBuilder -> ScrollBuilder` |

Two triggers, plus timing and easing. Same fire-and-forget mental model as [`Cmd`](cmd.md), but the result is typed - so you can:

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

## Handling Results

### `ScrollOk`

`ScrollOk` is a type alias for `{ container : Container, targetElementId : Maybe String }`.

It is returned for every scroll that completed successfully,  and tells you which container finished and, if you targeted a specific element, which one.

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was scrolled (`Document` or `Container "id"`) |
| `targetElementId` | `Maybe String` | The element ID, if `toElement` was used |

??? example "View Source Code"

    ```elm
    GotScrollResult (Ok results) ->
        let
            arrived =
                results
                    |> List.filterMap .targetElementId
                    |> String.join ", "
        in
        ( { model | status = "Arrived at: " ++ arrived }
        , Cmd.none
        )
    ```

### `ScrollError`

Returned when a scroll fails. Tells you what was being scrolled, which target was involved, and the underlying DOM error - usually because the container or target element wasn't in the DOM.

| Field | Type | Description |
| ----- | ---- | ----------- |
| `container` | `Container` | The container that was being scrolled |
| `targetElementId` | `Maybe String` | The element ID, if one was specified |
| `domError` | [`Dom.Error`](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) | The underlying browser DOM error |

??? example "View Source Code"

    ```elm
    GotScrollResult (Err (Task.ScrollError err)) ->
        let
            target =
                err.targetElementId
                    |> Maybe.withDefault "(no element)"
        in
        ( { model | status = "Scroll failed for: " ++ target }
        , Cmd.none
        )
    ```

## `scroll` vs `scrollEach`

`Task.scroll` is **fail-fast**: the first scroll to fail ends the task immediately, and later scrolls in the same builder are skipped. You only get `Ok` if **every** scroll completed - and at that point the payload lists them all, in order. The moment one fails you get `Err` with no record of the ones that succeeded before it.

If you'd rather get a result for **every** target - failures included - use `Task.scrollEach`:

??? example "View Source Code"

    ```elm
    import Scroll.Task as Task
    import Task

    type Msg
        = ScrollAttempts (List (Result ScrollError ScrollOk))


    ScrollToSequence ->
        ( model
        , scrollSequence
            |> Task.scrollEach
            |> Task.perform ScrollAttempts
        )
    ```

`scrollEach` always completes and returns one `Result` per target.

## Task Composition

Because `Task.scroll` is a regular `Task`, you can compose it with anything else that returns a `Task`. Example - fetch data, then scroll to wherever the response points:

??? example "View Source Code"

    ```elm
    import Scroll.Task as Task
    import Task

    fetchArticle "article-123"
        |> Task.andThen
            (Task.scroll << scrollToSection << .anchorId)
        |> Task.attempt GotResult
    ```

## Caveats

`Task` suffers the two pre-calculation trade-offs that [`Cmd`](cmd.md#caveats) does:

- **Timing drift** on busy pages or high-refresh-rate displays.
- **Re-triggering doesn't cancel** - parallel scrolls compete for the container, longest wins.

Both are fixed by [`Sub`](sub.md) if they matter to you.

## Next Steps

Need state, mid-flight redirects, pause / resume, or per-frame progress?

[Sub Engine →](sub.md){ .md-button .md-button--primary }
