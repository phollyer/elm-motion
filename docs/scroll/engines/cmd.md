# `Scroll.Cmd`

This is everything `Scroll.Cmd` offers:

| Function | Type |
| -------- | ---- |
| `scroll` | `msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg` |

One function. That's it.

And that's the point: if your scroll is "send the user there, I don't need to know anything more", you can wire it up in two lines of `update` and there is nothing else to learn. No state in the model, no subscription, no view attribute, no event union.

If you need anything beyond "go" - typed success/failure, mid-flight redirects, live progress, pause/resume - the other engines have it. But for plain navigation, this is the whole story.

## Example

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Cmd/FirstScroll/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm"
    ```

## Trigger

??? example "View Source Code"

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

`ScrollComplete` fires when the scroll finishes - successfully or not, you can't tell the difference, and that's deliberate. If the target element isn't in the DOM, the scroll fails silently.

If you need a real result, use [`Task`](task.md).

## Multiple Targets in One Call

Chain `build` calls into a single pipeline to dispatch several scrolls at once. The completion message fires **once per target**:

??? example "View Source Code"

    ```elm
    scrollSidebarAndMain : ScrollBuilder -> ScrollBuilder
    scrollSidebarAndMain =
        Scroll.forContainer "sidebar"
            >> Scroll.toElement "nav-item-3"
            >> Scroll.speed 300
            >> Scroll.build
            >> Scroll.forContainer "main-content"
            >> Scroll.toElement "section-3"
            >> Scroll.speed 400
            >> Scroll.build
    ```

## Caveats

The minimal API has two real trade-offs - both shared with [`Task`](task.md), and both fixed by [`Sub`](sub.md) if they matter to you.

### Timing Drift

`Cmd` pre-calculates every frame at dispatch time and writes them out as a `Task` chain. Without access to the browser's vsync signal, the *actual* duration can drift on busy pages or high-refresh-rate displays.

### Re-Triggering Doesn't Cancel

Calling `Cmd.scroll` again while a scroll is in flight doesn't replace the running scroll - both run in parallel and compete for control of the container. The longer one usually wins, often finishing short of its real target.

If you have to stay on `Cmd`, prevent overlap in your own code: ignore new triggers while a scroll is active, debounce rapid input, or queue the latest target and only dispatch it after `ScrollComplete`.

📖 See [Interrupting Scrolls](../concepts/interrupting-scrolls.md) for a live side-by-side demonstration of all three engines.

## Next Steps

Need to know whether the scroll succeeded, or compose a scroll with other tasks?

[Task Engine →](task.md){ .md-button .md-button--primary }
