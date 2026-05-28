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

## Next Steps

Continue to transform composition.

[Transform Order →](../concepts/transform-order.md){ .md-button .md-button--primary }
