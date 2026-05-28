# Scroll Easing

Easing is the *shape* of a scroll - whether it whooshes off and glides to a halt, ramps up gradually, or bounces past the target before settling.

The same scroll, with different easing, can feel snappy, deliberate, sluggish, or playful. It's one of the cheapest ways to make scrolling feel intentional rather than mechanical.

??? example "Setting an easing"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "features"
        >> Scroll.speed 800
        >> Scroll.easing QuintOut
        >> Scroll.build
    ```

!!! tip "Sensible default"
    If you're not sure which easing to start with, try `CubicOut` for short scrolls and `QuintOut` for long ones. Both feel deliberate without drawing attention to themselves.

--8<-- "docs/shared/easing-reference.md"

## Choosing an Easing for Scroll

| Use Case | Recommended Easing | Why |
| -------- | ------------------ | --- |
| Short scroll jumps | `CubicOut` | Smooth without feeling exaggerated. |
| Long scroll jumps | `QuintOut` | Feels deliberate and controlled over distance. |
| Focused destination jumps | `SineOut` / `CubicOut` | Gentle settle, no visual noise. |
| Playful interactions | `BackOut` / `ElasticOut` / `BounceOut` | Expressive - use sparingly. |

!!! note "Practical guidance"
    Keep `Elastic` and `Bounce` for moments you *want* the user to notice. For everyday navigation, `Out` variants are clearer and less distracting.

## Default

If you don't set an easing, scrolls run on `Linear` - a constant rate from start to finish. That's deliberate for scrolling (no surprise overshoot) but most scrolls feel better with even a mild `CubicOut`.

## Next Steps

Learn what happens when a scroll is re-triggered before the first one finishes.

[Interrupting Scrolls →](interrupting-scrolls.md){ .md-button .md-button--primary }
