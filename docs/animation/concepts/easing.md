# Easing

Easing controls how property values accelerate and decelerate during animation.

--8<-- "docs/shared/easing-reference.md"

## Choosing an Easing

| Use Case | Recommended Easing | Why |
| -------- | ------------------ | --- |
| Entering elements | `QuintOut` / `CubicOut` | Arrives fast, settles smoothly |
| Exiting elements | `QuintIn` / `CubicIn` | Leaves with acceleration |
| State-to-state transitions | `QuintInOut` / `CubicInOut` | Balanced easing at both ends |
| Playful motion moments | `BackOut` / `ElasticOut` / `BounceOut` | Adds character and energy |

!!! tip "For entrances"
    Use `Out` variants — elements should arrive and settle smoothly.

!!! tip "For exits"
    Use `In` variants — elements should accelerate away.

!!! tip "For state changes"
    Use `InOut` variants — smooth transitions between states.

## Examples

The same horizontal translate, driven by six different easing curves and rendered in each of the four time-driven engines. Click a curve to play the animation; each click also flips the direction so you can keep tapping to compare. Same `Translate.duration 1500` for every curve.

??? example "View Example"
    === "Transition"

        <iframe src="../../examples/src/Animation/Transition/Easings/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Keyframe"

        <iframe src="../../examples/src/Animation/Keyframe/Easings/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../examples/src/Animation/Sub/Easings/index.html" class="example-iframe" loading="lazy"></iframe>

    === "WAAPI"

        <iframe src="../../examples/src/Animation/WAAPI/Easings/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"
    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/Easings/Main.elm"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/Easings/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/Easings/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/Easings/Main.elm"
        ```

## Next Steps

For physics-based motion — where the spring's stiffness, damping, and mass decide how long the motion takes — see Spring.

[Spring →](../concepts/spring.md){ .md-button .md-button--primary }
