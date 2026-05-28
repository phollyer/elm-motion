# Spring

Springs describe motion in terms of physics — stiffness, damping, mass — rather than a fixed time-and-curve. There is no explicit duration: the motion ends when the value has settled at the target.

Use a spring when motion should feel physical. Use an [easing](easing.md) when you want a known duration and a predictable curve.

--8<-- "docs/shared/spring-reference.md"

## Choosing a Spring

| Use Case | Recommended Preset | Why |
| -------- | ------------------ | --- |
| Hero reveals, large modals | `gentle` | Soft settle with a sense of weight |
| Playful accents, attention-grabbers | `wobbly` | Visible oscillations — character and energy |
| Buttons, tooltips, snappy state changes | `stiff` | Quick to settle, small overshoot |
| Ambient drift, slow-developing reveals | `slow` | Mellow approach, no urgency |
| Scroll handoffs, anywhere overshoot would read as a bug | `noWobble` | Spring-like timing without bounce |

!!! tip "Springs vs easings"
    A spring's duration depends on its physics and the distance it has to travel — short hops settle quickly, long ones take longer, all using the same configuration. Easings always take their configured duration, regardless of distance. Reach for a spring when distance is dynamic or unknown.

!!! note "Engines that support springs"
    All six animation engines accept springs:
    [Transition](../engines/transition.md),
    [Keyframe](../engines/keyframes.md),
    [Sub](../engines/sub.md),
    [WAAPI](../engines/waapi.md),
    [Scroll Timeline](../engines/scroll-timeline.md),
    [View Timeline](../engines/view-timeline.md).

    The CSS-based engines (Transition, Keyframe) and the JS-backed engines (WAAPI, Scroll Timeline, View Timeline) pre-bake the spring into densely-spaced samples. Sub renders the analytic solution every frame.

!!! warning "Springs and `duration` / `speed`"
    Setting a spring overrides any easing already on the builder, and the spring's settle time is what determines how long the motion lasts. `duration` and `speed` only apply to easing-based motion.

## Setting a Spring

A spring can be set at either level, with the same precedence rules as easing:

- **Engine-level** (`Engine.spring`) — default for every property in the builder.
- **Property-level** (`Property.spring`) — overrides the engine default for that property only.

??? example "View Source Code"

    ```elm
    import Motion.Spring as Spring

    bouncyReveal : AnimBuilder mode -> AnimBuilder mode
    bouncyReveal =
        Translate.for "panel"
            >> Translate.toX 0
            >> Translate.spring Spring.wobbly
            >> Translate.build
    ```

## Next Steps

Continue to transform composition.

[Transform Order →](../concepts/transform-order.md){ .md-button .md-button--primary }
