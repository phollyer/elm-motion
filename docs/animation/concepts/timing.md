# Animation Timing

Control how long animations take with either fixed durations or distance-based speeds.

## Duration vs Speed

Elm Motion offers two approaches to timing:

| Approach | Behavior | Best For |
| -------- | -------- | -------- |
| `duration` | Fixed time regardless of distance | Most animations — consistent, predictable timing |
| `speed` | Time varies based on distance | Movement animations where distance varies |

## Duration

Set a fixed animation time in milliseconds:

??? example "View Source Code"

    ```elm
    Opacity.for "boxAnim"
        >> Opacity.to 1
        >> Opacity.duration 300  -- Always 300ms
        >> Opacity.build
    ```

Duration should be the default choice for most animations. Fades, color changes, and UI effects benefit from consistent timing.

## Speed

Set a rate of change per second:

??? example "View Source Code"

    ```elm
    Translate.for "boxAnim"
        >> Translate.toX 100
        >> Translate.speed 200  -- 200 pixels per second
        >> Translate.build
    ```

Moving 100 pixels at 200px/s takes 500ms. Moving 400 pixels takes 2000ms.

!!! warning "Units of Speed"
    Speed is calculated in 'property specific units per second'. Exactly what 'units' represents differs by property type - details of which are on each Property page.

!!! tip "When to use speed"
    Speed shines for **Translate** animations where elements travel different distances. A short move feels snappy while a long move takes appropriately longer — matching how physical objects behave.

!!! example "Practical example"
    A drag-and-drop interface where items snap to grid positions — use `speed` so nearby drops feel quick and distant drops take longer. But the fade effect when picking up an item? Use `duration` for consistency.

## Important Notes

!!! warning "Choose one"
    Use either `duration` or `speed`, not both. If both are set, the last one wins.

!!! warning "Default behavior"
    If no `duration` or `speed` is set — either globally on the engine or locally on the property — then a duration of 0ms is used and the element instantly jumps to its end state.


## Next Steps

Learn how easing shapes the feel of your motion.

[Easing →](easing.md){ .md-button .md-button--primary }
