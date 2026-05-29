# Interrupting Scrolls

Re-triggering a scroll mid-flight is handled differently by each engine. Only `Scroll.Sub` redirects automatically; with `Cmd` and `Task` the new scroll runs in parallel with the old one, and gating that is on you.

| Engine | On re-trigger |
| ------ | ------------- |
| [Cmd](../engines/cmd.md) | Runs in parallel - gate it yourself (track an `isScrolling` flag, debounce, etc.). |
| [Task](../engines/task.md) | Runs in parallel - same as `Cmd`, but the `Result` makes it easy to chain the next scroll off the previous one. |
| [Sub](../engines/sub.md) | Replaces the running scroll, picking up smoothly from the current position. Fires a `Stopped` event for the interrupted scroll first. |

The example below shows the same two-button scroll in each engine - mash the buttons to feel the difference.

??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Scroll/Cmd/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Scroll/Task/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Scroll/Sub/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"
    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Scroll/Cmd/Interrupting/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Scroll/Task/Interrupting/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/Interrupting/Main.elm"
        ```

## Next Steps

Choose the easing curve that shapes how each scroll accelerates and decelerates.

[Easing →](easing.md){ .md-button .md-button--primary }
