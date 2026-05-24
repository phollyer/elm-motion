# Responsive Animations

There are two ways to keep animations in sync with layout changes:

1. **Relative length units** — render with `Percent`, `Vw`, `Vh`, `Rem`, or `Em` via [`Anim.Unit`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Unit) and the browser re-evaluates values against the current layout on every frame. No resize plumbing needed. Supported on the [Transition](../engines/transition.md), [Keyframe](../engines/keyframes.md), [WAAPI](../engines/waapi.md), [ScrollTimeline](../engines/scrolltimeline.md), and [ViewTimeline](../engines/viewtimeline.md) engines.
2. **`Anim.Resize.bounds`** — explicit pixel-keyed bounds fed into the engine on each resize event. Use this when endpoints are computed from layout measurements in `Px` (e.g. `containerWidth - boxWidth`). Supported on the [Sub](../engines/sub.md) and [WAAPI](../engines/waapi.md) engines.

When layout changes mid-animation, the Sub and WAAPI engines can keep animations in sync through the [`Anim.Resize`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize) API. Feed new [`Bounds`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize#Bounds) into the engine on each resize event and the in-flight animation is remapped proportionally into the new range — endpoints adopt the new bounds, the current value keeps its relative position, and normalized progress is preserved so timing stays in phase.

The [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md) engines don't currently observe resize events directly; use relative length units for resize-aware animation on those engines. See [Transition and Keyframe Engines](#transition-and-keyframe-engines) below.

---

## Example

--8<-- [start:desc]

A box loops back and forth across a track. Use the slider to change track width while the animation is running. The box's current position is remapped proportionally into the new bounds, and its timing keeps in phase.

--8<-- [end:desc]

--8<-- [start:examples]

??? example "View Example"

    === "WAAPI"

        <iframe src="../../../examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/index.html" class="example-iframe" loading="lazy", style="height:550px;min-height:550px;max-height:550px"></iframe>

    === "Keyframe"

        <iframe src="../../../examples/src/Animation/Keyframe/ResponsiveAnimations/Responsive/index.html" class="example-iframe" loading="lazy", style="height:550px;min-height:550px;max-height:550px"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Animation/Sub/ResponsiveAnimations/Responsive/index.html" class="example-iframe" loading="lazy", style="height:550px;min-height:550px;max-height:550px"></iframe>

--8<-- [end:examples]

---

## Quick Start

Three pieces wire the resize API together.

### 1. Subscribe to viewport changes

Use `Browser.Events.onResize` to know when the layout changes. The example also re-fires this message when the slider changes width so in-app width changes are treated the same as a real browser resize.

??? example "View Source Code"

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/Main.elm:subscriptions"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ResponsiveAnimations/Responsive/Main.elm:subscriptions"
        ```

### 2. Measure the new geometry

When a resize fires, ask the browser for the new size of whatever element the animation is anchored to (with `Browser.Dom.getElement`) and wait for the result.

??? example "View Source Code"

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/Main.elm:on-resize-update"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ResponsiveAnimations/Responsive/Main.elm:on-resize-update"
        ```

### 3. Hand the new bounds to the engine

Call the engine's `onResize` with a chain of property-level `bounds` calls — one per group that needs updating. The engine remaps each group proportionally on the next animation frame.

??? example "View Source Code"

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/Main.elm:on-resize-handler"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ResponsiveAnimations/Responsive/Main.elm:on-resize-handler"
        ```

---

## How the Remap Works

On every resize, each axis with new bounds is remapped:

- **Endpoints** (the animation's `start` and `end` values) adopt the new bounds.
- **Current value** keeps its relative position within the range — if it was 25% of the way from start to end before, it's still 25% of the way after.
- **Normalized progress** is preserved, so looping and ping-pong motion stay in phase.

Properties that aren't bounded by the resize (for example, `Opacity` when only the track width changed) are left untouched.

---

## Transition and Keyframe Engines

The [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md) engines don't currently observe resize events — once an animation starts, pixel-based targets are fixed for the lifetime of that animation.

For resize-aware behavior on these engines, use relative units (`Percent`, `Vw`/`Vh`, `Cqw`/`Cqh`, etc.) so the browser re-evaluates values against current layout each frame.

If your targets are pixel-derived from measured layout and must be remapped proportionally while in flight, use [Sub](../engines/sub.md) or [WAAPI](../engines/waapi.md) with `Anim.Resize.bounds`.

---

## Next Steps

[Interrupting Animations](interrupting-animations.md){ .md-button .md-button--primary }
[Engines Overview](../engines/overview.md){ .md-button .md-button--primary }
