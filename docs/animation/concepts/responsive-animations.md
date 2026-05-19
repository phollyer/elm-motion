# Responsive Animations

When layout changes mid-animation, the [Sub](../engines/sub.md) and [WAAPI](../engines/waapi.md) engines can keep animations in sync with the new geometry through the [`Anim.Resize`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize) API. You declare a **policy** per animation group — proportional, clamp, or retarget — then feed new [`Bounds`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize#Bounds) into the engine on each resize event.

The [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md) engines don't currently observe resize events. See [Transition and Keyframe Engines](#transition-and-keyframe-engines) below.

---

## Example

??? example "View Example"

    === "WAAPI"

        <iframe src="../../../examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/index.html" class="example-iframe" loading="lazy", style="height:550px;min-height:550px;max-height:550px"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Animation/Sub/ResponsiveAnimations/Responsive/index.html" class="example-iframe" loading="lazy", style="height:850px;min-height:850px;max-height:850px"></iframe>

Two boxes loop back and forth across a track. Use the **Narrow / Normal / Widen** buttons to change the track width while the animation is running. The top box uses the `Resize.proportional` policy and the bottom box uses `Resize.retarget` — watch how each one reacts differently to the new bounds.

---

## Quick Start

Four pieces wire the resize API together.

### 1. Declare a policy

Attach a [`Resize.Policy`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize#Policy) to each animation group so the engine knows how to react when bounds change. The example sets the policy inline on the same builder pipeline that starts the animation — one group gets `Resize.proportional`, the other gets `Resize.retarget`.

??? example "View Source Code"

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/Main.elm:policy-init"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ResponsiveAnimations/Responsive/Main.elm:policy-init"
        ```

### 2. Subscribe to viewport changes

Use `Browser.Events.onResize` to know when the layout changes. The example also re-fires this message when the user clicks a width button so the in-app "resize" is treated the same as a real browser resize.

??? example "View Source Code"

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/ResponsiveAnimations/Responsive/Main.elm:subscriptions"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/ResponsiveAnimations/Responsive/Main.elm:subscriptions"
        ```

### 3. Measure the new geometry

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

### 4. Hand the new bounds to the engine

Call the engine's `onResize` with a chain of property-level `bounds` calls — one per group that needs updating. The engine applies each group's declared policy on the next animation frame.

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

## Choosing a Policy Preset

Three presets cover the common cases. Pick whichever matches the feel you want; you can mix presets across groups, and you can fine-tune any of them later.

### `Resize.proportional`

Use when you want **rhythm** to keep flowing — looping or ping-pong motion that should feel continuous as the track grows or shrinks. The current value moves to keep the same relative position within the new range, and the animation's timing stays in phase.

??? example "View Source Code"

    ```elm
    Translate.resizePolicy "myGroup" Resize.proportional
    ```

### `Resize.clamp`

Use when bounds are a **safety rail**, not the track itself. The current value stays put (clamped into the new range), the animation's configured start/end values are preserved, and time is solved from where the element actually is.

??? example "View Source Code"

    ```elm
    Translate.resizePolicy "myGroup" Resize.clamp
    ```

### `Resize.retarget`

Use when the animation should keep **heading toward the new boundary**. The current value stays where it is and the engine solves the remaining time so the element ends up at the resized edge.

??? example "View Source Code"

    ```elm
    Translate.resizePolicy "myGroup" Resize.retarget
    ```

---

## Per-Property Overrides

A policy set with `Resize.policy "group" ...` applies to every property in that group. Override it for one property by calling that property's `resizePolicy` instead — handy when, say, `Translate` should adapt proportionally but `Scale` should clamp.

??? example "View Source Code"

    ```elm
    -- Group-wide default
    Resize.policy "card" Resize.proportional

    -- Translate adapts proportionally (inherited), but Scale clamps
    Scale.resizePolicy "card" Resize.clamp
    ```

Resolution order is: **per-property policy → group-wide policy → library default** (`Resize.proportional`).

---

## Transition and Keyframe Engines

The [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md) engines don't currently observe resize events — once an animation starts, its target values are fixed for the lifetime of that animation.

If you need an animation to react to layout changes, use the [Sub](../engines/sub.md) or [WAAPI](../engines/waapi.md) engine.

You can still call `Transition.retarget` / `Keyframe.retarget` from your own resize handler to snap an element to a freshly computed value, but the engine won't smoothly continue an in-flight animation toward the new geometry.

---

## Next Steps

[Interrupting Animations](interrupting-animations.md){ .md-button .md-button--primary }
[Engines Overview](../engines/overview.md){ .md-button .md-button--primary }
