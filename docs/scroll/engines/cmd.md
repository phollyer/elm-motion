# `Scroll.Cmd`

This is everything `Scroll.Cmd` offers:

| Function | Type |
| -------- | ---- |
| `scroll` | `msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg` |
| `delay` | `Int -> ScrollBuilder -> ScrollBuilder` |
| `duration` | `Int -> ScrollBuilder -> ScrollBuilder` |
| `speed` | `Float -> ScrollBuilder -> ScrollBuilder` |
| `easing` | `Easing -> ScrollBuilder -> ScrollBuilder` |

One trigger, plus timing and easing. That's the whole engine.

And that's the point: if your scroll is "send the user there, I don't need to know anything more", you can wire it up in two lines of `update` and there is nothing else to learn. No state in the model, no subscription, no event union.

If you need anything beyond "go" - typed success/failure, mid-flight redirects, live progress, pause/resume - the other engines have it. But for plain navigation, this is the whole story.

## Example

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Cmd/FirstScroll/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Cmd/FirstScroll/Main.elm"
    ```

## Trigger

Use `scroll` to trigger the scroll animation.

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

`ScrollComplete` fires when the scroll finishes - successfully or not, you can't tell the difference, and that's deliberate. If the target element isn't in the DOM, the scroll fails silently and reports completion.

If you need a real result, use [`Task`](task.md) or [`Sub`](sub.md).

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

This Engine has two real trade-offs - both shared with [`Task`](task.md), and both fixed by [`Sub`](sub.md) if they matter to you.

### Timing Drift

When you ask for a `duration` of `3000`, you're saying "I want this scroll to take about three seconds". `Cmd` plans out all the in-between scroll positions up front and hands them to Elm as a chain of small tasks: *set position, then set the next, then the next...*

There's no clock between those steps. The runtime just runs them back-to-back as fast as it can, and the browser paints whatever it has ready on its next refresh. So the *actual* time you see depends on how busy the page is and how fast the display refreshes - the duration is a target, not a guarantee.

If you need a duration you can rely on to the millisecond, use [`Sub`](sub.md).

### Re-Triggering Doesn't Cancel

Calling `Cmd.scroll` again while a scroll is in flight doesn't replace the running scroll - both run in parallel and compete for control of the container. The longer one usually wins, often finishing short of its real target.

If you have to stay on `Cmd`, prevent overlap in your own code: ignore new triggers while a scroll is active, debounce rapid input, or queue the latest target and only dispatch it after `ScrollComplete`.

## Next Steps

Need to know whether the scroll succeeded, or compose a scroll with other tasks?

[Task Engine →](task.md){ .md-button .md-button--primary }
