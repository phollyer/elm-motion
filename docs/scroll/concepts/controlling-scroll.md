# Controlling Scroll Animations

Once a scroll is running, you may want to stop it, pause it, or send it back to the start. That's only possible with the [`Scroll.Sub`](../engines/sub.md) engine - because only `Sub` keeps state about the scroll while it's in flight.

!!! note "Stateful scrolling only"
    [`Scroll.Cmd`](../engines/cmd.md) and [`Scroll.Task`](../engines/task.md) are fire-and-forget. Once dispatched, they can't be controlled. If you need any of the controls below, reach for `Scroll.Sub`.

## The Five Controls

| Control | Behaviour |
| ------- | --------- |
| `stop` | Jump to the **target** position and finish. |
| `pause` | Freeze at the current position. |
| `resume` | Continue from where `pause` froze. |
| `reset` | Jump to the **start** position and finish. |
| `restart` | Jump to start, then replay. |

All five take a `Container` (either `Sub.Document` or `Sub.Container "id"`) so you can target a specific scroll - useful when several containers are scrolling at the same time.

--8<-- "docs/scroll/concepts/controlling-scrolls/scroll-to-section.md"

## Wiring the Controls

There are two shapes of control function depending on whether they need to issue a command.

### Commands - `stop`, `reset`, `restart`

These actively move the scroll position, so they return `( ScrollState, Cmd msg )`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/ControllingScrolls/Main.elm:stop"
    ```

`reset` and `restart` follow the exact same shape:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/ControllingScrolls/Main.elm:reset"
    ```

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/ControllingScrolls/Main.elm:restart"
    ```

### State-only - `pause`, `resume`

These only flip a flag in `ScrollState`, so they return just the updated state - no `Cmd` needed:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/ControllingScrolls/Main.elm:pause"
    ```

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Scroll/Sub/ControllingScrolls/Main.elm:resume"
    ```

## Events Fired by Controls

When a control runs, the engine emits a matching `ScrollEvent` on the next frame so you can react (update UI, flip status indicators, etc.):

| Control | Event |
| ------- | ----- |
| `stop` | `Stopped` |
| `pause` | `Paused` |
| `resume` | `Resumed` |
| `reset` | `Stopped` |
| `restart` | `Restarted` |

📖 See [Sub Engine - Events](../engines/sub.md#events) for the full event list.

## Next Steps

Learn what happens when you trigger a *new* scroll for a container that's already scrolling.

[Interrupting Scrolls →](interrupting-scrolls.md){ .md-button .md-button--primary }
