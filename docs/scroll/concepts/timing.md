# Scroll Timing

How long should a scroll take? Elm Motion gives you two ways to answer that, and you only pick one.

| Approach | What it means | Best for |
| -------- | ------------- | -------- |
| `duration` | "Take exactly this many milliseconds, no matter how far we're scrolling." | All targets are at roughly the same distance, or you want consistent rhythm. |
| `speed` | "Move at this many pixels per second; let the distance decide the duration." | Most scrolling. Distances vary, and a constant feel is what users expect. |

!!! tip "`speed` is almost always the right default for scrolling"
    A 100px scroll at a fixed 600ms duration crawls. A 2400px scroll at the same 600ms races. `speed` gives you the same *feel* no matter how far the user is jumping.

## `duration`

Fixed milliseconds, regardless of distance:

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.duration 600
        >> Scroll.build
    ```

## `speed`

Pixels per second; the engine works out the duration from the distance to travel:

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.speed 800
        >> Scroll.build
    ```

At 800 px/s a 200px scroll takes 250ms; a 2400px scroll takes 3 seconds.

## `delay`

Wait before starting the scroll, in milliseconds. Handy for staggering scrolls or letting other UI settle first:

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.delay 150
        >> Scroll.speed 800
        >> Scroll.build
    ```

## Defaults vs Per-Target

In a single builder pipeline you can set defaults that apply to every scroll, then override them on individual targets:

??? example "View Source Code"

    ```elm
    Scroll.speed 800
        >> Scroll.easing QuintOut
        >> Scroll.forDocument
        >> Scroll.toElement "section-1"
        >> Scroll.build
        >> Scroll.forDocument
        >> Scroll.toElement "hero"
        >> Scroll.duration 400      -- overrides the 800 px/s default just for this target
        >> Scroll.build
    ```

## Gotchas

!!! warning "Pick one - `duration` or `speed`"
    If both are set on the same target, the last one wins. Be explicit about which you actually want.

!!! warning "No `duration` and no `speed` = an instant jump"
    With neither set, the engine treats the duration as `0ms` and snaps to the target. Always set at least one.

## Timing Accuracy

!!! warning "Cmd and Task timing is approximate"
    [Cmd](../engines/cmd.md) and [Task](../engines/task.md) pre-calculate every frame up front and then write them out. They have no access to the browser's vsync signal, so the *actual* time the scroll takes can drift depending on machine load and display refresh rate.

    If timing precision matters, use [Sub](../engines/sub.md) - it advances each frame with a real delta-time, so the configured duration stays close to what users perceive.

## Next Steps

Now that you can control *how long*, learn how to control *how it feels*.

[Easing →](easing.md){ .md-button .md-button--primary }
