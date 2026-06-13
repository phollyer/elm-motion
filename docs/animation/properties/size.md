# Size

Animate the width and height of elements.

**Module:** `Anim.Property.Size`

**GPU Accelerated:** ❌ No — triggers browser reflows and repaints.

!!! warning "Performance Impact"
    Size changes trigger browser reflows. The scope depends on layout context - a fixed-size container with `overflow: hidden` limits reflow to its subtree. In unbounded layouts, reflow can propagate widely. Consider using `Scale` transforms when you don't need actual layout changes.

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Size as Size

    expandBox : AnimBuilder eng -> AnimBuilder eng
    expandBox =
        Size.begin
            >> Size.toHW 150 200
            >> Size.end
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial size (uniform) |
| `initHW` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial width and height |
| `initW` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial width |
| `initH` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial height |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder eng -> Builder eng` | Start building |
| `build` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromHW` | `Float -> Float -> Builder eng -> Builder eng` | Starting height and width |
| `fromH` | `Float -> Builder eng -> Builder eng` | Starting height (pixels) |
| `fromW` | `Float -> Builder eng -> Builder eng` | Starting width (pixels) |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toHW` | `Float -> Float -> Builder eng -> Builder eng` | Ending height and width |
| `toH` | `Float -> Builder eng -> Builder eng` | Ending height (pixels) |
| `toW` | `Float -> Builder eng -> Builder eng` | Ending width (pixels) |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byHW` | `Float -> Float -> Builder eng -> Builder eng` | Resize by height and width amounts |
| `byH` | `Float -> Builder eng -> Builder eng` | Resize by height amount (pixels) |
| `byW` | `Float -> Builder eng -> Builder eng` | Resize by width amount (pixels) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | Pixels per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder eng -> Builder eng` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }` | Use spring physics instead of easing |

## Next Steps

Now you've learnt about the first-class properties supported by Elm Motion, learn how to use the Custom Properties modules in order to animate any other CSS Property.

[Custom Properties →](./custom-property.md){ .md-button .md-button--primary }

