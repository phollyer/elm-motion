# Playback

Control how many times an animation plays and whether each repeat reverses direction. Every Document timeline engine except [Transition](../engines/transition.md) supports the same three playback functions.

| Function | Effect | Default |
| -------- | ------ | ------- |
| `iterations` | Play the animation a fixed number of times | `1` |
| `loopForever` | Repeat the animation indefinitely | off |
| `alternate` | Reverse direction on each repeat (ping-pong) | off |

## Example - Pulsing Dot

A dot in the middle of the screen that pulses by scaling and fading in and out - looping forever and alternating direction on each iteration.

--8<-- "docs/animation/first-animations/pulsing-dot.md:examples"

--8<-- "docs/animation/first-animations/pulsing-dot.md:code"



## Iterations

Play the animation `n` times in the same direction. The element returns to its `start` value at the beginning of every iteration.

??? example "View Source Code"

    ```elm
    Keyframe.iterations 3
        >> Keyframe.for "blink"
        >> Opacity.begin
        >> Opacity.to 0
        >> Opacity.duration 250
        >> Opacity.end
    ```

After three plays the animation ends and the element rests at the final value.

## Loop Forever

Repeat the animation indefinitely.

??? example "View Source Code"

    ```elm
    Sub.loopForever
        >> Sub.for "spinner"
        >> Rotate.begin
        >> Rotate.toZ 360
        >> Rotate.duration 1000
        >> Rotate.end
    ```

## Alternate

Reverse direction on every iteration boundary. The classic ping-pong:

- iteration 1 plays `start -> end`
- iteration 2 plays `end -> start`
- iteration 3 plays `start -> end`
- …

??? example "View Source Code"

    ```elm
    WAAPI.loopForever
        >> WAAPI.alternate
        >> WAAPI.for "bounce"
        >> Translate.begin
        >> Translate.toY -40
        >> Translate.duration 500
        >> Translate.easing EaseInOut
        >> Translate.end
    ```

!!! info "Alternate implies at least two iterations"
    `alternate` only has a visible effect when the animation runs more than once. Calling `alternate` when `iterations` is unset or `1` automatically bumps `iterations` to `2`. An explicit `iterations` count (or `loopForever`) set before or after `alternate` is preserved.

## Next Steps

Shape how each iteration feels with easing curves.

[Easing →](easing.md){ .md-button .md-button--primary }
