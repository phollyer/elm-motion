# Interrupting Scrolls

What happens if a scroll is already in flight and you trigger another one? The answer depends entirely on which engine you're using.

## At a Glance

| Engine | What happens on re-trigger |
| ------ | -------------------------- |
| [Cmd](../engines/cmd.md) | ⚠️ Both scrolls run in parallel. The new one does **not** replace the old. |
| [Task](../engines/task.md) | ⚠️ Both scrolls run in parallel. The new one does **not** replace the old. |
| [Sub](../engines/sub.md) | ✅ The new scroll **replaces** the old, picking up smoothly from the current position. |

The three examples below all do the same thing - two big buttons that scroll a container to top and bottom - and let you mash them rapidly to see each engine's natural behaviour.

## `Scroll.Cmd`

`Scroll.Cmd` pre-calculates every frame of the scroll at dispatch time. Re-triggering doesn't cancel the running scroll - it dispatches a **second** scroll alongside it.

What you'll see in the example:

- click rapidly to the **same** target: scrolls overlap, but they're aiming at the same place, so the result is correct.
- click to a **different** target while one is running: both scrolls fight for the container. Usually the longer one wins, often finishing short of its real target.

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Cmd/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Cmd/Interrupting/Main.elm"
    ```

A dispatched `Cmd` scroll cannot be cancelled.

### Working Around It

If you have to stay on `Cmd`, the only options are to prevent the overlap in your own code:

- ignore new triggers while a scroll is active (track an `isScrolling` flag),
- debounce or throttle rapid input,
- queue the latest target and only dispatch it after `ScrollComplete`.

If you need clean redirection, switch to [`Scroll.Sub`](../engines/sub.md).

## `Scroll.Task`

`Scroll.Task` behaves identically to `Cmd` here - same pre-calculation, same parallel behaviour. The difference is that you also get an `Err` if the second scroll fails (e.g. target missing), but the **running** scroll still can't be cancelled.

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Task/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Task/Interrupting/Main.elm"
    ```

### Working Around It

The same workarounds as `Cmd` apply, with one extra option that `Task`'s `Result` makes natural:

- serialize: start the next scroll only after the previous `Task` resolves,
- keep a `pendingTarget` in the model and launch it from `ScrollResult`,
- throttle or debounce repeated triggers before launching the next `Task`.

## `Scroll.Sub`

`Scroll.Sub` is the engine that handles this gracefully. Because it keeps live `ScrollState`, calling `scroll` again for a container that's already scrolling **replaces** the running scroll - the engine reads the current DOM position on the next frame and re-targets from wherever it actually is.

The visible result: the scroll smoothly bends toward the new target without jumping, jittering, or fighting itself.

??? example "View Example"

    <iframe src="../../../examples/src/Scroll/Sub/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/Interrupting/Main.elm"
    ```

The replaced scroll fires a `Stopped` event for the interrupted container before the new scroll begins, so you can react in `update` if you need to.

## Next Steps

You've covered every scroll concept. Now build your first scroll from scratch.

[Your First Scrolls →](../first-scrolls/vertical-scrolling.md){ .md-button .md-button--primary }
